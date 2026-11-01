import 'package:firebase_auth/firebase_auth.dart';

import './app_i18n.dart';

String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return AppI18n.ts(
        en: 'This Gmail is already registered. Try signing in.',
        ar: 'هذا Gmail مسجّل مسبقًا. جرّب تسجيل الدخول.',
      );
    case 'invalid-email':
      return AppI18n.ts(
        en: 'That email is not valid for sign-in.',
        ar: 'هذا البريد غير صالح لتسجيل الدخول.',
      );
    case 'weak-password':
      return AppI18n.ts(
        en:
            'Password is too weak. Use at least 8 characters with uppercase, lowercase, a number, and a symbol.',
        ar:
            'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل مع حرف كبير وصغير ورقم ورمز.',
      );
    case 'user-disabled':
      return AppI18n.ts(
        en: 'This account has been disabled.',
        ar: 'تم تعطيل هذا الحساب.',
      );
    case 'user-not-found':
    case 'invalid-credential':
      return AppI18n.ts(
        en: 'No account found or wrong password.',
        ar: 'لا يوجد حساب أو كلمة المرور خاطئة.',
      );
    case 'wrong-password':
      return AppI18n.ts(
        en: 'Incorrect password.',
        ar: 'كلمة المرور غير صحيحة.',
      );
    case 'too-many-requests':
      return AppI18n.ts(
        en: 'Too many attempts. Please wait and try again.',
        ar: 'محاولات كثيرة جدًا. انتظر قليلًا ثم أعد المحاولة.',
      );
    case 'network-request-failed':
      return AppI18n.ts(
        en: 'Network error. Check your connection.',
        ar: 'خطأ في الشبكة. تحقق من الاتصال.',
      );
    case 'operation-not-allowed':
      return AppI18n.ts(
        en: 'Email/password sign-in is not enabled in Firebase console.',
        ar: 'تسجيل الدخول بالبريد وكلمة المرور غير مفعّل في Firebase.',
      );
    default:
      if (e.message?.isNotEmpty == true) {
        return e.message!;
      }
      return AppI18n.ts(
        en: 'Something went wrong (${e.code}).',
        ar: 'حدث خطأ (${e.code}).',
      );
  }
}
