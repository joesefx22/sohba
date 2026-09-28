/// Service for streak calculations and bonus multipliers
///
/// Streak Logic:
/// - Activity today OR yesterday = streak still active
/// - Count consecutive days backwards from today
///
/// Bonus Multipliers:
/// - 0-6 days: 1.0x (no bonus)
/// - 7-13 days: 1.1x (+10%)
/// - 14-29 days: 1.15x (+15%)
/// - 30-99 days: 1.25x (+25%)
/// - 100+ days: 1.5x (+50%)
///
/// Milestones: 7, 14, 30, 60, 100, 365
class StreakService {
  StreakService._();

  /// Milestone streak values that trigger special rewards/animations
  static const List<int> milestones = [7, 14, 30, 60, 100, 365];

  /// Calculate current streak from a list of activity dates
  ///
  /// Returns the number of consecutive days with activity,
  /// counting backwards from today or yesterday.
  static int calculateStreak(List<DateTime> activityDates) {
    if (activityDates.isEmpty) return 0;

    // Normalize dates to midnight and remove duplicates
    final normalizedDates = activityDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending (newest first)

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if streak is still active (activity today or yesterday)
    final mostRecent = normalizedDates.first;
    if (mostRecent != today && mostRecent != yesterday) {
      return 0; // Streak broken
    }

    // Count consecutive days
    int streak = 0;
    DateTime expectedDate = mostRecent;

    for (final date in normalizedDates) {
      if (date == expectedDate) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(expectedDate)) {
        // Gap found, streak ends here
        break;
      }
    }

    return streak;
  }

  /// Get bonus multiplier for points based on streak length
  ///
  /// Returns a multiplier (1.0 = no bonus, 1.5 = +50%)
  static double streakBonusMultiplier(int streak) {
    if (streak >= 100) return 1.5; // +50%
    if (streak >= 30) return 1.25; // +25%
    if (streak >= 14) return 1.15; // +15%
    if (streak >= 7) return 1.1; // +10%
    return 1.0; // No bonus
  }

  /// Get bonus percentage as integer for display
  ///
  /// Returns 0, 10, 15, 25, or 50
  static int streakBonusPercent(int streak) {
    if (streak >= 100) return 50;
    if (streak >= 30) return 25;
    if (streak >= 14) return 15;
    if (streak >= 7) return 10;
    return 0;
  }

  /// Check if a milestone was reached between old and new streak
  ///
  /// Returns the milestone value if reached, null otherwise
  static int? checkStreakMilestone(int oldStreak, int newStreak) {
    for (final milestone in milestones) {
      if (oldStreak < milestone && newStreak >= milestone) {
        return milestone;
      }
    }
    return null;
  }

  /// Check if all milestones reached between old and new streak
  ///
  /// Returns list of milestone values reached (can be multiple)
  static List<int> checkAllMilestones(int oldStreak, int newStreak) {
    final reached = <int>[];
    for (final milestone in milestones) {
      if (oldStreak < milestone && newStreak >= milestone) {
        reached.add(milestone);
      }
    }
    return reached;
  }

  /// Check if streak is still active based on last activity date
  ///
  /// Streak is active if last activity was today or yesterday
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

  /// Check if activity was already recorded today
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

  /// Get days until streak breaks (0 = breaks today, 1 = breaks tomorrow)
  static int daysUntilStreakBreaks(DateTime? lastActiveDate) {
    if (lastActiveDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = DateTime(
      lastActiveDate.year,
      lastActiveDate.month,
      lastActiveDate.day,
    );

    if (lastActive == today) {
      return 2; // Active today, breaks in 2 days if no activity
    } else if (lastActive == today.subtract(const Duration(days: 1))) {
      return 1; // Active yesterday, breaks tomorrow if no activity
    }
    return 0; // Already broken
  }

  /// Get the next milestone to reach
  static int? nextMilestone(int currentStreak) {
    for (final milestone in milestones) {
      if (currentStreak < milestone) {
        return milestone;
      }
    }
    return null; // All milestones reached
  }

  /// Get progress to next milestone as percentage (0.0 - 1.0)
  static double progressToNextMilestone(int currentStreak) {
    final next = nextMilestone(currentStreak);
    if (next == null) return 1.0;

    // Find previous milestone
    int previous = 0;
    for (final milestone in milestones) {
      if (milestone >= next) break;
      if (currentStreak >= milestone) {
        previous = milestone;
      }
    }

    final range = next - previous;
    final progress = currentStreak - previous;
    return progress / range;
  }

  /// Get a motivational message based on streak status
  static String streakMessage(int streak, {bool isActive = true}) {
    if (!isActive) {
      return 'Starte heute eine neue Serie!';
    }

    if (streak == 0) {
      return 'Beginne deine Serie!';
    } else if (streak == 1) {
      return 'Guter Start! Mach morgen weiter!';
    } else if (streak < 7) {
      return 'Weiter so! ${7 - streak} Tage bis zum Bonus!';
    } else if (streak < 14) {
      return 'Tolle Serie! +10% Bonus aktiv!';
    } else if (streak < 30) {
      return 'Fantastisch! +15% Bonus aktiv!';
    } else if (streak < 100) {
      return 'Unglaublich! +25% Bonus aktiv!';
    } else {
      return 'Legendär! +50% Bonus aktiv!';
    }
  }
}
