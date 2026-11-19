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
    final res = await Supabase.instance.client.rpc(
      'award_himmah',
      params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_reason': reason,
        'p_reference_id': referenceId,
      },
    );
    return (res as num).toInt();
  }

  static Future<void> spend({
    required String userId,
    required int amount,
    required String reason,
    String? referenceId,
  }) async {
    await Supabase.instance.client.rpc(
      'spend_himmah',
      params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_reason': reason,
        'p_reference_id': referenceId,
      },
    );
  }

  static Future<int> currentBalance(String userId) async {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('himmah')
        .eq('id', userId)
        .maybeSingle();
    return (row?['himmah'] as int?) ?? 0;
  }

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