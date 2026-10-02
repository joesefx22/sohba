import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/athkar.dart';

class AthkarRepository {
  final SupabaseClient _client;
  AthkarRepository(this._client);

  Future<List<UserAthkarProgress>> getProgress({
    required String userId,
    required DateTime date,
  }) async {
    final dateStr = _dateOnly(date);
    final res = await _client
        .from('user_athkar_logs')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr);

    return (res as List)
        .map((e) => UserAthkarProgress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertProgress({
    required String userId,
    required String athkarItemId,
    required DateTime date,
    required int count,
    required bool completed,
  }) async {
    final dateStr = _dateOnly(date);
    await _client.from('user_athkar_logs').upsert({
      'user_id': userId,
      'athkar_item_id': athkarItemId,
      'date': dateStr,
      'count': count,
      'completed': completed,
      'completed_at': completed ? DateTime.now().toIso8601String() : null,
    }, onConflict: 'user_id,athkar_item_id,date');
  }

  Future<int> countCompletedForDate({
    required String userId,
    required DateTime date,
  }) async {
    final dateStr = _dateOnly(date);
    final res = await _client
        .from('user_athkar_logs')
        .select('id')
        .eq('user_id', userId)
        .eq('date', dateStr)
        .eq('completed', true);
    return (res as List).length;
  }

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}