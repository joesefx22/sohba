import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'athkar_service.dart';

/// One-shot helper that pushes the bundled Hisnul Muslim JSON
/// into Supabase. Idempotent (uses upsert). Safe to run multiple times.
///
/// Call from an admin-only debug screen or a maintenance task.
class AthkarSeeder {
  AthkarSeeder._();

  static Future<bool> seed(SupabaseClient client) async {
    try {
      final categories = await AthkarService.loadAll();

      if (categories.isEmpty) {
        debugPrint('AthkarSeeder: no categories loaded from JSON');
        return false;
      }

      int catCount = 0;
      int itemCount = 0;

      for (final cat in categories) {
        await client.from('athkar_categories').upsert({
          'id': cat.id,
          'name_ar': cat.nameAr,
          'name_en': cat.nameEn,
          'icon': cat.icon,
          'display_order': cat.displayOrder,
          'is_mandatory': cat.isMandatory,
        });
        catCount++;

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
          itemCount++;
        }
      }

      debugPrint('AthkarSeeder: seeded $catCount categories, $itemCount items');
      return true;
    } catch (e) {
      debugPrint('AthkarSeeder.seed error: $e');
      return false;
    }
  }

  /// Check if the DB already has athkar seeded.
  static Future<bool> isSeeded(SupabaseClient client) async {
    try {
      final res = await client
          .from('athkar_categories')
          .select('id')
          .limit(1);
      return (res as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}