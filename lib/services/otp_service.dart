import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OtpService {
  OtpService({
    FirebaseDatabase? database,
    http.Client? httpClient,
  })  : _root = (database ?? FirebaseDatabase.instance).ref('otps'),
        _http = httpClient ?? http.Client();

  final DatabaseReference _root;
  final http.Client _http;

  static const registerPurpose = 'register';
  static const resetPurpose = 'reset';
  static const fromName = 'Hostel Student Wallet';
  static const _emailJsServiceId = 'service_uv1emup';
  static const _emailJsTemplateId = 'template_jpdvy1r';
  static const _emailJsPublicKey = 'JBC79L7GQL7bdgQ2A';
  static const _emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  static const ttl = Duration(minutes: 10);
  static const resendCooldown = Duration(seconds: 60);
  static const maxAttempts = 5;

  static String docId(String email, String purpose) {
    final raw = '${normalizeEmail(email)}_$purpose';
    return raw
        .replaceAll('.', ',')
        .replaceAll('#', '_')
        .replaceAll('\$', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_')
        .replaceAll('/', '_');
  }

  static String normalizeEmail(String email) =>
      email.trim().toLowerCase().replaceAll(RegExp(r'\s'), '');

  static String digestCode({
    required String email,
    required String purpose,
    required String code,
  }) {
    final material =
        '$purpose|${normalizeEmail(email)}|${code.trim()}|HostelStudentWalletOtp';
    return sha256.convert(utf8.encode(material)).toString();
  }

  static String generateCode([Random? random]) {
    final rng = random ?? Random.secure();
    return rng.nextInt(1000000).toString().padLeft(6, '0');
  }

  Future<void> sendCode({
    required String email,
    required String purpose,
  }) async {
    final normalized = normalizeEmail(email);
    _assertPurpose(purpose);
    final ref = _root.child(docId(normalized, purpose));

    try {
      final existing = await ref.get();
      if (existing.exists && existing.value is Map) {
        final row = _asMap(existing.value);
        final last = _asDate(row['lastSentAt']);
        if (last != null) {
          final wait = resendCooldown - DateTime.now().difference(last);
          if (wait > Duration.zero) {
            throw OtpException(
              OtpError.cooldown,
              'Wait ${wait.inSeconds} seconds before resending.',
            );
          }
        }
      }

      final code = generateCode();
      final now = DateTime.now();
      await ref.set({
        'email': normalized,
        'purpose': purpose,
        'codeHash': digestCode(email: normalized, purpose: purpose, code: code),
        'expiresAt': now.add(ttl).millisecondsSinceEpoch,
        'attempts': 0,
        'lastSentAt': now.millisecondsSinceEpoch,
        'used': false,
      });

      await _sendEmailJs(toEmail: normalized, code: code);
    } on OtpException {
      rethrow;
    } on FirebaseException catch (e, st) {
      debugPrint('OTP RTDB error code=${e.code} message=${e.message}\n$st');
      throw OtpException(OtpError.sendFailed, _rtdbSendMessage(e, st));
    } catch (e, st) {
      debugPrint('OTP sendCode unexpected error: $e\n$st');
      throw OtpException(OtpError.sendFailed, _rtdbSendMessage(e, st));
    }
  }

  Future<void> verifyCode({
    required String email,
    required String purpose,
    required String code,
  }) async {
    final normalized = normalizeEmail(email);
    _assertPurpose(purpose);
    final digits = code.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) {
      throw OtpException(OtpError.wrong, 'Enter the 6-digit code.');
    }

    final ref = _root.child(docId(normalized, purpose));
    try {
      var outcome = 'expired';
      await ref.runTransaction((Object? current) {
        if (current is! Map) {
          outcome = 'expired';
          return Transaction.abort();
        }
        final data = _asMap(current);
        if (data['used'] == true) {
          outcome = 'used';
          return Transaction.abort();
        }
        final expiresAt = _asDate(data['expiresAt']);
        if (expiresAt == null || !expiresAt.isAfter(DateTime.now())) {
          outcome = 'expired';
          return Transaction.abort();
        }
        final attempts = _asInt(data['attempts']);
        if (attempts >= maxAttempts) {
          outcome = 'tooMany';
          return Transaction.abort();
        }
        final expected = digestCode(
          email: normalized,
          purpose: purpose,
          code: digits,
        );
        if (expected != data['codeHash']?.toString()) {
          final left = maxAttempts - attempts - 1;
          outcome = left <= 0 ? 'tooMany' : 'wrong:$left';
          data['attempts'] = attempts + 1;
          return Transaction.success(data);
        }
        data['used'] = true;
        outcome = 'ok';
        return Transaction.success(data);
      });

      if (outcome == 'ok') return;
      if (outcome == 'used') {
        throw OtpException(
          OtpError.used,
          'This code was already used. Request a new one.',
        );
      }
      if (outcome == 'expired') {
        throw OtpException(
          OtpError.expired,
          'This code has expired. Request a new one.',
        );
      }
      if (outcome == 'tooMany') {
        throw OtpException(
          OtpError.tooMany,
          'Too many wrong attempts. Request a new code.',
        );
      }
      if (outcome.startsWith('wrong:')) {
        final left = outcome.substring(6);
        throw OtpException(
          OtpError.wrong,
          'Wrong code. You have $left attempts left.',
        );
      }
      throw OtpException(OtpError.wrong, 'Wrong code.');
    } on OtpException {
      rethrow;
    } on FirebaseException catch (e, st) {
      debugPrint('OTP verify RTDB error code=${e.code} message=${e.message}\n$st');
      throw OtpException(OtpError.sendFailed, _rtdbSendMessage(e, st));
    } catch (e, st) {
      debugPrint('OTP verify unexpected error: $e\n$st');
      throw OtpException(OtpError.sendFailed, _rtdbSendMessage(e, st));
    }
  }

  Future<void> _sendEmailJs({
    required String toEmail,
    required String code,
  }) async {
    debugPrint(
      'EmailJS send → url=$_emailJsUrl '
      'service_id=$_emailJsServiceId '
      'template_id=$_emailJsTemplateId '
      'user_id=$_emailJsPublicKey '
      'to_email=$toEmail',
    );

    late final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse(_emailJsUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_id': _emailJsServiceId,
              'template_id': _emailJsTemplateId,
              'user_id': _emailJsPublicKey,
              'template_params': {
                'to_email': toEmail,
                'otp_code': code,
                'from_name': fromName,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException catch (e, st) {
      debugPrint('EmailJS timeout: $e\n$st');
      throw OtpException(
        OtpError.sendFailed,
        'EmailJS timed out after 20 seconds. The tablet has a connection, but api.emailjs.com did not answer.',
      );
    } on SocketException catch (e, st) {
      debugPrint('EmailJS SocketException: $e\n$st');
      throw OtpException(
        OtpError.sendFailed,
        'EmailJS socket error: $e',
      );
    } on HttpException catch (e, st) {
      debugPrint('EmailJS HttpException: $e\n$st');
      throw OtpException(OtpError.sendFailed, 'EmailJS HTTP error: $e');
    } catch (e, st) {
      debugPrint('EmailJS request failed: $e\n$st');
      throw OtpException(OtpError.sendFailed, 'EmailJS request failed: $e');
    }

    debugPrint(
      'EmailJS response status=${response.statusCode} body=${response.body}',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw OtpException(
      OtpError.sendFailed,
      _emailJsUserMessage(response.statusCode, response.body),
    );
  }

  String _rtdbSendMessage(Object e, [StackTrace? st]) {
    final blob = '${e.toString()}\n${st ?? ''}';
    final denied = blob.toLowerCase().contains('permission denied') ||
        (e is FirebaseException && e.code == 'permission-denied');
    if (denied) {
      return 'Realtime Database blocked /otps (Permission denied). '
          'The app file is updated, but Firebase Console still uses old rules. '
          'Open project b-teck → Realtime Database → Rules, paste database.rules.json, click Publish. '
          'Then fully stop the app and run it again (hot reload is not enough).';
    }
    if (e is FirebaseException) {
      return 'Realtime Database error [${e.code}]: ${e.message}';
    }
    return 'Could not send the code: $e';
  }

  String _emailJsUserMessage(int status, String body) {
    final lower = body.toLowerCase();
    final prefix =
        'EmailJS HTTP $status: ${body.isEmpty ? "(empty body)" : body}';

    if (status == 403 ||
        lower.contains('non-browser') ||
        lower.contains('disabled for non-browser')) {
      return '$prefix\nFix: EmailJS Account → Security → turn ON “Allow EmailJS API for non-browser applications”. If “Use Private Key” is ON, turn it OFF.';
    }
    if (status == 400 || status == 401 || status == 404 || status == 422) {
      return '$prefix\nFix: Check Service ID service_uv1emup, Template ID template_jpdvy1r, Public Key JBC79L7GQL7bdgQ2A, and template To = {{to_email}}.';
    }
    return prefix;
  }

  void _assertPurpose(String purpose) {
    if (purpose != registerPurpose && purpose != resetPurpose) {
      throw ArgumentError('Invalid OTP purpose');
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    return {};
  }

  DateTime? _asDate(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.round());
    }
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

enum OtpError { cooldown, expired, wrong, tooMany, used, network, sendFailed }

class OtpException implements Exception {
  OtpException(this.code, this.message);
  final OtpError code;
  final String message;

  @override
  String toString() => message;
}
