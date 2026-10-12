import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for qiyam/sunnah daily logs.
class QiyamRepository {
  final SupabaseClient _client;
  QiyamRepository(this._client);

  /// Upsert today's qiyam log.
  Future<void> log({
    required String userId,
    DateTime? date,
    bool? witr,
    bool? shaf,
    bool? duha,
    int? sunnahRakat,
    int? tahajjudRakat,
  }) async {
    final d = date ?? DateTime.now();
    await _client.rpc('log_qiyam', params: {
      'p_user_id': userId,
      'p_date': _dateOnly(d),
      'p_witr': witr,
      'p_shaf': shaf,
      'p_duha': duha,
      'p_sunnah_rakat': sunnahRakat,
      'p_tahajjud_rakat': tahajjudRakat,
    });
  }

  /// Fetch last [days] days of qiyam logs, keyed by "YYYY-MM-DD".
  Future<Map<String, Map<String, dynamic>>> getRange({
    required String userId,
    int days = 30,
  }) async {
    final res = await _client.rpc('get_qiyam_range', params: {
      'p_user_id': userId,
      'p_days': days,
    });

    final map = <String, Map<String, dynamic>>{};
    for (final raw in (res as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      final date = row['date'] as String; // already YYYY-MM-DD
      map[date] = {
        'witr': row['prayed_witr'] == true,
        'shaf': row['prayed_shaf'] == true,
        'duha': row['prayed_duha'] == true,
        'sunnah_rakat': row['sunnah_rakat'] ?? 0,
        'tahajjud_rakat': row['tahajjud_rakat'] ?? 0,
      };
    }
    return map;
  }

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}