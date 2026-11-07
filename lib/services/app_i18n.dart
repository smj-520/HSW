import 'package:flutter/material.dart';

import './app_settings_controller.dart';

abstract final class AppI18n {
  static bool isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  static bool get isArabicFromSettings =>
      AppSettingsController.instance.isArabic;

  static String t(
    BuildContext context, {
    required String en,
    required String ar,
  }) {
    return isArabic(context) ? ar : en;
  }

  static String ts({required String en, required String ar}) {
    return isArabicFromSettings ? ar : en;
  }
}

extension AppI18nContextX on BuildContext {
  String tr(String en, String ar) => AppI18n.t(this, en: en, ar: ar);
}
