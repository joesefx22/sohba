import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prayer_log.dart';

/// Repository for prayer logs — the core game data.
class PrayerRepository {
  final SupabaseClient _client;
  PrayerRepository(this._client);

  /// Upsert a prayer log (idempotent per user/date/prayer).
  Future<void> upsertLog(PrayerLog log) async {
    await _client.from('prayer_logs').upsert(log.toJson());
  }

  /// Get all prayer logs for a specific date.
  Future<List<PrayerLog>> getLogsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final dateStr = _dateOnly(date);
    final res = await _client
        .from('prayer_logs')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr);

    return (res as List)
        .map((e) => PrayerLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get logs in a range (for calendar / stats).
  Future<List<PrayerLog>> getLogsInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _client
        .from('prayer_logs')
        .select()
        .eq('user_id', userId)
        .gte('date', _dateOnly(from))
        .lte('date', _dateOnly(to))
        .order('date', ascending: false);

    return (res as List)
        .map((e) => PrayerLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mark a missed prayer as repented (tawbah).
  Future<void> markRepented({
    required String userId,
    required DateTime date,
    required PrayerName prayer,
  }) async {
    await _client
        .from('prayer_logs')
        .update({
          'sayyiat_repented': true,
          'repented_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('date', _dateOnly(date))
        .eq('prayer', prayer.name);
  }

  /// Realtime stream for today's logs.
  Stream<List<PrayerLog>> streamLogsForDate({
    required String userId,
    required DateTime date,
  }) {
    final dateStr = _dateOnly(date);
    return _client
        .from('prayer_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('date', dateStr)
        .map((rows) => rows
            .map((r) => PrayerLog.fromJson(r))
            .toList());
  }

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}