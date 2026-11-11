import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit_streak.dart';

class HabitStreakRepository {
  final SupabaseClient _client;
  HabitStreakRepository(this._client);

  Future<List<HabitStreak>> getForUser(String userId) async {
    final res = await _client
        .from('habit_streaks')
        .select()
        .eq('user_id', userId)
        .order('current_streak', ascending: false);
    return (res as List)
        .map((e) => HabitStreak.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> bump({
    required String userId,
    required String habitKey,
    DateTime? date,
  }) async {
    await _client.rpc('bump_habit_streak', params: {
      'p_user_id': userId,
      'p_habit_key': habitKey,
      'p_date': date != null
          ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
          : null,
    });
  }

  Future<int> sweep(String userId) async {
    final res = await _client.rpc(
      'sweep_habit_streaks',
      params: {'p_user_id': userId},
    );
    return (res as num).toInt();
  }
}