import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  LocalPrefs._();
  static final LocalPrefs instance = LocalPrefs._();

  SharedPreferences? _prefs;
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = (await prefs).getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await (await prefs).setString(key, jsonEncode(value));
  }

  Future<List<Map<String, dynamic>>> getJsonList(String key) async {
    final raw = (await prefs).getString(key);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> v) async {
    await (await prefs).setString(key, jsonEncode(v));
  }

  Future<String?> getString(String key) async => (await prefs).getString(key);
  Future<void> setString(String key, String v) async => (await prefs).setString(key, v);
  Future<void> remove(String key) async => (await prefs).remove(key);
}