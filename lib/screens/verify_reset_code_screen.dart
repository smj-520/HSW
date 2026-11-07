import 'package:flutter/material.dart';

import '../navigation/app_transitions.dart';
import '../services/otp_service.dart';
import '../services/password_reset_service.dart';
import './otp_code_screen.dart';
import './reset_password_screen.dart';

class VerifyResetCodeScreen extends StatelessWidget {
  const VerifyResetCodeScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return OtpCodeScreen(
      email: email,
      purpose: OtpService.resetPurpose,
      resendCode: () => PasswordResetService().sendCode(email),
      verifyCode: (_) async {},
      onVerified: (code) async {
        await Navigator.of(context).pushReplacement(
          AppTransitions.fadeSlide(
            ResetPasswordScreen(recoveryEmail: email, otpCode: code),
            routeName: '/reset-password',
          ),
        );
      },
    );
  }
}
