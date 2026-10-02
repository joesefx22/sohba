import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/athkar_service.dart';

/// One-time helper: push Hisnul Muslim categories + items to Supabase.
///
/// Call once from a debug screen or from a maintenance task.
/// Since our schema also allows JSON-only mode (AthkarService reads
/// the bundled asset directly), this is optional for MVP.
class AthkarBootstrap {
  AthkarBootstrap._();

  static Future<void> seedToSupabase(SupabaseClient client) async {
    final categories = await AthkarService.loadAll();

    for (final cat in categories) {
      await client.from('athkar_categories').upsert({
        'id': cat.id,
        'name_ar': cat.nameAr,
        'name_en': cat.nameEn,
        'icon': cat.icon,
        'display_order': cat.displayOrder,
        'is_mandatory': cat.isMandatory,
      });

      for (final item in cat.items) {
        await client.from('athkar_items').upsert({
          'id': item.id,
          'category_id': item.categoryId,
          'display_order': item.displayOrder,
          'arabic': item.arabic,
          'transliteration': item.transliteration,
          'translation': item.translation,
          'repeat_count': item.repeatCount,
          'reference': item.reference,
          'virtue': item.virtue,
        });
      }
    }
  }

  /// Debug: log the Hisnul Muslim JSON structure.
  static Future<void> debugLogStructure() async {
    final raw = await rootBundle.loadString('assets/athkar/hisnul_muslim.json');
    final decoded = json.decode(raw);
    print('Root type: ${decoded.runtimeType}');
    if (decoded is List) {
      print('Total items: ${decoded.length}');
      print('First item keys: ${(decoded.first as Map).keys.join(", ")}');
    }
  }
}