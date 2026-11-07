import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/apps_script.dart';

class PasswordResetService {
  PasswordResetService({
    http.Client? httpClient,
    String? webAppUrl,
  })  : _http = httpClient ?? http.Client(),
        _url = webAppUrl ?? kPasswordResetWebAppUrl;

  final http.Client _http;
  final String _url;

  Future<void> sendCode(String email) async {
    final data = await _post(
      {
        'action': 'send',
        'email': email.trim().toLowerCase(),
      },
      treatRedirectAsSuccess: true,
    );
    final error = data['error']?.toString();
    if (data['ok'] == true) return;
    if (error == 'cooldown') {
      final wait = data['waitSec'];
      final seconds = wait is num ? wait.round() : 60;
      throw PasswordResetException(
        PasswordResetError.cooldown,
        'Wait $seconds seconds before resending.',
      );
    }
    if (error == 'invalid_email') {
      throw PasswordResetException(
        PasswordResetError.invalid,
        'Enter a valid email address.',
      );
    }
    throw PasswordResetException(
      PasswordResetError.sendFailed,
      'Could not send the code. Try again.',
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final data = await _post({
      'action': 'reset',
      'email': email.trim().toLowerCase(),
      'code': code.replaceAll(RegExp(r'\D'), ''),
      'newPassword': newPassword,
    });
    if (data['ok'] == true) return;
    final error = data['error']?.toString();
    if (error == 'weak') {
      throw PasswordResetException(
        PasswordResetError.weak,
        'Use at least 8 characters with uppercase, lowercase, a number, and a symbol.',
      );
    }
    if (error == 'too_many') {
      throw PasswordResetException(
        PasswordResetError.tooMany,
        'Too many wrong attempts. Request a new code.',
      );
    }
    if (error == 'invalid') {
      final left = data['left'];
      if (left is num) {
        throw PasswordResetException(
          PasswordResetError.invalid,
          'Wrong or expired code. You have ${left.round()} attempts left.',
        );
      }
      throw PasswordResetException(
        PasswordResetError.invalid,
        'Wrong or expired code. Request a new one.',
      );
    }
    throw PasswordResetException(
      PasswordResetError.sendFailed,
      'Could not update the password. Try again.',
    );
  }

  bool get isConfigured =>
      _url.startsWith('https://') && !_url.contains('PASTE_DEPLOYMENT_ID');

  static const _jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> _post(
    Map<String, dynamic> body, {
    bool treatRedirectAsSuccess = false,
  }) async {
    if (!isConfigured) {
      throw PasswordResetException(
        PasswordResetError.config,
        'Forgot-password is not connected yet. Paste the Apps Script web-app URL into lib/config/apps_script.dart.',
      );
    }
    late final http.Response response;
    try {
      response = await _postFollowingRedirects(body)
          .timeout(const Duration(seconds: 25));
    } on TimeoutException catch (e, st) {
      debugPrint('PasswordReset timeout: $e\n$st');
      throw PasswordResetException(
        PasswordResetError.network,
        'The reset service timed out. Try again.',
      );
    } on SocketException catch (e, st) {
      debugPrint('PasswordReset socket: $e\n$st');
      throw PasswordResetException(
        PasswordResetError.network,
        'No connection to the reset service. Check the internet and try again.',
      );
    } on PasswordResetException {
      rethrow;
    } catch (e, st) {
      debugPrint('PasswordReset request failed: $e\n$st');
      throw PasswordResetException(
        PasswordResetError.network,
        'Could not reach the reset service: $e',
      );
    }

    debugPrint(
      'PasswordReset HTTP ${response.statusCode} body=${response.body}',
    );

    final redirected = _isRedirect(response.statusCode);
    Map<String, dynamic>? data = _tryJsonMap(response.body);
    if (data == null && treatRedirectAsSuccess && redirected) {
      return {'ok': true};
    }
    if (data == null) {
      throw PasswordResetException(
        PasswordResetError.sendFailed,
        'The reset service returned an unexpected reply (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode >= 400 && data['ok'] != true) {
      throw PasswordResetException(
        PasswordResetError.sendFailed,
        'Reset service HTTP ${response.statusCode}.',
      );
    }
    return data;
  }

  Future<http.Response> _postFollowingRedirects(Map<String, dynamic> body) async {
    final uri = Uri.parse(_url);
    final request = http.Request('POST', uri)
      ..followRedirects = false
      ..headers.addAll(_jsonHeaders)
      ..body = jsonEncode(body);
    final first = await http.Response.fromStream(await _http.send(request));
    if (!_isRedirect(first.statusCode)) return first;

    final location = first.headers['location'] ?? first.headers['Location'];
    if (location == null || location.isEmpty) return first;

    final next = uri.resolve(location);
    return _http.get(next, headers: const {'Accept': 'application/json'});
  }

  bool _isRedirect(int status) =>
      status == 301 || status == 302 || status == 303 || status == 307 || status == 308;

  Map<String, dynamic>? _tryJsonMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return null;
  }
}

enum PasswordResetError {
  cooldown,
  invalid,
  tooMany,
  weak,
  network,
  config,
  sendFailed,
}

class PasswordResetException implements Exception {
  PasswordResetException(this.code, this.message);
  final PasswordResetError code;
  final String message;

  @override
  String toString() => message;
}
