import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/streak_provider.dart';
import '../repositories/prayer_repository.dart';
import 'himmah_service.dart';
import 'lock_service.dart';

class SchedulerService {
  SchedulerService._();

  static Future<int> runDailyMaintenance({
    required String userId,
    required StreakProvider streakProvider,
  }) async {
    int swept = 0;
    try {
      final repo = PrayerRepository(Supabase.instance.client);
      swept = await repo.sweepMissedPrayers(userId: userId);

      // Award daily streak himmah (once per day, idempotent by streak value)
      await streakProvider.loadForUser(userId);
      final streak = streakProvider.currentStreak;
      if (streak > 0) {
        final himmahToday = HimmahService.dailyStreakHimmah(streak);
        if (himmahToday > 0) {
          await _awardOncePerDay(
            userId: userId,
            amount: himmahToday,
            reason: 'streak_day',
            ref: 'day_${DateTime.now().toIso8601String().split('T').first}',
          );
        }
      }

      // Detect streak loss
      final lost = await streakProvider.checkAndHandleLoss(userId: userId);
      if (lost != null) {
        debugPrint('Streak lost: $lost');
      }

      // If sweep affected any prayer, evaluate lock
      if (swept > 0) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('is_locked, locked_prayer')
            .eq('id', userId)
            .maybeSingle();
        if (profile == null || profile['is_locked'] != true) {
          // Lock for the most recent missed prayer
          final missed = await Supabase.instance.client
              .from('prayer_logs')
              .select('prayer, date')
              .eq('user_id', userId)
              .eq('status', 'missed')
              .eq('sayyiat_repented', false)
              .order('date', ascending: false)
              .limit(1)
              .maybeSingle();
          if (missed != null) {
            await LockService.lockForMissedPrayer(
              userId: userId,
              prayer: missed['prayer'] as String,
              date: DateTime.parse(missed['date'] as String),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('SchedulerService: $e');
    }
    return swept;
  }

  static Future<void> _awardOncePerDay({
    required String userId,
    required int amount,
    required String reason,
    required String ref,
  }) async {
    final existing = await Supabase.instance.client
        .from('himmah_transactions')
        .select('id')
        .eq('user_id', userId)
        .eq('reference_id', ref)
        .maybeSingle();
    if (existing != null) return;
    await HimmahService.award(
        userId: userId, amount: amount, reason: reason, referenceId: ref);
  }
}