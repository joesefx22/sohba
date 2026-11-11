import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/streak_provider.dart';
import '../repositories/prayer_repository.dart';
import 'himmah_service.dart';

class SchedulerService {
  SchedulerService._();

  static Future<int> runDailyMaintenance({
    required String userId,
    required StreakProvider streakProvider,
  }) async {
    int swept = 0;
    try {
      final repo = PrayerRepository(Supabase.instance.client);
      // sweep + lock (داخلياً على السيرفر)
      swept = await repo.sweepMissedPrayers(userId: userId);

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

      final lost = await streakProvider.checkAndHandleLoss(userId: userId);
      if (lost != null) debugPrint('Streak lost: $lost');
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
    try {
      await HimmahService.award(
        userId: userId,
        amount: amount,
        reason: reason,
        referenceId: ref,
      );
    } catch (e) {
      debugPrint('SchedulerService._awardOncePerDay: $e');
    }
  }
}