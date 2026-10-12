import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/athkar.dart';

/// Loads Hisnul Muslim from bundled JSON and organizes into categories.
///
/// The raw file is a flat array of items with `ID`, `ARABIC_TEXT`,
/// `TRANSLATED_TEXT`, `REPEAT`. We map ranges of IDs to categories.
class AthkarService {
  AthkarService._();

  static List<AthkarCategory>? _cached;

  /// Category → list of Hisnul Muslim IDs.
  static const Map<String, CategoryMeta> categoryMeta = {
    'morning': CategoryMeta(
      nameAr: 'أذكار الصباح',
      nameEn: 'Morning Remembrance',
      icon: 'wb_twilight',
      displayOrder: 1,
      isMandatory: true,
      ids: [
        75, 76, 77, 78, 79, 80, 81, 82, 83,
        84, 85, 86, 87, 88, 89, 90, 91, 92,
      ],
    ),
    'evening': CategoryMeta(
      nameAr: 'أذكار المساء',
      nameEn: 'Evening Remembrance',
      icon: 'nights_stay',
      displayOrder: 2,
      isMandatory: true,
      ids: [
        93, 94, 95, 96, 97, 98, 99, 100, 101,
        102, 103, 104, 105, 106, 107, 108, 109, 110,
      ],
    ),
    'after_prayer': CategoryMeta(
      nameAr: 'أذكار بعد الصلاة',
      nameEn: 'After Prayer',
      icon: 'mosque',
      displayOrder: 3,
      isMandatory: true,
      ids: [65, 66, 67, 68, 69, 70, 71, 72, 73, 74],
    ),
    'sleep': CategoryMeta(
      nameAr: 'أذكار النوم',
      nameEn: 'Before Sleep',
      icon: 'bedtime',
      displayOrder: 4,
      isMandatory: false,
      ids: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    ),
    'waking': CategoryMeta(
      nameAr: 'أذكار الاستيقاظ',
      nameEn: 'Upon Waking',
      icon: 'wb_sunny',
      displayOrder: 5,
      isMandatory: false,
      ids: [11, 12, 13, 14, 15, 16],
    ),
  };

  /// Load and cache all categories with their items.
  ///
  /// Returns an empty list on failure (missing asset / malformed JSON)
  /// so the app never crashes on startup.
  static Future<List<AthkarCategory>> loadAll() async {
    if (_cached != null) return _cached!;

    final List<dynamic> rawItems;
    try {
      final raw =
          await rootBundle.loadString('assets/athkar/hisnul_muslim.json');
      final decoded = json.decode(raw);

      if (decoded is List) {
        rawItems = decoded;
      } else if (decoded is Map && decoded['items'] is List) {
        rawItems = decoded['items'] as List;
      } else {
        debugPrint('AthkarService: unexpected JSON shape');
        _cached = const [];
        return _cached!;
      }
    } catch (e, st) {
      debugPrint('AthkarService.loadAll failed: $e\n$st');
      _cached = const [];
      return _cached!;
    }

    // Index by ID (tolerate String or int IDs from JSON).
    final byId = <int, Map<String, dynamic>>{};
    for (final item in rawItems) {
      if (item is! Map) continue;
      final rawId = item['ID'];
      int? id;
      if (rawId is int) {
        id = rawId;
      } else if (rawId is String) {
        id = int.tryParse(rawId);
      }
      if (id == null) continue;
      byId[id] = Map<String, dynamic>.from(item);
    }

    final categories = <AthkarCategory>[];
    for (final entry in categoryMeta.entries) {
      final meta = entry.value;
      final items = <AthkarItem>[];
      var order = 0;

      for (final id in meta.ids) {
        final raw = byId[id];
        if (raw == null) continue;

        items.add(AthkarItem(
          id: 'athkar_$id',
          categoryId: entry.key,
          displayOrder: order++,
          arabic: _str(raw['ARABIC_TEXT']),
          transliteration:
              _nullableStr(raw['LANGUAGE_ARABIC_TRANSLATED_TEXT']),
          translation: _nullableStr(raw['TRANSLATED_TEXT']),
          repeatCount: _intOr(raw['REPEAT'], 1),
          reference: _nullableStr(raw['REFERENCE']),
          virtue: _nullableStr(raw['VIRTUE']),
        ));
      }

      if (items.isEmpty) continue;

      categories.add(AthkarCategory(
        id: entry.key,
        nameAr: meta.nameAr,
        nameEn: meta.nameEn,
        icon: meta.icon,
        displayOrder: meta.displayOrder,
        isMandatory: meta.isMandatory,
        items: items,
      ));
    }

    categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    _cached = categories;
    return categories;
  }

  static Future<AthkarCategory?> loadCategory(String id) async {
    final all = await loadAll();
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Clear cache (useful for tests).
  @visibleForTesting
  static void clearCache() => _cached = null;

  // ----- helpers -----

  static String _str(Object? v) => v?.toString() ?? '';

  static String? _nullableStr(Object? v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static int _intOr(Object? v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }
}

class CategoryMeta {
  final String nameAr;
  final String? nameEn;
  final String icon;
  final int displayOrder;
  final bool isMandatory;
  final List<int> ids;

  const CategoryMeta({
    required this.nameAr,
    this.nameEn,
    required this.icon,
    required this.displayOrder,
    required this.isMandatory,
    required this.ids,
  });
}