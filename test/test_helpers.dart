import 'package:taply/core/services/storage_service.dart';

class TestStorageService implements IStorageService {
  final Map<String, dynamic> data = {};

  TestStorageService([Map<String, dynamic>? initialData]) {
    if (initialData != null) {
      data.addAll(initialData);
    }
  }

  @override
  Future<void> init() async {}

  @override
  bool? getBool(String key) => data[key] as bool?;

  @override
  Future<bool> setBool(String key, bool value) async {
    data[key] = value;
    return true;
  }

  @override
  String? getString(String key) => data[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    data[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => data[key] as int?;

  @override
  Future<bool> setInt(String key, int value) async {
    data[key] = value;
    return true;
  }

  @override
  double? getDouble(String key) => data[key] as double?;

  @override
  Future<bool> setDouble(String key, double value) async {
    data[key] = value;
    return true;
  }

  @override
  List<String>? getStringList(String key) =>
      (data[key] as List?)?.cast<String>();

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    data[key] = List<String>.from(value);
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    data.clear();
    return true;
  }
}
