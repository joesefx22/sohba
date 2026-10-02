import 'package:flutter_test/flutter_test.dart';
import 'package:sohba/services/streak_service.dart';

void main() {
  group('StreakService.calculateStreak', () {
    test('0 for empty', () {
      expect(StreakService.calculateStreak([]), 0);
    });

    test('1 for today only', () {
      final today = DateTime.now();
      expect(StreakService.calculateStreak([today]), 1);
    });

    test('counts consecutive days', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dates = [
        today,
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      ];
      expect(StreakService.calculateStreak(dates), 3);
    });

    test('breaks at gap', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dates = [
        today,
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 3)),
      ];
      expect(StreakService.calculateStreak(dates), 2);
    });

    test('0 if last activity 2+ days ago', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      expect(StreakService.calculateStreak([twoDaysAgo]), 0);
    });
  });

  group('StreakService.streakBonusMultiplier', () {
    test('1.0 for < 7', () {
      expect(StreakService.streakBonusMultiplier(6), 1.0);
    });
    test('1.1 for 7-13', () {
      expect(StreakService.streakBonusMultiplier(7), 1.1);
      expect(StreakService.streakBonusMultiplier(13), 1.1);
    });
    test('1.15 for 14-29', () {
      expect(StreakService.streakBonusMultiplier(14), 1.15);
    });
    test('1.25 for 30-99', () {
      expect(StreakService.streakBonusMultiplier(30), 1.25);
    });
    test('1.5 for 100+', () {
      expect(StreakService.streakBonusMultiplier(100), 1.5);
    });
  });

  group('StreakService.checkStreakMilestone', () {
    test('crosses 7', () {
      expect(StreakService.checkStreakMilestone(6, 7), 7);
    });
    test('crosses 30', () {
      expect(StreakService.checkStreakMilestone(29, 30), 30);
    });
    test('no milestone', () {
      expect(StreakService.checkStreakMilestone(5, 6), isNull);
    });
  });

  group('StreakService.isStreakActive', () {
    test('today = active', () {
      expect(StreakService.isStreakActive(DateTime.now()), true);
    });
    test('yesterday = active', () {
      final y = DateTime.now().subtract(const Duration(days: 1));
      expect(StreakService.isStreakActive(y), true);
    });
    test('2 days ago = inactive', () {
      final d = DateTime.now().subtract(const Duration(days: 2));
      expect(StreakService.isStreakActive(d), false);
    });
    test('null = inactive', () {
      expect(StreakService.isStreakActive(null), false);
    });
  });
}