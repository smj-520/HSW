import 'package:flutter/material.dart';

import './app_settings_controller.dart';

/// UI copy EN/AR. [t] uses [MaterialApp.locale]; [ts] uses the same source as
/// locale ([AppSettingsController]) for validators/services without [BuildContext].
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

  /// Bilingual string when [BuildContext] is not available (e.g. form validators).
  static String ts({required String en, required String ar}) {
    return isArabicFromSettings ? ar : en;
  }
}

extension AppI18nContextX on BuildContext {
  /// Shorthand for [AppI18n.t] with positional EN/AR (e.g. list tiles, dialogs).
  String tr(String en, String ar) => AppI18n.t(this, en: en, ar: ar);
}
