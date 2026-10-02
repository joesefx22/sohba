import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lock_state.dart';

class LockService {
  LockService._();

  static Future<void> lockForMissedPrayer({
    required String userId,
    required String prayer,
    required DateTime date,
  }) async {
    try {
      await Supabase.instance.client.rpc(
        'lock_user_for_missed_prayer',
        params: {
          'p_user_id': userId,
          'p_prayer': prayer,
          'p_date':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        },
      );
    } catch (e) {
      debugPrint('LockService.lockForMissedPrayer: $e');
    }
  }

  static Future<void> unlock(String userId) async {
    try {
      await Supabase.instance.client.rpc(
        'unlock_user',
        params: {'p_user_id': userId},
      );
    } catch (e) {
      debugPrint('LockService.unlock: $e');
    }
  }

  static LockState readFrom(Map<String, dynamic>? profile) =>
      LockState.fromProfile(profile);
}