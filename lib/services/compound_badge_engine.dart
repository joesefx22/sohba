import '../models/prayer_log.dart';

/// Evaluates compound badge requirements against recent prayer data.
class CompoundBadgeEngine {
  CompoundBadgeEngine._();

  /// Returns true if requirements are satisfied by [daysBack] days of logs.
  static bool evaluate({
    required Map<String, dynamic> requirements,
    required List<PrayerLog> recentLogs,
    int daysBack = 7,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: daysBack));
    final recent = recentLogs.where((l) => l.date.isAfter(cutoff)).toList();

    // min_sunnah_rakat (approximate: count of individual+congregation on sunnah-like markers)
    if (requirements['min_sunnah_rakat'] != null) {
      // Not fully modeled in DB yet — skip silently.
      return false;
    }

    // has_duha — needs a prayer marker 'duha' not implemented. Return false.
    if (requirements['has_duha'] == true) return false;

    // all_of: list of flags that must be present on the SAME day
    final allOf = (requirements['all_of'] as List?)?.cast<String>();
    if (allOf != null && allOf.isNotEmpty) {
      return _anyDayHasAll(recent, allOf);
    }

    return false;
  }

  static bool _anyDayHasAll(List<PrayerLog> logs, List<String> flags) {
    final byDay = <String, Set<String>>{};
    for (final l in logs) {
      final key = '${l.date.year}-${l.date.month}-${l.date.day}';
      final set = byDay.putIfAbsent(key, () => {});
      if (l.status == PrayerStatus.congregation) {
        set.add('${l.prayer.name}_congregation');
      }
      if (l.status == PrayerStatus.individual) {
        set.add('${l.prayer.name}_individual');
      }
    }

    for (final day in byDay.values) {
      final ok = flags.every((f) {
        if (f == 'witr' || f == 'shaf') return true; // not modeled — pass-through
        return day.contains(f);
      });
      if (ok) return true;
    }
    return false;
  }
}