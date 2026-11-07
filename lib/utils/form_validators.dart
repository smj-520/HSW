import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../services/app_i18n.dart';

abstract final class FormValidators {
  static const int minPasswordPolicyLength = 8;
  static const int minLoginPasswordLength = 6;

  static final RegExp _hasUpper = RegExp(r'[A-Z]');
  static final RegExp _hasLower = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasSpecial = RegExp(r'[^A-Za-z0-9\s]');

  static final RegExp _gmailLocal = RegExp(
    r'^[a-z0-9](?:[a-z0-9._+-]*[a-z0-9])?@(gmail|googlemail)\.com$',
  );

  static String passwordPolicyHint() {
    return AppI18n.ts(
      en:
          'At least 8 characters, with uppercase, lowercase, a number, and a symbol.',
      ar:
          '8 أحرف على الأقل، مع حرف كبير وصغير ورقم ورمز (مثل !@#).',
    );
  }

  static String? required(
    String? value, {
    String fieldEn = 'This field',
    String fieldAr = 'هذا الحقل',
  }) {
    if (value == null || value.trim().isEmpty) {
      return AppI18n.ts(en: '$fieldEn is required', ar: '$fieldAr مطلوب');
    }
    return null;
  }

  static String? gmailOnly(String? value) {
    final r = required(value, fieldEn: 'Email', fieldAr: 'البريد');
    if (r != null) return r;
    final v = value!.trim().toLowerCase().replaceAll(RegExp(r'\s'), '');
    if (!_gmailLocal.hasMatch(v)) {
      return AppI18n.ts(
        en: 'Use a real Gmail address (@gmail.com only)',
        ar: 'استخدم عنوان Gmail حقيقي (@gmail.com فقط)',
      );
    }
    final local = v.split('@').first;
    if (local.length < 6 || local.length > 64) {
      return AppI18n.ts(
        en: 'Gmail username must be 6–64 characters',
        ar: 'اسم مستخدم Gmail يجب أن يكون بين 6 و 64 حرفًا',
      );
    }
    if (local.contains('..')) {
      return AppI18n.ts(
        en: 'Gmail cannot contain consecutive dots',
        ar: 'Gmail لا يمكن أن يحتوي على نقطتين متتاليتين',
      );
    }
    if (local.startsWith('.') || local.endsWith('.')) {
      return AppI18n.ts(
        en: 'Invalid Gmail format',
        ar: 'صيغة Gmail غير صالحة',
      );
    }
    return null;
  }

  static String normalizeGmail(String value) {
    final v = value.trim().toLowerCase().replaceAll(RegExp(r'\s'), '');
    if (v.endsWith('@gmail.com')) return v;
    return '$v@gmail.com';
  }

  static String normalizeEmail(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s'), '');
  }

