import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class HimmahService {
  HimmahService._();

  static Future<int> award({
    required String userId,
    required int amount,
    required String reason,
    String? referenceId,
  }) async {
    final row = await Supabase.instance.client
        .from('himmah_transactions')
        .insert({
          'user_id': userId,
          'amount': amount,
          'reason': reason,
          'reference_id': referenceId,
        })
        .select('balance_after')
        .single();
    return (row['balance_after'] as int?) ?? 0;
  }

  static Future<void> spend({
    required String userId,
    required int amount,
    required String reason,
    String? referenceId,
  }) async {
    await Supabase.instance.client.from('himmah_transactions').insert({
      'user_id': userId,
      'amount': -amount.abs(),
      'reason': reason,
      'reference_id': referenceId,
    });
  }

  static Future<int> currentBalance(String userId) async {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('himmah')
        .eq('id', userId)
        .maybeSingle();
    return (row?['himmah'] as int?) ?? 0;
  }

  /// Streak day bonus: 1 himmah per day of consecutive streak (capped).
  static int dailyStreakHimmah(int streak) {
    if (streak >= 30) return 3;
    if (streak >= 14) return 2;
    if (streak >= 7) return 1;
    if (streak >= 1) return 1;
    return 0;
  }

  static int milestoneHimmah(int milestone) {
    for (final e in AppConfig.himmahMilestones.entries) {
      if (e.key == milestone) return e.value;
    }
    return 0;
  }
}