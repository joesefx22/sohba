import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class StorageService {
  static final _prefs = SharedPreferences.getInstance();

  // Legacy methods (kept for backward compatibility)
  static Future<void> saveData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(value));
  }

  static Future<dynamic> loadData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return json.decode(prefs.getString(key) ?? '{}');
  }

  // Liste speichern
  static Future<bool> saveList<T>(
    String key,
    List<T> list,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      final prefs = await _prefs;
      final jsonList = list.map((item) => toJson(item)).toList();
      return prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('StorageService.saveList error: $e');
      return false;
    }
  }

  // Liste laden
  static Future<List<T>> loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString(key);
      if (jsonString == null) return [];
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => fromJson(json)).toList();
    } catch (e) {
      debugPrint('StorageService.loadList error: $e');
      return [];
    }
  }

  // Objekt speichern
  static Future<bool> saveObject<T>(
    String key,
    T object,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      final prefs = await _prefs;
      return prefs.setString(key, jsonEncode(toJson(object)));
    } catch (e) {
      debugPrint('StorageService.saveObject error: $e');
      return false;
    }
  }

  // Objekt laden
  static Future<T?> loadObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;
      return fromJson(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('StorageService.loadObject error: $e');
      return null;
    }
  }

  // Löschen
  static Future<bool> remove(String key) async {
    final prefs = await _prefs;
    return prefs.remove(key);
  }

  // Alles löschen (für Tests)
  static Future<bool> clear() async {
    final prefs = await _prefs;
    return prefs.clear();
  }
}
