import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/prayer_log.dart';
import '../repositories/prayer_repository.dart';
import '../services/streak_service.dart';

class StreakMilestone {
  final int value;
  final bool justReached;
  const StreakMilestone(this.value, {this.justReached = false});
}

class StreakProvider extends ChangeNotifier {
  late final PrayerRepository _prayerRepo;

  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActiveDate;
  List<DateTime> _activityDates = [];
  bool _loading = false;

  StreakProvider() {
    _prayerRepo = PrayerRepository(Supabase.instance.client);
  }

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastActiveDate => _lastActiveDate;
  List<DateTime> get activityDates => List.unmodifiable(_activityDates);
  bool get loading => _loading;

  /// Bonus multiplier applied to hasanat.
  double get bonusMultiplier =>
      StreakService.streakBonusMultiplier(_currentStreak);

  int get bonusPercent => StreakService.streakBonusPercent(_currentStreak);

  int? get nextMilestone {
    for (final m in AppConfig.streakMilestones) {
      if (_currentStreak < m) return m;
    }
    return null;
  }

  double get progressToNextMilestone {
    final next = nextMilestone;
    if (next == null) return 1.0;
    int previous = 0;
    for (final m in AppConfig.streakMilestones) {
      if (m >= next) break;
      if (_currentStreak >= m) previous = m;
    }
    final range = next - previous;
    if (range <= 0) return 1.0;
    return (_currentStreak - previous) / range;
  }

  // --- Loading ------------------------------------------------------------

  Future<void> loadForUser(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      // Load last 60 days of prayer logs
      final from = DateTime.now().subtract(const Duration(days: 60));
      final logs = await _prayerRepo.getLogsInRange(
        userId: userId,
        from: from,
        to: DateTime.now(),
      );

      _activityDates = _deriveActivityDates(logs);
      _recalculate();
      _lastActiveDate =
          _activityDates.isNotEmpty ? _activityDates.last : null;
    } catch (e) {
      debugPrint('StreakProvider.loadForUser: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- Core ---------------------------------------------------------------

  /// Called after a successful prayer record.
  /// Returns a milestone value if one was just reached.
  Future<int?> recordActivity({required String userId}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If already active today, no change.
    if (_activityDates.isNotEmpty && _activityDates.last == today) {
      return null;
    }

    final oldStreak = _currentStreak;

    // Append today and recalculate
    _activityDates = [..._activityDates, today];
    _recalculate();
    _lastActiveDate = now;

    // Persist to profile
    try {
      await Supabase.instance.client.from('profiles').update({
        'current_streak': _currentStreak,
        'longest_streak': _longestStreak,
        'last_active_date': today.toIso8601String().split('T').first,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('StreakProvider persistence: $e');
    }

    notifyListeners();

    // Check milestone crossing
    for (final m in AppConfig.streakMilestones) {
      if (oldStreak < m && _currentStreak >= m) {
        return m;
      }
    }
    return null;
  }

  /// Detect if the streak was broken while user was away.
  /// Returns the lost streak value if it was lost, null otherwise.
  Future<int?> checkAndHandleLoss({required String userId}) async {
    if (_activityDates.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = _activityDates.last;
    final daysDiff = today.difference(last).inDays;

    if (daysDiff >= 2 && _currentStreak > 0) {
      final lost = _currentStreak;
      _currentStreak = 0;
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'current_streak': 0}).eq('id', userId);
      } catch (_) {}
      notifyListeners();
      return lost;
    }
    return null;
  }

  // --- Helpers ------------------------------------------------------------

  List<DateTime> _deriveActivityDates(List<PrayerLog> logs) {
    final set = <DateTime>{};
    for (final log in logs) {
      // Consider a day active if ANY prayer was prayed (not missed)
      if (log.status == PrayerStatus.congregation ||
          log.status == PrayerStatus.individual ||
          log.status == PrayerStatus.qada) {
        set.add(DateTime(log.date.year, log.date.month, log.date.day));
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  void _recalculate() {
    // Deduplicate + sort
    final normalized = _activityDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    if (normalized.isEmpty) {
      _currentStreak = 0;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Streak must include today or yesterday
    if (normalized.last != today && normalized.last != yesterday) {
      _currentStreak = 0;
      return;
    }

    int streak = 1;
    DateTime expected = normalized.last;
    for (int i = normalized.length - 2; i >= 0; i--) {
      final prev = expected.subtract(const Duration(days: 1));
      if (normalized[i] == prev) {
        streak++;
        expected = prev;
      } else {
        break;
      }
    }

    _currentStreak = streak;
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
  }
}