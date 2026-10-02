import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/prayer_log.dart';
import 'adhan_service.dart';

/// The current phase of a prayer's timeline.
enum PrayerPhase {
  /// Adhan has not been called yet.
  beforeAdhan,

  /// Adhan called, but congregation window hasn't opened yet.
  waitingForCongregation,

  /// Congregation window is currently open.
  congregationOpen,

  /// Congregation window closed; individual window is open.
  individualOpen,

  /// Individual window closed; qada window is open.
  qadaOpen,

  /// All windows closed — prayer is considered missed.
  missed,
}

extension PrayerPhaseX on PrayerPhase {
  String get arabicLabel {
    switch (this) {
      case PrayerPhase.beforeAdhan:
        return 'لم يدخل الوقت بعد';
      case PrayerPhase.waitingForCongregation:
        return 'وقت الجماعة لم يفتح بعد';
      case PrayerPhase.congregationOpen:
        return 'وقت الجماعة مفتوح';
      case PrayerPhase.individualOpen:
        return 'وقت الانفراد';
      case PrayerPhase.qadaOpen:
        return 'وقت القضاء';
      case PrayerPhase.missed:
        return 'فائتة';
    }
  }
}

/// Represents the full computed timeline for one prayer on one day.
///
/// This is the **output** of [PrayerEngine.computeTimeline] — it's
/// immutable and purely derived from the adhan times + config.
class PrayerTimeline {
  final PrayerName prayer;
  final DateTime date;

  final DateTime adhan;
  final DateTime sunrise; // only meaningful for Fajr

  final DateTime congregationOpen;
  final DateTime congregationClose;

  final DateTime individualOpen;
  final DateTime individualClose;

  final DateTime qadaOpen;
  final DateTime qadaClose; // = same prayer tomorrow's adhan

  const PrayerTimeline({
    required this.prayer,
    required this.date,
    required this.adhan,
    required this.sunrise,
    required this.congregationOpen,
    required this.congregationClose,
    required this.individualOpen,
    required this.individualClose,
    required this.qadaOpen,
    required this.qadaClose,
  });

  /// Which phase is active at [now]?
  PrayerPhase phaseAt(DateTime now) {
    if (now.isBefore(adhan)) return PrayerPhase.beforeAdhan;
    if (now.isBefore(congregationOpen)) {
      return PrayerPhase.waitingForCongregation;
    }
    if (now.isBefore(congregationClose)) {
      return PrayerPhase.congregationOpen;
    }
    if (now.isBefore(individualClose)) {
      return PrayerPhase.individualOpen;
    }
    if (now.isBefore(qadaClose)) return PrayerPhase.qadaOpen;
    return PrayerPhase.missed;
  }

  /// Duration until [phase] opens (zero if already open or passed).
  Duration timeUntil(DateTime target, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (current.isAfter(target)) return Duration.zero;
    return target.difference(current);
  }

  Map<String, dynamic> toJson() => {
        'prayer': prayer.name,
        'date': date.toIso8601String(),
        'adhan': adhan.toIso8601String(),
        'sunrise': sunrise.toIso8601String(),
        'congregation_open': congregationOpen.toIso8601String(),
        'congregation_close': congregationClose.toIso8601String(),
        'individual_open': individualOpen.toIso8601String(),
        'individual_close': individualClose.toIso8601String(),
        'qada_open': qadaOpen.toIso8601String(),
        'qada_close': qadaClose.toIso8601String(),
      };
}

/// The heart of Sohba — computes per-prayer timelines and decides
/// which phase the user is in at any given moment.
///
/// Pure functions, no state. All dependencies are injected via
/// [AdhanService] and [AppConfig], so this class is fully testable.
class PrayerEngine {
  PrayerEngine._();

  /// Compute the timeline for [prayer] on the given [date].
  ///
  /// If [date] is null, uses today.
  static PrayerTimeline computeTimeline({
    required PrayerName prayer,
    DateTime? date,
    DateTime? now,
  }) {
    final today = date ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Adhan time for this prayer today
    final adhan = AdhanService.timeFor(prayer, onDate: todayDate);

    // Sunrise (needed only for Fajr, but harmless for others)
    final sunrise = AdhanService.sunrise(onDate: todayDate);

    // Congregation window
    final congregationOpen = adhan.add(
      const Duration(minutes: AppConfig.congregationWindowOpenDelay),
    );
    final congregationClose = congregationOpen.add(
      const Duration(minutes: AppConfig.congregationWindowDuration),
    );

    // Individual window closes [individualWindowCloseBuffer] minutes
    // before the *next* prayer's adhan.
    final nextPrayer = _nextPrayerAfter(prayer);
    final nextAdhan = AdhanService.timeFor(
      nextPrayer,
      onDate: todayDate,
    );
    final individualClose = nextAdhan.subtract(
      const Duration(minutes: AppConfig.individualWindowCloseBuffer),
    );

    // Qada window: from end of individual until this prayer tomorrow
    final tomorrow = todayDate.add(const Duration(days: 1));
    final tomorrowAdhan = AdhanService.timeFor(prayer, onDate: tomorrow);

    return PrayerTimeline(
      prayer: prayer,
      date: todayDate,
      adhan: adhan,
      sunrise: sunrise,
      congregationOpen: congregationOpen,
      congregationClose: congregationClose,
      individualOpen: congregationClose,
      individualClose: individualClose,
      qadaOpen: individualClose,
      qadaClose: tomorrowAdhan,
    );
  }

