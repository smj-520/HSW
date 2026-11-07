import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class RememberCredentials {
  static const enabledKey = 'remember_me_enabled';
  static const gmailUserKey = 'remember_me_gmail_user';
  static const _securePassKey = 'remember_me_saved_password';

  static const FlutterSecureStorage _vault = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> saveAfterLogin({
    required bool remember,
    required String gmailUsername,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, remember);
    if (remember) {
      await prefs.setString(gmailUserKey, gmailUsername.trim().toLowerCase());
      try {
        await _vault.write(key: _securePassKey, value: password);
      } catch (_) {
        if (kDebugMode) {
          print('RememberCredentials: could not save password to secure storage');
        }
      }
    } else {
      await prefs.remove(gmailUserKey);
      try {
        await _vault.delete(key: _securePassKey);
      } catch (_) {}
    }
  }

  static Future<void> clearStoredSecrets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(gmailUserKey);
    try {
      await _vault.delete(key: _securePassKey);
    } catch (_) {}
  }

  static Future<bool> loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? true;
  }

  static Future<String> loadGmailUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(gmailUserKey) ?? '';
  }

  static Future<String?> loadPasswordIfRemembered() async {
    if (kIsWeb) return null;
    final enabled = await loadEnabled();
    if (!enabled) return null;
    try {
      return await _vault.read(key: _securePassKey);
    } catch (_) {
      return null;
    }
  }
}
