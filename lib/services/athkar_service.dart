import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../models/athkar.dart';

/// Loads Hisnul Muslim from bundled JSON and organizes into categories.
///
/// The raw file is a flat array of items with `ID`, `ARABIC_TEXT`,
/// `TRANSLATED_TEXT`, `REPEAT`. We map ranges of IDs to categories.
class AthkarService {
  AthkarService._();

  static List<AthkarCategory>? _cached;

  /// Category → list of Hisnul Muslim IDs.
  ///
  /// Source: standard Hisnul Muslim chapter structure.
  /// NOTE: You can customize these ranges after inspecting your JSON file.
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
  static Future<List<AthkarCategory>> loadAll() async {
    if (_cached != null) return _cached!;

    final raw = await rootBundle.loadString('assets/athkar/hisnul_muslim.json');
    final decoded = json.decode(raw);

    // Handle both flat array and {items: [...]} wrapper
    final List<dynamic> rawItems;
    if (decoded is List) {
      rawItems = decoded;
    } else if (decoded is Map && decoded['items'] is List) {
      rawItems = decoded['items'] as List;
    } else {
      debugPrint('AthkarService: unexpected JSON shape');
      return [];
    }

    // Index by ID
    final byId = <int, Map<String, dynamic>>{};
    for (final item in rawItems) {
      if (item is Map<String, dynamic> && item['ID'] != null) {
        byId[item['ID'] as int] = item;
      }
    }

    // Build categories
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
          arabic: (raw['ARABIC_TEXT'] ?? '').toString(),
          transliteration:
              (raw['LANGUAGE_ARABIC_TRANSLATED_TEXT'] ?? '').toString(),
          translation: (raw['TRANSLATED_TEXT'] ?? '').toString(),
          repeatCount: (raw['REPEAT'] ?? 1) is int
              ? raw['REPEAT'] as int
              : int.tryParse(raw['REPEAT'].toString()) ?? 1,
          reference: raw['REFERENCE']?.toString(),
          virtue: raw['VIRTUE']?.toString(),
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
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
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