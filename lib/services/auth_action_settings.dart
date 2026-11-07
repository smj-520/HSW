import 'package:firebase_auth/firebase_auth.dart';

const String kCustomAuthHandlerUrl = 'https://b-teck.web.app/auth/index.html';

bool get hasCustomAuthHandlerUrl => kCustomAuthHandlerUrl.trim().isNotEmpty;

ActionCodeSettings authActionCodeSettings() {
  return ActionCodeSettings(
    url: kCustomAuthHandlerUrl.trim(),
    handleCodeInApp: false,
    androidPackageName: 'com.example.cpp',
    androidInstallApp: true,
    androidMinimumVersion: '23',
  );
}

Future<void> sendAppEmailVerification(User user) async {
  if (hasCustomAuthHandlerUrl) {
    await user.sendEmailVerification(authActionCodeSettings());
    return;
  }
  await user.sendEmailVerification();
}
