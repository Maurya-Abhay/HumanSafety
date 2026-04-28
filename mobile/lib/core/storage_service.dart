import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  static Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  static Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  static Future<void> saveJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  static Future<void> saveJsonList(String key, List<Map<String, dynamic>> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  static Future<Map<String, dynamic>?> getJson(String key) async {
    final value = _prefs.getString(key);
    if (value != null) {
      return jsonDecode(value) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<dynamic>?> getJsonList(String key) async {
    final value = _prefs.getString(key);
    if (value != null) {
      return jsonDecode(value) as List<dynamic>;
    }
    return null;
  }

  static Future<void> delete(String key) async {
    await _prefs.remove(key);
  }

  static Future<void> clear() async {
    await _prefs.clear();
  }

  static Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }
}
