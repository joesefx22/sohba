import 'package:sohba/config/app_config.dart';
import 'package:sohba/models/prayer_log.dart';
import 'package:sohba/services/adhan_service.dart';

/// ═══════════════════════════════════════════════════════════
/// PrayerEngine — منطق نظام الصلاة المبسّط
/// ═══════════════════════════════════════════════════════════
/// القواعد:
/// 1. الصلاة P في اليوم D متاحة من أذان P(D) لحد فجر (D+1).
/// 2. بعد فجر (D+1) بدون تسجيل → missed (+200 سيئة).
/// 3. لا نوافذ زمنية، لا قضاء.
/// "يوم الصلاة D" = من فجر(D) إلى فجر(D+1).
class PrayerEngine {
  PrayerEngine._();

  /// يرجّع "يوم الصلاة" الحالي.
  static DateTime currentPrayerDay(DateTime now) {
    final todayFajr = AdhanService.timesForDate(now)[PrayerName.fajr]!;
    final midnight = DateTime(now.year, now.month, now.day);
    return now.isBefore(todayFajr)
        ? midnight.subtract(const Duration(days: 1))
        : midnight;
  }

  /// الموعد النهائي ليوم [day] = فجر (day+1).
  static DateTime deadlineForDay(DateTime day) =>
      AdhanService.timesForDate(
        DateTime(day.year, day.month, day.day).add(const Duration(days: 1)),
      )[PrayerName.fajr]!;

  static Map<PrayerName, PrayerStatus> computeStatuses({
    required DateTime date,
    required Map<PrayerName, PrayerStatus> logged,
    required DateTime now,
  }) {
    final times = AdhanService.timesForDate(date);
    final deadline = deadlineForDay(date);
    final result = <PrayerName, PrayerStatus>{};

    for (final p in PrayerName.values) {
      final recorded = logged[p];
      final adhan = times[p]!;

      if (recorded == PrayerStatus.congregation ||
          recorded == PrayerStatus.individual ||
          recorded == PrayerStatus.missed) {
        result[p] = recorded!;
      } else if (now.isBefore(adhan)) {
        result[p] = PrayerStatus.upcoming;
      } else if (now.isBefore(deadline)) {
        result[p] = PrayerStatus.pending;
      } else {
        result[p] = PrayerStatus.missed;
      }
    }
    return result;
  }

  /// الصلوات اللي "جت" في يوم [date] — لعرضها في صفحة الصلاة.
  static List<PrayerName> arrivedPrayers({
    required DateTime date,
    required DateTime now,
  }) {
    final times = AdhanService.timesForDate(date);
    return PrayerName.values.where((p) => !now.isBefore(times[p]!)).toList();
  }

  /// الصلاة اللي عليها الدور في الرئيسية.
  static ({PrayerName prayer, PrayerStatus status, DateTime at}) currentOrNext({
    required DateTime date,
    required Map<PrayerName, PrayerStatus> statuses,
    required DateTime now,
  }) {
    for (final p in PrayerName.values) {
      if (statuses[p] == PrayerStatus.pending) {
        return (prayer: p, status: PrayerStatus.pending,
                at: AdhanService.timesForDate(date)[p]!);
      }
    }
    for (final p in PrayerName.values) {
      if (statuses[p] == PrayerStatus.upcoming) {
        return (prayer: p, status: PrayerStatus.upcoming,
                at: AdhanService.timesForDate(date)[p]!);
      }
    }
    final tomorrowFajr = AdhanService.timesForDate(
      DateTime(date.year, date.month, date.day).add(const Duration(days: 1)),
    )[PrayerName.fajr]!;
    return (prayer: PrayerName.fajr, status: PrayerStatus.upcoming, at: tomorrowFajr);
  }

  static (int, int) rewardsFor(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.congregation:
        return (AppConfig.hasanatPerCongregation, 0);
      case PrayerStatus.individual:
        return (AppConfig.hasanatPerIndividual, 0);
      case PrayerStatus.missed:
        return (0, AppConfig.sayyiatPerMissedPrayer);
      default:
        return (0, 0);
    }
  }
}