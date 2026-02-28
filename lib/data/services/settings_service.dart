import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user profile and app settings. Keys are private to avoid collisions.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyUserName = 'user_name';
  static const String _keyThemeMode = 'theme_mode'; // 0=system, 1=light, 2=dark
  static const String _keyLocale = 'locale'; // languageCode e.g. 'en', 'es'

  String? get userName => _prefs.getString(_keyUserName);
  Future<void> setUserName(String? value) async {
    if (value == null) {
      await _prefs.remove(_keyUserName);
    } else {
      await _prefs.setString(_keyUserName, value);
    }
  }

  ThemeMode get themeMode {
    final i = _prefs.getInt(_keyThemeMode);
    if (i == null) return ThemeMode.system;
    switch (i) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final i = switch (mode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };
    await _prefs.setInt(_keyThemeMode, i);
  }

  String? get languageCode => _prefs.getString(_keyLocale);
  Future<void> setLanguageCode(String? code) async {
    if (code == null || code.isEmpty) {
      await _prefs.remove(_keyLocale);
    } else {
      await _prefs.setString(_keyLocale, code);
    }
  }
}
