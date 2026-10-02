import 'package:flutter_test/flutter_test.dart';

import 'package:sohba/config/app_config.dart';
import 'package:sohba/models/prayer_log.dart';
import 'package:sohba/services/adhan_service.dart';
import 'package:sohba/services/prayer_engine.dart';

void main() {
  final testDate = DateTime(2026, 9, 28);

  group('PrayerEngine — Timeline', () {
    test('congregation window opens 40 min after adhan', () {
      final t = PrayerEngine.computeTimeline(
        prayer: PrayerName.fajr,
        date: testDate,
      );
      expect(
        t.congregationOpen.difference(t.adhan).inMinutes,
        AppConfig.congregationWindowOpenDelay,
      );
    });

    test('congregation lasts 30 min', () {
      final t = PrayerEngine.computeTimeline(
        prayer: PrayerName.fajr,
        date: testDate,
      );
      expect(
        t.congregationClose.difference(t.congregationOpen).inMinutes,
        AppConfig.congregationWindowDuration,
      );
    });

    test('dhuhr individual closes 15 min before asr', () {
      final t = PrayerEngine.computeTimeline(
        prayer: PrayerName.dhuhr,
        date: testDate,
      );
      final asr = AdhanService.timeFor(PrayerName.asr, onDate: testDate);
      expect(
        asr.difference(t.individualClose).inMinutes,
        AppConfig.individualWindowCloseBuffer,
      );
    });

    test('qada closes at same prayer tomorrow', () {
      final t = PrayerEngine.computeTimeline(
        prayer: PrayerName.maghrib,
        date: testDate,
      );
      final tomorrowMaghrib = AdhanService.timeFor(
        PrayerName.maghrib,
        onDate: testDate.add(const Duration(days: 1)),
      );
      expect(t.qadaClose, tomorrowMaghrib);
    });
  });

  group('PrayerEngine — Phases', () {
    late PrayerTimeline fajr;

    setUp(() {
      fajr = PrayerEngine.computeTimeline(
        prayer: PrayerName.fajr,
        date: testDate,
      );
    });

    test('before adhan', () {
      expect(
        fajr.phaseAt(fajr.adhan.subtract(const Duration(minutes: 10))),
        PrayerPhase.beforeAdhan,
      );
    });

    test('waiting for congregation', () {
      expect(
        fajr.phaseAt(fajr.adhan.add(const Duration(minutes: 20))),
        PrayerPhase.waitingForCongregation,
      );
    });

    test('congregation open', () {
      expect(
        fajr.phaseAt(fajr.congregationOpen.add(const Duration(minutes: 5))),
        PrayerPhase.congregationOpen,
      );
    });

    test('individual open', () {
      expect(
        fajr.phaseAt(fajr.congregationClose.add(const Duration(minutes: 20))),
        PrayerPhase.individualOpen,
      );
    });

    test('qada open', () {
      expect(
        fajr.phaseAt(fajr.individualClose.add(const Duration(hours: 2))),
        PrayerPhase.qadaOpen,
      );
    });

    test('missed', () {
      expect(
        fajr.phaseAt(fajr.qadaClose.add(const Duration(minutes: 5))),
        PrayerPhase.missed,
      );
    });
  });

  group('PrayerEngine — Hasanat', () {
    test('congregation in window = +27', () {
      final t = PrayerEngine.computeTimeline(
        prayer: PrayerName.fajr,
        date: testDate,
      );
      final inWin = t.congregationOpen.add(const Duration(minutes: 5));
      final h = PrayerEngine.hasanatFor(
        prayer: PrayerName.fajr,
        status: PrayerStatus.congregation,
        now: inWin,
        date: testDate,
      );
      expect(h, 27);
    });

    test('individual in window = +1', () {
      final t = PrayerEngine.computeTimeline(
        prayer: PrayerName.asr,
        date: testDate,
      );
      final inWin = t.congregationClose.add(const Duration(minutes: 20));
      final h = PrayerEngine.hasanatFor(
        prayer: PrayerName.asr,
        status: PrayerStatus.individual,
        now: inWin,
        date: testDate,
      );
      expect(h, 1);
    });

    test('qada = 0', () {
      final t = PrayerEngine.computeTimeline(
        prayer: PrayerName.maghrib,
        date: testDate,
      );
      final inQada = t.individualClose.add(const Duration(hours: 3));
      final h = PrayerEngine.hasanatFor(
        prayer: PrayerName.maghrib,
        status: PrayerStatus.qada,
        now: inQada,
        date: testDate,
      );
      expect(h, 0);
    });

    test('missed = 200 sayyiat', () {
      expect(PrayerEngine.sayyiatForMissed(PrayerName.isha), 200);
    });
  });

  group('PrayerEngine — Validation', () {
    test('rejects congregation before adhan', () {
      final t = PrayerEngine.computeTimeline(
        prayer: PrayerName.fajr,
        date: testDate,
      );
      final err = PrayerEngine.validateStatus(
        prayer: PrayerName.fajr,
        status: PrayerStatus.congregation,
        now: t.adhan.subtract(const Duration(minutes: 30)),
        date: testDate,
      );
      expect(err, isNotNull);
    });

    test('accepts congregation in window', () {
      final t = PrayerEngine.computeTimeline(
        prayer: PrayerName.dhuhr,
        date: testDate,
      );
      final err = PrayerEngine.validateStatus(
        prayer: PrayerName.dhuhr,
        status: PrayerStatus.congregation,
        now: t.congregationOpen.add(const Duration(minutes: 10)),
        date: testDate,
      );
      expect(err, isNull);
    });
  });

  group('PrayerLog — Model', () {
    test('empty has pending status', () {
      final log = PrayerLog.empty(
        userId: 'u1',
        date: testDate,
        prayer: PrayerName.fajr,
      );
      expect(log.status, PrayerStatus.pending);
      expect(log.isRecorded, false);
    });

    test('congregation = +27 hasanat net iman +0.27', () {
      final log = PrayerLog.empty(
        userId: 'u1',
        date: testDate,
        prayer: PrayerName.fajr,
      ).copyWith(status: PrayerStatus.congregation, hasanat: 27);
      expect(log.netImanEffect, closeTo(0.27, 0.001));
    });

    test('missed with sayyiat = -4 iman', () {
      final log = PrayerLog.empty(
        userId: 'u1',
        date: testDate,
        prayer: PrayerName.dhuhr,
      ).copyWith(
        status: PrayerStatus.missed,
        sayyiat: 200,
        sayyiatRepented: false,
      );
      expect(log.netImanEffect, closeTo(-4.0, 0.001));
    });

    test('repented sayyiat = 0 impact', () {
      final log = PrayerLog.empty(
        userId: 'u1',
        date: testDate,
        prayer: PrayerName.dhuhr,
      ).copyWith(
        status: PrayerStatus.missed,
        sayyiat: 200,
        sayyiatRepented: true,
      );
      expect(log.netImanEffect, 0);
    });

    test('JSON roundtrip', () {
      final original = PrayerLog.empty(
        userId: 'u1',
        date: testDate,
        prayer: PrayerName.isha,
      ).copyWith(status: PrayerStatus.qada);
      final restored = PrayerLog.fromJson(original.toJson());
      expect(restored.prayer, original.prayer);
      expect(restored.status, original.status);
    });
  });
}