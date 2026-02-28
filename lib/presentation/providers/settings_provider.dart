import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/data/services/settings_service.dart';

/// Injected in main after SharedPreferences init. Override with real [SettingsService].
final settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError(
    'SettingsService must be overridden in main with SharedPreferences-based instance',
  );
});

final class SettingsState {
  const SettingsState({
    this.userName,
    this.themeMode = ThemeMode.system,
    this.locale,
  });

  final String? userName;
  final ThemeMode themeMode;
  final Locale? locale;
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._service)
      : super(SettingsState(
          userName: _service.userName,
          themeMode: _service.themeMode,
          locale: _service.languageCode != null
              ? Locale(_service.languageCode!)
              : null,
        ));

  final SettingsService _service;

  Future<void> setUserName(String? value) async {
    await _service.setUserName(value);
    state = SettingsState(
      userName: value,
      themeMode: state.themeMode,
      locale: state.locale,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _service.setThemeMode(mode);
    state = SettingsState(
      userName: state.userName,
      themeMode: mode,
      locale: state.locale,
    );
  }

  Future<void> setLocale(Locale? locale) async {
    final code = locale?.languageCode;
    await _service.setLanguageCode(code);
    state = SettingsState(
      userName: state.userName,
      themeMode: state.themeMode,
      locale: locale,
    );
  }
}

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsNotifierProvider).themeMode;
});

final localeProvider = Provider<Locale?>((ref) {
  return ref.watch(settingsNotifierProvider).locale;
});

final userNameProvider = Provider<String?>((ref) {
  return ref.watch(settingsNotifierProvider).userName;
});
