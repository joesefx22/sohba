import 'package:flutter/foundation.dart';

import '../models/badge.dart';
import '../models/athkar.dart';
import '../models/prayer_log.dart';

/// Computes all streak/metric values that badges depend on.
///
/// Given 60 days of prayer logs and today's athkar progress,
/// produces a [BadgeContext] the BadgeProvider can evaluate.
class BadgeEngine {
  BadgeEngine._();

  /// Build a [BadgeContext] from the user's recent history.
  ///
  /// [prayerLogs] should cover at least the last 60 days,
  /// ordered descending by date.
  /// [athkarItemsToday] = all today's items across mandatory categories.
  /// [athkarProgressToday] = map of itemId → completed.
  static BadgeContext compute({
    required List<PrayerLog> prayerLogs,
    required List<AthkarItem> athkarItemsToday,
    required Map<String, bool> athkarProgressToday,
  }) {
    // Organize logs by date
    final byDate = <DateTime, Map<PrayerName, PrayerLog>>{};
    for (final log in prayerLogs) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      byDate.putIfAbsent(day, () => {});
      byDate[day]![log.prayer] = log;
    }

    final sortedDays = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 1. Fajr congregation streak
    final fajrStreak = _consecutiveStreak(
      sortedDays,
      todayDate,
      (log) => log.status == PrayerStatus.congregation,
      prayer: PrayerName.fajr,
      byDate: byDate,
    );

    // 2. All 5 prayers on time (congregation OR individual, not qada/missed)
    final allPrayersStreak = _consecutiveStreak(
      sortedDays,
      todayDate,
      (log) => log.status == PrayerStatus.congregation ||
          log.status == PrayerStatus.individual,
      requireAllPrayers: true,
      byDate: byDate,
    );

    // 3. Qiyam al-layl streak — detected by isha congregation
    //    (a proxy for "woke up for qiyam").
    final qiyamStreak = _consecutiveStreak(
      sortedDays,
      todayDate,
      (log) => log.status == PrayerStatus.congregation,
      prayer: PrayerName.isha,
      byDate: byDate,
    );

    // 4. Athkar streak — conservative value from today only.
    final athkarCompleteToday = athkarItemsToday.isNotEmpty &&
        athkarItemsToday.every((i) => athkarProgressToday[i.id] == true);
    final athkarStreak = athkarCompleteToday ? 1 : 0;

    // 5. Overall streak — any prayer recorded per day
    final overallStreak = _consecutiveStreak(
      sortedDays,
      todayDate,
      (log) => log.status != PrayerStatus.pending &&
          log.status != PrayerStatus.missed,
      byDate: byDate,
    );

    // 6. Total hasanat
    final totalHasanat =
        prayerLogs.fold<int>(0, (sum, log) => sum + log.hasanat);

    return BadgeContext(
      fajrCongregationStreak: fajrStreak,
      allPrayersOnTimeDays: allPrayersStreak,
      qiyamStreak: qiyamStreak,
      athkarStreak: athkarStreak,
      overallStreak: overallStreak,
      totalHasanat: totalHasanat,
    );
  }

  /// Count consecutive days from [today] backwards where the
  /// predicate holds.
  ///
  /// - If [requireAllPrayers] is true → ALL 5 prayers must match.
  /// - Else if [prayer] is provided → only that prayer must match.
  /// - Else → ANY prayer in the day must match (used for overall streak).
  static int _consecutiveStreak(
    List<DateTime> sortedDays,
    DateTime today,
    bool Function(PrayerLog) predicate, {
    PrayerName? prayer,
    bool requireAllPrayers = false,
    required Map<DateTime, Map<PrayerName, PrayerLog>> byDate,
  }) {
    if (sortedDays.isEmpty) return 0;

    // If today isn't in the list, allow streak to start from yesterday
    final yesterday = today.subtract(const Duration(days: 1));
    final start = sortedDays.first == today ? today : yesterday;

    int streak = 0;
    DateTime cursor = start;

    for (int i = 0; i < sortedDays.length; i++) {
      final dayMap = byDate[cursor];
      if (dayMap == null) break;

      bool dayQualifies;
      if (requireAllPrayers) {
        dayQualifies = PrayerName.values.every((p) {
          final log = dayMap[p];
          return log != null && predicate(log);
        });
      } else if (prayer != null) {
        final log = dayMap[prayer];
        dayQualifies = log != null && predicate(log);
      } else {
        // FIX: no specific prayer requested — check if ANY prayer matches
        dayQualifies = dayMap.values.any(predicate);
      }

      if (!dayQualifies) break;

      streak++;
      cursor = cursor.subtract(const Duration(days: 1));

      // Safety: stop at 400 days
      if (streak > 400) break;
    }

    return streak;
  }

  /// Debug helper.
  static void debugLogContext(BadgeContext ctx) {
    debugPrint('BadgeContext:');
    debugPrint('  fajr_congregation_streak: ${ctx.fajrCongregationStreak}');
    debugPrint('  all_prayers_on_time:      ${ctx.allPrayersOnTimeDays}');
    debugPrint('  qiyam_streak:             ${ctx.qiyamStreak}');
    debugPrint('  athkar_streak:            ${ctx.athkarStreak}');
    debugPrint('  overall_streak:           ${ctx.overallStreak}');
    debugPrint('  total_hasanat:            ${ctx.totalHasanat}');
  }
}