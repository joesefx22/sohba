import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/prayer_log.dart';
import 'adhan_service.dart';

enum PrayerPhase {
  beforeAdhan,
  waitingForCongregation,
  congregationOpen,
  individualOpen,
  qadaOpen,
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

class PrayerTimeline {
  final PrayerName prayer;
  final DateTime date;
  final DateTime adhan;
  final DateTime sunrise;
  final DateTime congregationOpen;
  final DateTime congregationClose;
  final DateTime individualOpen;
  final DateTime individualClose;
  final DateTime qadaOpen;
  final DateTime qadaClose;

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

  PrayerPhase phaseAt(DateTime now) {
    if (now.isBefore(adhan)) return PrayerPhase.beforeAdhan;
    if (now.isBefore(congregationOpen)) return PrayerPhase.waitingForCongregation;
    if (now.isBefore(congregationClose)) return PrayerPhase.congregationOpen;
    if (now.isBefore(individualClose)) return PrayerPhase.individualOpen;
    if (now.isBefore(qadaClose)) return PrayerPhase.qadaOpen;
    return PrayerPhase.missed;
  }

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

class PrayerEngine {
  PrayerEngine._();

  static PrayerTimeline computeTimeline({
    required PrayerName prayer,
    DateTime? date,
    DateTime? now,
  }) {
    final today = date ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final adhan = AdhanService.timeFor(prayer, onDate: todayDate);
    final sunrise = AdhanService.sunrise(onDate: todayDate);

    final congregationOpen = adhan.add(
      const Duration(minutes: AppConfig.congregationWindowOpenDelay),
    );
    final congregationClose = congregationOpen.add(
      const Duration(minutes: AppConfig.congregationWindowDuration),
    );

    final nextPrayer = _nextPrayerAfter(prayer);
    final nextAdhan = AdhanService.timeFor(nextPrayer, onDate: todayDate);
    final individualClose = nextAdhan.subtract(
      const Duration(minutes: AppConfig.individualWindowCloseBuffer),
    );

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

  static Map<PrayerName, PrayerTimeline> computeAllTimelines({
    DateTime? date,
    DateTime? now,
  }) {
    return {
      for (final p in PrayerName.values)
        p: computeTimeline(prayer: p, date: date, now: now),
    };
  }

  /// Base hasanat (before streak bonus).
  static int hasanatFor({
    required PrayerName prayer,
    required PrayerStatus status,
    required DateTime now,
    DateTime? date,
  }) {
    final timeline = computeTimeline(prayer: prayer, date: date, now: now);
    final phase = timeline.phaseAt(now);

    if (status == PrayerStatus.congregation) {
      if (phase == PrayerPhase.congregationOpen) {
        return AppConfig.hasanatPerCongregation;
      }
      return AppConfig.hasanatPerIndividual;
    }

    if (status == PrayerStatus.individual) {
      // FIX: allow individual during congregation window too (was returning 0)
      if (phase == PrayerPhase.individualOpen ||
          phase == PrayerPhase.congregationOpen) {
        return AppConfig.hasanatPerIndividual;
      }
      // qada awards 0
      if (phase == PrayerPhase.qadaOpen) return 0;
    }

    if (status == PrayerStatus.qada) return 0;

    return 0;
  }

  /// Hasanat with streak bonus applied.
  static int hasanatWithBonus({
    required PrayerName prayer,
    required PrayerStatus status,
    required DateTime now,
    DateTime? date,
    double bonusMultiplier = 1.0,
  }) {
    final base = hasanatFor(
      prayer: prayer,
      status: status,
      now: now,
      date: date,
    );
    if (base == 0) return 0;
    return (base * bonusMultiplier).round();
  }

  static int sayyiatForMissed(PrayerName prayer) =>
      AppConfig.sayyiatPerMissedPrayer;

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
        return PrayerName.fajr;
    }
  }

  static DateTime nextPrayerAdhan(PrayerName prayer, DateTime date) {
    final next = _nextPrayerAfter(prayer);
    if (prayer == PrayerName.isha) {
      final tomorrow = date.add(const Duration(days: 1));
      return AdhanService.timeFor(next, onDate: tomorrow);
    }
    return AdhanService.timeFor(next, onDate: date);
  }

  static void debugPrintTimeline(PrayerTimeline t) {
    debugPrint('━━━ ${t.prayer.arabicName} ━━━');
    debugPrint('Adhan:              ${AdhanService.formatTime(t.adhan)}');
    debugPrint('Congregation opens: ${AdhanService.formatTime(t.congregationOpen)}');
    debugPrint('Congregation close: ${AdhanService.formatTime(t.congregationClose)}');
    debugPrint('Individual closes:  ${AdhanService.formatTime(t.individualClose)}');
    debugPrint('Qada closes:        ${AdhanService.formatTime(t.qadaClose)}');
  }
}