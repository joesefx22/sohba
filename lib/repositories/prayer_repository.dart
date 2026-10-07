import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/prayer_log.dart';
import '../services/prayer_engine.dart';

class PrayerRepository {
  final SupabaseClient _client;
  PrayerRepository(this._client);

  // ============================================
  // UPSERT via RPC (server-authoritative)
  // ============================================

  /// Records a prayer via the server-side RPC.
  ///
  /// The server:
  ///   - validates the phase against its own `now()`
  ///   - computes hasanat from status + phase
  ///   - stamps `recorded_at` with server time
  ///
  /// Returns a map with: id, prayer, status, hasanat, recorded_at, phase.
  Future<Map<String, dynamic>> recordPrayerRpc({
    required String userId,
    required PrayerName prayer,
    required PrayerStatus status,
    required DateTime logicalDate,
    required PrayerTimeline timeline,
    double bonusMultiplier = 1.0,
  }) async {
    final res = await _client.rpc(
      'record_prayer',
      params: {
        'p_user_id': userId,
        'p_prayer': prayer.name,
        'p_status': status.name,
        'p_date': _dateOnly(logicalDate),
        'p_adhan': timeline.adhan.toUtc().toIso8601String(),
        'p_congregation_open':
            timeline.congregationOpen.toUtc().toIso8601String(),
        'p_congregation_close':
            timeline.congregationClose.toUtc().toIso8601String(),
        'p_individual_close':
            timeline.individualClose.toUtc().toIso8601String(),
        'p_qada_close': timeline.qadaClose.toUtc().toIso8601String(),
        'p_bonus_multiplier': bonusMultiplier,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  // ============================================
  // READS
  // ============================================

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

  // ============================================
  // TAWBAH
  // ============================================

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

  // ============================================
  // SWEEP (server-side, user-scoped)
  // ============================================

  /// Sweeps pending prayers older than 1 day → marks them missed.
  /// Server enforces that `p_user_id` matches `auth.uid()`.
  Future<int> sweepMissedPrayers({required String userId}) async {
    final res = await _client.rpc(
      'sweep_missed_prayers_for_user',
      params: {'p_user_id': userId},
    );
    return (res as num).toInt();
  }

  // ============================================
  // REALTIME
  // ============================================

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
        .map((rows) => rows.map((r) => PrayerLog.fromJson(r)).toList());
  }

  // ============================================
  // HELPERS
  // ============================================

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}