import '../config/app_config.dart';

/// Streak calculation + bonus multipliers.
/// Milestones live in [AppConfig.streakMilestones] (single source of truth).
class StreakService {
  StreakService._();

  static List<int> get milestones => AppConfig.streakMilestones;

  static int calculateStreak(List<DateTime> activityDates) {
    if (activityDates.isEmpty) return 0;

    final normalizedDates = activityDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final mostRecent = normalizedDates.first;
    if (mostRecent != today && mostRecent != yesterday) return 0;

    int streak = 0;
    DateTime expectedDate = mostRecent;

    for (final date in normalizedDates) {
      if (date == expectedDate) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(expectedDate)) {
        break;
      }
    }

    return streak;
  }

  static double streakBonusMultiplier(int streak) {
    if (streak >= 100) return 1.5;
    if (streak >= 30) return 1.25;
    if (streak >= 14) return 1.15;
    if (streak >= 7) return 1.1;
    return 1.0;
  }

  static int streakBonusPercent(int streak) {
    if (streak >= 100) return 50;
    if (streak >= 30) return 25;
    if (streak >= 14) return 15;
    if (streak >= 7) return 10;
    return 0;
  }

  static int? checkStreakMilestone(int oldStreak, int newStreak) {
    for (final milestone in milestones) {
      if (oldStreak < milestone && newStreak >= milestone) return milestone;
    }
    return null;
  }

  static List<int> checkAllMilestones(int oldStreak, int newStreak) {
    final reached = <int>[];
    for (final milestone in milestones) {
      if (oldStreak < milestone && newStreak >= milestone) reached.add(milestone);
    }
    return reached;
  }

  static bool isStreakActive(DateTime? lastActiveDate) {
    if (lastActiveDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastActive = DateTime(
      lastActiveDate.year,
      lastActiveDate.month,
      lastActiveDate.day,
    );
    return lastActive == today || lastActive == yesterday;
  }

  static bool hasActivityToday(DateTime? lastActiveDate) {
    if (lastActiveDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = DateTime(
      lastActiveDate.year,
      lastActiveDate.month,
      lastActiveDate.day,
    );
    return lastActive == today;
  }

  static int? nextMilestone(int currentStreak) {
    for (final milestone in milestones) {
      if (currentStreak < milestone) return milestone;
    }
    return null;
  }

  static double progressToNextMilestone(int currentStreak) {
    final next = nextMilestone(currentStreak);
    if (next == null) return 1.0;
    int previous = 0;
    for (final milestone in milestones) {
      if (milestone >= next) break;
      if (currentStreak >= milestone) previous = milestone;
    }
    final range = next - previous;
    return (currentStreak - previous) / range;
  }
}