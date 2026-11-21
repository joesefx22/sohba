import 'package:sohba/config/app_config.dart';
import 'package:sohba/models/prayer_log.dart';
import 'package:sohba/services/adhan_service.dart';

/// ═══════════════════════════════════════════════════════════
/// Legacy phase/timeline — للتوافق مع prayer_card.dart
/// (النظام الجديد يستخدم PrayerStatus بدلًا منه، لكن UI القديم لسه)
/// ═══════════════════════════════════════════════════════════
enum PrayerPhase {
  beforeAdhan,
  waitingForCongregation,
  congregationOpen,
  individualOpen,
  qadaOpen,
  missed,
}

class PrayerTimeline {
  final PrayerName prayer;
  final DateTime adhan;
  final DateTime congregationOpen;
  final DateTime congregationClose;
  final DateTime individualClose;
  final DateTime qadaClose;

  const PrayerTimeline({
    required this.prayer,
    required this.adhan,
    required this.congregationOpen,
    required this.congregationClose,
    required this.individualClose,
    required this.qadaClose,
  });

  PrayerPhase phaseAt(DateTime now) {
    if (now.isBefore(adhan)) return PrayerPhase.beforeAdhan;
    if (now.isBefore(congregationOpen)) {
      return PrayerPhase.waitingForCongregation;
    }
    if (now.isBefore(congregationClose)) return PrayerPhase.congregationOpen;
    if (now.isBefore(individualClose)) return PrayerPhase.individualOpen;
    if (now.isBefore(qadaClose)) return PrayerPhase.qadaOpen;
    return PrayerPhase.missed;
  }
}

/// ═══════════════════════════════════════════════════════════
/// PrayerEngine — منطق نظام الصلاة المبسّط (الرئيسي)
/// ═══════════════════════════════════════════════════════════
/// القواعد:
/// 1. الصلاة P في اليوم D متاحة من أذان P(D) لحد فجر (D+1).
/// 2. بعد فجر (D+1) بدون تسجيل → missed (+200 سيئة).
/// 3. لا نوافذ زمنية، لا قضاء.
class PrayerEngine {
  PrayerEngine._();

  // Legacy windows — تستخدمها الـ timeline فقط.
  static const int _congOpenDelay = 40;
  static const int _congDuration = 30;
  static const int _individualCloseBuffer = 15;
  static const Duration _qadaWindow = Duration(hours: 24);

  // ============================================
  // النظام الجديد
  // ============================================

  static DateTime currentPrayerDay(DateTime now) {
    final todayFajr = AdhanService.timesForDate(now)[PrayerName.fajr]!;
    final midnight = DateTime(now.year, now.month, now.day);
    return now.isBefore(todayFajr)
        ? midnight.subtract(const Duration(days: 1))
        : midnight;
  }

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

  static List<PrayerName> arrivedPrayers({
    required DateTime date,
    required DateTime now,
  }) {
    final times = AdhanService.timesForDate(date);
    return PrayerName.values.where((p) => !now.isBefore(times[p]!)).toList();
  }

  static ({PrayerName prayer, PrayerStatus status, DateTime at}) currentOrNext({
    required DateTime date,
    required Map<PrayerName, PrayerStatus> statuses,
    required DateTime now,
  }) {
    for (final p in PrayerName.values) {
      if (statuses[p] == PrayerStatus.pending) {
        return (
          prayer: p,
          status: PrayerStatus.pending,
          at: AdhanService.timesForDate(date)[p]!,
        );
      }
    }
    for (final p in PrayerName.values) {
      if (statuses[p] == PrayerStatus.upcoming) {
        return (
          prayer: p,
          status: PrayerStatus.upcoming,
          at: AdhanService.timesForDate(date)[p]!,
        );
      }
    }
    final tomorrowFajr = AdhanService.timesForDate(
      DateTime(date.year, date.month, date.day).add(const Duration(days: 1)),
    )[PrayerName.fajr]!;
    return (
      prayer: PrayerName.fajr,
      status: PrayerStatus.upcoming,
      at: tomorrowFajr,
    );
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

  // ============================================
  // Legacy timeline API
  // ============================================

  static Map<PrayerName, PrayerTimeline> computeAllTimelines({
    DateTime? onDate,
  }) {
    final date = onDate ?? DateTime.now();
    return {
      for (final p in PrayerName.values) p: computeTimeline(p, onDate: date),
    };
  }

  static PrayerTimeline computeTimeline(
    PrayerName prayer, {
    DateTime? onDate,
  }) {
    final date = onDate ?? DateTime.now();
    final adhan = AdhanService.timesForDate(date)[prayer]!;
    final congregationOpen =
        adhan.add(const Duration(minutes: _congOpenDelay));
    final congregationClose =
        congregationOpen.add(const Duration(minutes: _congDuration));
    final individualClose = _nextAdhan(prayer, date)
        .subtract(const Duration(minutes: _individualCloseBuffer));
    final qadaClose = adhan.add(_qadaWindow);

    return PrayerTimeline(
      prayer: prayer,
      adhan: adhan,
      congregationOpen: congregationOpen,
      congregationClose: congregationClose,
      individualClose: individualClose,
      qadaClose: qadaClose,
    );
  }

  static DateTime _nextAdhan(PrayerName prayer, DateTime date) {
    if (prayer == PrayerName.isha) {
      return AdhanService.timesForDate(
        date.add(const Duration(days: 1)),
      )[PrayerName.fajr]!;
    }
    final next = PrayerName.values[prayer.index + 1];
    return AdhanService.timesForDate(date)[next]!;
  }
}