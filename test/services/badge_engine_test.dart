import 'package:flutter_test/flutter_test.dart';

import 'package:sohba/models/athkar.dart';
import 'package:sohba/models/prayer_log.dart';
import 'package:sohba/services/badge_engine.dart';

void main() {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  PrayerLog log({
    required int daysAgo,
    required PrayerName prayer,
    required PrayerStatus status,
    int hasanat = 0,
  }) {
    final d = todayDate.subtract(Duration(days: daysAgo));
    return PrayerLog(
      id: '${daysAgo}_${prayer.name}',
      userId: 'u1',
      date: d,
      prayer: prayer,
      status: status,
      hasanat: hasanat,
    );
  }

  AthkarItem item(String id) => AthkarItem(
        id: id,
        categoryId: 'morning',
        displayOrder: 0,
        arabic: 'ذكر',
      );

  group('BadgeEngine — Fajr congregation streak', () {
    test('counts consecutive days with fajr congregation', () {
      final logs = [
        log(daysAgo: 0, prayer: PrayerName.fajr, status: PrayerStatus.congregation),
        log(daysAgo: 1, prayer: PrayerName.fajr, status: PrayerStatus.congregation),
        log(daysAgo: 2, prayer: PrayerName.fajr, status: PrayerStatus.congregation),
      ];
      final ctx = BadgeEngine.compute(
        prayerLogs: logs,
        athkarItemsToday: [],
        athkarProgressToday: {},
      );
      expect(ctx.fajrCongregationStreak, 3);
    });

    test('breaks at first non-congregation day', () {
      final logs = [
        log(daysAgo: 0, prayer: PrayerName.fajr, status: PrayerStatus.congregation),
        log(daysAgo: 1, prayer: PrayerName.fajr, status: PrayerStatus.individual),
        log(daysAgo: 2, prayer: PrayerName.fajr, status: PrayerStatus.congregation),
      ];
      final ctx = BadgeEngine.compute(
        prayerLogs: logs,
        athkarItemsToday: [],
        athkarProgressToday: {},
      );
      expect(ctx.fajrCongregationStreak, 1);
    });

    test('zero when today and yesterday missed', () {
      final logs = [
        log(daysAgo: 2, prayer: PrayerName.fajr, status: PrayerStatus.congregation),
        log(daysAgo: 3, prayer: PrayerName.fajr, status: PrayerStatus.congregation),
      ];
      final ctx = BadgeEngine.compute(
        prayerLogs: logs,
        athkarItemsToday: [],
        athkarProgressToday: {},
      );
      expect(ctx.fajrCongregationStreak, 0);
    });
  });

  group('BadgeEngine — All prayers streak', () {
    test('counts day only if all 5 prayers recorded', () {
      final logs = <PrayerLog>[];
      for (final p in PrayerName.values) {
        logs.add(log(
          daysAgo: 0,
          prayer: p,
          status: PrayerStatus.congregation,
        ));
      }
      final ctx = BadgeEngine.compute(
        prayerLogs: logs,
        athkarItemsToday: [],
        athkarProgressToday: {},
      );
      expect(ctx.allPrayersOnTimeDays, 1);
    });

    test('does not count if one prayer missing', () {
      final logs = <PrayerLog>[];
      // skip isha
      for (final p in PrayerName.values.where((p) => p != PrayerName.isha)) {
        logs.add(log(daysAgo: 0, prayer: p, status: PrayerStatus.congregation));
      }
      final ctx = BadgeEngine.compute(
        prayerLogs: logs,
        athkarItemsToday: [],
        athkarProgressToday: {},
      );
      expect(ctx.allPrayersOnTimeDays, 0);
    });

    test('does not count if one is missed', () {
      final logs = <PrayerLog>[];
      for (final p in PrayerName.values) {
        logs.add(log(
          daysAgo: 0,
          prayer: p,
          status: p == PrayerName.asr
              ? PrayerStatus.missed
              : PrayerStatus.congregation,
        ));
      }
      final ctx = BadgeEngine.compute(
        prayerLogs: logs,
        athkarItemsToday: [],
        athkarProgressToday: {},
      );
      expect(ctx.allPrayersOnTimeDays, 0);
    });
  });

  group('BadgeEngine — Overall streak', () {
    test('counts any recorded prayer per day', () {
      final logs = [
        log(daysAgo: 0, prayer: PrayerName.fajr, status: PrayerStatus.individual),
        log(daysAgo: 1, prayer: PrayerName.dhuhr, status: PrayerStatus.congregation),
        log(daysAgo: 2, prayer: PrayerName.isha, status: PrayerStatus.qada),
      ];
      final ctx = BadgeEngine.compute(
        prayerLogs: logs,
        athkarItemsToday: [],
        athkarProgressToday: {},
      );
      expect(ctx.overallStreak, 3);
    });
  });

  group('BadgeEngine — Athkar streak', () {
    test('1 when all today items completed', () {
      final items = [item('a'), item('b')];
      final progress = {'a': true, 'b': true};
      final ctx = BadgeEngine.compute(
        prayerLogs: [],
        athkarItemsToday: items,
        athkarProgressToday: progress,
      );
      expect(ctx.athkarStreak, 1);
    });

    test('0 when some items incomplete', () {
      final items = [item('a'), item('b')];
      final progress = {'a': true, 'b': false};
      final ctx = BadgeEngine.compute(
        prayerLogs: [],
        athkarItemsToday: items,
        athkarProgressToday: progress,
      );
      expect(ctx.athkarStreak, 0);
    });

    test('0 when no items', () {
      final ctx = BadgeEngine.compute(
        prayerLogs: [],
        athkarItemsToday: [],
        athkarProgressToday: {},
      );
      expect(ctx.athkarStreak, 0);
    });
  });

  group('BadgeEngine — Total hasanat', () {
    test('sums hasanat across logs', () {
      final logs = [
        log(daysAgo: 0, prayer: PrayerName.fajr,
            status: PrayerStatus.congregation, hasanat: 27),
        log(daysAgo: 0, prayer: PrayerName.dhuhr,
            status: PrayerStatus.individual, hasanat: 1),
        log(daysAgo: 1, prayer: PrayerName.asr,
            status: PrayerStatus.congregation, hasanat: 27),
      ];
      final ctx = BadgeEngine.compute(
        prayerLogs: logs,
        athkarItemsToday: [],
        athkarProgressToday: {},
      );
      expect(ctx.totalHasanat, 55);
    });
  });
}