  /// Compute timelines for all 5 prayers on [date].
  static Map<PrayerName, PrayerTimeline> computeAllTimelines({
    DateTime? date,
    DateTime? now,
  }) {
    return {
      for (final p in PrayerName.values)
        p: computeTimeline(prayer: p, date: date, now: now),
    };
  }

  /// Determine the hasanat awarded if the user records
  /// [status] for [prayer] at time [now].
  static int hasanatFor({
    required PrayerName prayer,
    required PrayerStatus status,
    required DateTime now,
    DateTime? date,
  }) {
    final timeline = computeTimeline(
      prayer: prayer,
      date: date,
      now: now,
    );
    final phase = timeline.phaseAt(now);

    if (status == PrayerStatus.congregation) {
      // Only allowed inside the congregation window
      if (phase == PrayerPhase.congregationOpen) {
        return AppConfig.hasanatPerCongregation;
      }
      // If outside the window, degrade to individual
      return AppConfig.hasanatPerIndividual;
    }

    if (status == PrayerStatus.individual) {
      if (phase == PrayerPhase.individualOpen) {
        return AppConfig.hasanatPerIndividual;
      }
      // If qada window, individual becomes qada
      if (phase == PrayerPhase.qadaOpen) {
        return 0; // qada doesn't award hasanat
      }
    }

    if (status == PrayerStatus.qada) {
      // qada awards no hasanat, but clears the sayyiat
      return 0;
    }

    return 0;
  }

  /// Determine the sayyiat recorded if the user misses [prayer].
  static int sayyiatForMissed(PrayerName prayer) {
    return AppConfig.sayyiatPerMissedPrayer;
  }

  /// Validate whether the user is allowed to record [status]
  /// for [prayer] at [now]. Returns null if allowed, or an error
  /// message otherwise.
  static String? validateStatus({
    required PrayerName prayer,
    required PrayerStatus status,
    required DateTime now,
    DateTime? date,
  }) {
    final timeline = computeTimeline(prayer: prayer, date: date, now: now);
    final phase = timeline.phaseAt(now);

    if (phase == PrayerPhase.beforeAdhan) {
      return 'لم يدخل وقت ${prayer.arabicName} بعد';
    }

    if (status == PrayerStatus.congregation &&
        phase != PrayerPhase.congregationOpen) {
      return 'وقت الجماعة انتهى — يمكنك التسجيل كمنفردًا';
    }

    if (status == PrayerStatus.individual &&
        phase != PrayerPhase.individualOpen &&
        phase != PrayerPhase.congregationOpen) {
      return 'لم يعد وقت الانفراد متاحًا — يمكنك القضاء';
    }

    if (status == PrayerStatus.qada && phase != PrayerPhase.qadaOpen) {
      return 'وقت القضاء لم يبدأ بعد';
    }

    if (status == PrayerStatus.missed && phase != PrayerPhase.missed) {
      return 'لم تنتهِ نافذة القضاء بعد';
    }

    return null;
  }

  // ============================================
  // HELPERS
  // ============================================

  static PrayerName _nextPrayerAfter(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return PrayerName.dhuhr;
      case PrayerName.dhuhr:
        return PrayerName.asr;
      case PrayerName.asr:
        return PrayerName.maghrib;
      case PrayerName.maghrib:
        return PrayerName.isha;
      case PrayerName.isha:
        return PrayerName.fajr; // wraps around
    }
  }

  /// For Fajr, the "next" prayer is Dhuhr the same day. For Isha,
  /// the "next" is Fajr the next day — but since we compute per-day
  /// timelines, we treat it as Fajr of the same day and the buffer
  /// naturally falls on the correct side.
  static DateTime nextPrayerAdhan(PrayerName prayer, DateTime date) {
    final next = _nextPrayerAfter(prayer);
    if (prayer == PrayerName.isha) {
      // Isha's next is tomorrow's Fajr
      final tomorrow = date.add(const Duration(days: 1));
      return AdhanService.timeFor(next, onDate: tomorrow);
    }
    return AdhanService.timeFor(next, onDate: date);
  }

  /// Debug: pretty-print a timeline.
  static void debugPrintTimeline(PrayerTimeline t) {
    debugPrint('━━━ ${t.prayer.arabicName} ━━━');
    debugPrint('Adhan:              ${AdhanService.formatTime(t.adhan)}');
    debugPrint('Congregation opens: ${AdhanService.formatTime(t.congregationOpen)}');
    debugPrint('Congregation close: ${AdhanService.formatTime(t.congregationClose)}');
    debugPrint('Individual closes:  ${AdhanService.formatTime(t.individualClose)}');
    debugPrint('Qada closes:        ${AdhanService.formatTime(t.qadaClose)}');
  }
}