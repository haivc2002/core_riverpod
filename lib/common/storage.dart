import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  static SharedPreferences? _prefs;
  static final Map<String, dynamic> _memoryPrefs = <String, dynamic>{};

  static Future<SharedPreferences> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> setString(String key, String value) async {
    _memoryPrefs[key] = value;
    await _prefs?.setString(key, value);
  }

  static Future<void> setInt(String key, int value) async {
    _memoryPrefs[key] = value;
    await _prefs?.setInt(key, value);
  }

  static Future<void> setDouble(String key, double value) async {
    _memoryPrefs[key] = value;
    await _prefs?.setDouble(key, value);
  }

  static Future<void> setBool(String key, bool value) async {
    _memoryPrefs[key] = value;
    await _prefs?.setBool(key, value);
  }

  static String getString(String key, {String? def}) {
    String? val;
    if (_memoryPrefs.containsKey(key)) {
      val = _memoryPrefs[key];
    }
    val ??= _prefs?.getString(key);
    val ??= def;
    _memoryPrefs[key] = val;
    return val ?? '';
  }

  static int getInt(String key, {int? def}) {
    int? val;
    if (_memoryPrefs.containsKey(key)) {
      val = _memoryPrefs[key];
    }
    val ??= _prefs?.getInt(key);
    val ??= def;
    _memoryPrefs[key] = val;
    return val ?? -1;
  }

  static double getDouble(String key, {double? def}) {
    double? val;
    if (_memoryPrefs.containsKey(key)) {
      val = _memoryPrefs[key];
    }
    val ??= _prefs?.getDouble(key);
    val ??= def;
    _memoryPrefs[key] = val;
    return val ?? -1;
  }

  static bool getBool(String key, {bool def = false}) {
    bool? val = _prefs?.getBool(key);
    if (val == null && _memoryPrefs.containsKey(key)) {
      val = _memoryPrefs[key];
    } else {
      val ??= def;
    }
    _memoryPrefs[key] = val!;
    return val;
  }

  static Future<bool> remove(String key) async {
    _memoryPrefs.remove(key);
    return await _prefs?.remove(key) ?? false;
  }

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> removeSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  static Future<bool> clear() async {
    _memoryPrefs.clear();
    return await _prefs?.clear() ?? false;
  }
}