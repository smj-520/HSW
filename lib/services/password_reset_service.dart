import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import './auth_action_settings.dart';

// Sends Firebase's normal reset email. The user opens the link — no OTP.
class PasswordResetService {
  Future<void> sendCode(String email) async {
    final normalized = email.trim().toLowerCase();
    if (Firebase.apps.isEmpty) {
      throw PasswordResetException('Firebase is not ready. Try again.');
    }
    try {
      if (hasCustomAuthHandlerUrl) {
        try {
          await FirebaseAuth.instance
              .sendPasswordResetEmail(
                email: normalized,
                actionCodeSettings: authActionCodeSettings(),
              )
              .timeout(const Duration(seconds: 20));
          return;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            return;
          }
        } catch (_) {}
      }
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: normalized)
          .timeout(const Duration(seconds: 20));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return;
      }
      throw PasswordResetException(_mapAuthError(e));
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return e.message ?? 'Could not send the email. Try again.';
    }
  }
}

class PasswordResetException implements Exception {
  PasswordResetException(this.message);
  final String message;

  @override
  String toString() => message;
}
