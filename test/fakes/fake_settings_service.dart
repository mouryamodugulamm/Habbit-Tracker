import 'package:habit_tracker/data/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory SharedPreferences for tests. [SettingsService] works with this.
class FakeSharedPreferences implements SharedPreferences {
  final Map<String, Object> _map = {};

  @override
  Set<String> getKeys() => _map.keys.toSet();

  @override
  Object? get(String key) => _map[key];

  @override
  bool? getBool(String key) => _map[key] as bool?;

  @override
  int? getInt(String key) => _map[key] as int?;

  @override
  double? getDouble(String key) => _map[key] as double?;

  @override
  String? getString(String key) => _map[key] as String?;

  @override
  List<String>? getStringList(String key) => _map[key] as List<String>?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _map[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _map.remove(key);
    return true;
  }

  @override
  Future<bool> commit() async => true;

  @override
  Future<void> reload() async {}

  @override
  Future<bool> clear() async {
    _map.clear();
    return true;
  }

  @override
  bool containsKey(String key) => _map.containsKey(key);
}

/// Returns a [SettingsService] backed by in-memory prefs for tests.
SettingsService createFakeSettingsService() {
  return SettingsService(FakeSharedPreferences());
}