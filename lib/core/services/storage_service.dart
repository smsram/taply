import 'package:shared_preferences/shared_preferences.dart';

abstract class IStorageService {
  Future<void> init();
  Future<bool> setBool(String key, bool value);
  bool? getBool(String key);
  Future<bool> setString(String key, String value);
  String? getString(String key);
  Future<bool> setDouble(String key, double value);
  double? getDouble(String key);
  Future<bool> setInt(String key, int value);
  int? getInt(String key);
  Future<bool> setStringList(String key, List<String> value);
  List<String>? getStringList(String key);
  Future<bool> remove(String key);
  Future<bool> clear();
}

class SharedPreferencesStorageService implements IStorageService {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    await init();
    return _prefs!.setBool(key, value);
  }

  @override
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    await init();
    return _prefs!.setString(key, value);
  }

  @override
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    await init();
    return _prefs!.setDouble(key, value);
  }

  @override
  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    await init();
    return _prefs!.setInt(key, value);
  }

  @override
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    await init();
    return _prefs!.setStringList(key, value);
  }

  @override
  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  @override
  Future<bool> remove(String key) async {
    await init();
    return _prefs!.remove(key);
  }

  @override
  Future<bool> clear() async {
    await init();
    return _prefs!.clear();
  }
}