  static String? emailAddress(String? value) {
    final r = required(value, fieldEn: 'Email', fieldAr: 'البريد الإلكتروني');
    if (r != null) return r;
    final v = normalizeEmail(value!);
    if (v.length > 254) {
      return AppI18n.ts(
        en: 'Email is too long',
        ar: 'البريد طويل جدًا',
      );
    }
    final re = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
    );
    if (!re.hasMatch(v)) {
      return AppI18n.ts(
        en: 'Enter a valid email address',
        ar: 'أدخل عنوان بريد إلكتروني صالحًا',
      );
    }
    return null;
  }

  static String? gmailUsername(String? value) {
    final r = required(value, fieldEn: 'Gmail username', fieldAr: 'اسم مستخدم Gmail');
    if (r != null) return r;
    final v = value!.trim().toLowerCase().replaceAll(RegExp(r'\s'), '');
    if (v.contains('@')) {
      return AppI18n.ts(
        en: 'Enter Gmail username only (without @gmail.com)',
        ar: 'أدخل اسم مستخدم Gmail فقط (بدون @gmail.com)',
      );
    }
    if (!RegExp(r'^[a-z0-9](?:[a-z0-9._+-]*[a-z0-9])?$').hasMatch(v)) {
      return AppI18n.ts(
        en: 'Use letters, numbers, dot, underscore, plus or hyphen',
        ar: 'استخدم أحرفًا إنجليزية صغيرة وأرقامًا أو . _ + -',
      );
    }
    if (v.length < 6 || v.length > 64) {
      return AppI18n.ts(
        en: 'Gmail username must be 6–64 characters',
        ar: 'اسم مستخدم Gmail يجب أن يكون بين 6 و 64 حرفًا',
      );
    }
    if (v.contains('..') || v.startsWith('.') || v.endsWith('.')) {
      return AppI18n.ts(
        en: 'Invalid Gmail username format',
        ar: 'صيغة اسم مستخدم Gmail غير صالحة',
      );
    }
    return null;
  }

  static String? loginPassword(String? value) {
    final r = required(value, fieldEn: 'Password', fieldAr: 'كلمة المرور');
    if (r != null) return r;
    if (value!.length < minLoginPasswordLength) {
      return AppI18n.ts(
        en: 'Password must be at least $minLoginPasswordLength characters',
        ar: 'كلمة المرور يجب ألا تقل عن $minLoginPasswordLength أحرف',
      );
    }
    return null;
  }

  static String? strongPassword(String? value) {
    final r = required(value, fieldEn: 'Password', fieldAr: 'كلمة المرور');
    if (r != null) return r;
    final v = value!;
    if (v.length < minPasswordPolicyLength) {
      return AppI18n.ts(
        en: 'Use at least $minPasswordPolicyLength characters',
        ar: 'استخدم $minPasswordPolicyLength أحرف على الأقل',
      );
    }
    if (!_hasUpper.hasMatch(v)) {
      return AppI18n.ts(
        en: 'Include at least one uppercase letter (A–Z)',
        ar: 'أضف حرفًا إنجليزيًا كبيرًا واحدًا على الأقل (A–Z)',
      );
    }
    if (!_hasLower.hasMatch(v)) {
      return AppI18n.ts(
        en: 'Include at least one lowercase letter (a–z)',
        ar: 'أضف حرفًا إنجليزيًا صغيرًا واحدًا على الأقل (a–z)',
      );
    }
    if (!_hasDigit.hasMatch(v)) {
      return AppI18n.ts(
        en: 'Include at least one number (0–9)',
        ar: 'أضف رقمًا واحدًا على الأقل (0–9)',
      );
    }
    if (!_hasSpecial.hasMatch(v)) {
      return AppI18n.ts(
        en: 'Include at least one symbol (e.g. ! @ # \$ % ^ & *)',
        ar: 'أضف رمزًا واحدًا على الأقل (مثل ! @ # \$ % & *)',
      );
    }
    return null;
  }

  static String? confirmPassword(String? password, String? confirm) {
    final r = required(confirm, fieldEn: 'Confirm password', fieldAr: 'تأكيد كلمة المرور');
    if (r != null) return r;
    if (password != confirm) {
      return AppI18n.ts(
        en: 'Passwords do not match',
        ar: 'كلمتا المرور غير متطابقتين',
      );
    }
    return null;
  }

  static IsoCode? tryParseIso(String? alpha2) {
    if (alpha2 == null || alpha2.isEmpty) return null;
    final upper = alpha2.toUpperCase();
    for (final iso in IsoCode.values) {
      if (iso.name == upper) return iso;
    }
    return null;
  }

  static String? phoneNational(String? value, IsoCode country) {
    final r = required(value, fieldEn: 'Phone number', fieldAr: 'رقم الهاتف');
    if (r != null) return r;
    final raw = value!.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (raw.isEmpty) {
      return AppI18n.ts(
        en: 'Phone number is required',
        ar: 'رقم الهاتف مطلوب',
      );
    }
    try {
      final pn = PhoneNumber.parse(raw, callerCountry: country);
      if (pn.isValid()) {
        return null;
      }
      return AppI18n.ts(
        en: 'Enter a valid ${_countryLabelEn(country)} mobile number',
        ar: 'أدخل رقم هاتف محمول صحيح لـ ${_countryLabelAr(country)}',
      );
    } catch (_) {
      return AppI18n.ts(
        en: 'Enter a valid phone number for ${_countryLabelEn(country)}',
        ar: 'أدخل رقم هاتف صحيح لـ ${_countryLabelAr(country)}',
      );
    }
  }

  static String _countryLabelEn(IsoCode country) {
    return country.name;
  }

  static String _countryLabelAr(IsoCode country) {
    return switch (country) {
      IsoCode.OM => 'عُمان',
      IsoCode.AE => 'الإمارات',
      IsoCode.SA => 'السعودية',
      IsoCode.EG => 'مصر',
      IsoCode.US => 'الولايات المتحدة',
      IsoCode.GB => 'المملكة المتحدة',
      _ => country.name,
    };
  }

  static String? newPasswordDifferent({
    required String? newPassword,
    String? oldPassword,
  }) {
    if (oldPassword == null || oldPassword.isEmpty) return null;
    if (newPassword == oldPassword) {
      return AppI18n.ts(
        en: 'Choose a different password than your previous one',
        ar: 'اختر كلمة مرور مختلفة عن السابقة',
      );
    }
    return null;
  }
}
