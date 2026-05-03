import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static Future<SharedPreferences>? _initFuture;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _initFuture = Future.value(_prefs);
  }

  static Future<void> _ensureInit() async {
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    _initFuture = SharedPreferences.getInstance();
    _prefs = await _initFuture!;
  }

  static Future<void> saveString(String key, String value) async {
    await _ensureInit();
    await _prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    await _ensureInit();
    return _prefs.getString(key);
  }

  static Future<void> saveInt(String key, int value) async {
    await _ensureInit();
    await _prefs.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    await _ensureInit();
    return _prefs.getInt(key);
  }

  static Future<void> saveBool(String key, bool value) async {
    await _ensureInit();
    await _prefs.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    await _ensureInit();
    return _prefs.getBool(key);
  }

  static Future<void> saveJson(String key, Map<String, dynamic> value) async {
    await _ensureInit();
    await _prefs.setString(key, jsonEncode(value));
  }

  static Future<void> saveJsonList(String key, List<Map<String, dynamic>> value) async {
    await _ensureInit();
    await _prefs.setString(key, jsonEncode(value));
  }

  static Future<Map<String, dynamic>?> getJson(String key) async {
    await _ensureInit();
    final value = _prefs.getString(key);
    if (value != null) {
      return jsonDecode(value) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<dynamic>?> getJsonList(String key) async {
    await _ensureInit();
    final value = _prefs.getString(key);
    if (value != null) {
      return jsonDecode(value) as List<dynamic>;
    }
    return null;
  }

  static Future<void> delete(String key) async {
    await _ensureInit();
    await _prefs.remove(key);
  }

  static Future<void> clear() async {
    await _ensureInit();
    await _prefs.clear();
  }

  static Future<bool> containsKey(String key) async {
    await _ensureInit();
    return _prefs.containsKey(key);
  }
}
