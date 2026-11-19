import '../models/prayer_log.dart';

/// Evaluates compound badge requirements against recent prayer + qiyam data.
///
/// FIX: removes the previous `witr` / `shaf` pass-through that allowed
/// unlocking `qiyam_full_night` without proving those prayers happened.
class CompoundBadgeEngine {
  CompoundBadgeEngine._();

  /// Evaluate [requirements] against a day's activity.
  ///
  /// [recentLogs] — last N days of prayer logs.
  /// [qiyamLogs] — last N days of qiyam_logs rows (mapped by YYYY-MM-DD).
  static bool evaluate({
    required Map<String, dynamic> requirements,
    required List<PrayerLog> recentLogs,
    Map<String, Map<String, dynamic>> qiyamLogsByDate = const {},
    int daysBack = 7,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: daysBack));
    final recent = recentLogs.where((l) => l.date.isAfter(cutoff)).toList();

    // min_sunnah_rakat: requires sunnah rakats logged that day.
    final minSunnah = (requirements['min_sunnah_rakat'] as num?)?.toInt();
    if (minSunnah != null) {
      return _anyDaySunnahAtLeast(qiyamLogsByDate, minSunnah, cutoff);
    }

    // has_duha: requires duha prayer explicitly logged.
    if (requirements['has_duha'] == true) {
      return _anyDayHasDuha(qiyamLogsByDate, cutoff);
    }

    // all_of: all flags must be true on the SAME day.
    final allOf = (requirements['all_of'] as List?)?.cast<String>();
    if (allOf != null && allOf.isNotEmpty) {
      return _anyDayHasAll(recent, qiyamLogsByDate, allOf, cutoff);
    }

    return false;
  }

  // ============================================
  // ALL_OF evaluation
  // ============================================

  static bool _anyDayHasAll(
    List<PrayerLog> logs,
    Map<String, Map<String, dynamic>> qiyam,
    List<String> flags,
    DateTime cutoff,
  ) {
    // Build map: date-key -> Set of "facts" for that day.
    final byDay = <String, Set<String>>{};

    for (final l in logs) {
      final key = _key(l.date);
      final set = byDay.putIfAbsent(key, () => {});
      if (l.status == PrayerStatus.congregation) {
        set.add('${l.prayer.name}_congregation');
      }
      if (l.status == PrayerStatus.individual) {
        set.add('${l.prayer.name}_individual');
      }
    }

    for (final entry in qiyam.entries) {
      final set = byDay.putIfAbsent(entry.key, () => {});
      if (entry.value['witr'] == true) set.add('witr');
      if (entry.value['shaf'] == true) set.add('shaf');
      if (entry.value['duha'] == true) set.add('duha');
    }

    for (final day in byDay.values) {
      final ok = flags.every(day.contains);
      if (ok) return true;
    }
    return false;
  }

  // ============================================
  // min_sunnah_rakat
  // ============================================

  static bool _anyDaySunnahAtLeast(
    Map<String, Map<String, dynamic>> qiyam,
    int target,
    DateTime cutoff,
  ) {
    for (final entry in qiyam.entries) {
      final date = _parseKey(entry.key);
      if (date == null || date.isBefore(cutoff)) continue;
      final rakat = (entry.value['sunnah_rakat'] as num?)?.toInt() ?? 0;
      if (rakat >= target) return true;
    }
    return false;
  }

  // ============================================
  // has_duha
  // ============================================

  static bool _anyDayHasDuha(
    Map<String, Map<String, dynamic>> qiyam,
    DateTime cutoff,
  ) {
    for (final entry in qiyam.entries) {
      final date = _parseKey(entry.key);
      if (date == null || date.isBefore(cutoff)) continue;
      if (entry.value['duha'] == true) return true;
    }
    return false;
  }

  // ============================================
  // helpers
  // ============================================

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }
}