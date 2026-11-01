import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme + language. Settings writes here; [MaterialApp] listens.
class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();
  static final AppSettingsController instance = AppSettingsController._();

  static const _kLocale = 'app_locale';
  static const _kTheme = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isArabic => _locale.languageCode == 'ar';

  /// Call once at startup so the last language/theme is ready before first frame.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_kLocale);
    if (lang == 'ar' || lang == 'en') {
      _locale = Locale(lang!);
    }
    final theme = prefs.getString(_kTheme);
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _persist();
  }

  void setLanguage(String languageCode) {
    final next = Locale(languageCode);
    if (_locale == next) return;
    _locale = next;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocale, _locale.languageCode);
      await prefs.setString(
        _kTheme,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {}
  }
}
