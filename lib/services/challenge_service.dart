import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge.dart';

class ChallengeService {
  ChallengeService._();

  static Future<List<Challenge>> forGroup(String groupId) async {
    final res = await Supabase.instance.client
        .from('challenges')
        .select()
        .eq('group_id', groupId)
        .gte('ends_at', DateTime.now().toIso8601String().split('T').first)
        .order('starts_at');
    return (res as List)
        .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Challenge> create({
    required String groupId,
    required String userId,
    required String title,
    required String type,
    required int targetDays,
  }) async {
    final now = DateTime.now();
    final ends = now.add(Duration(days: targetDays));
    final res = await Supabase.instance.client
        .from('challenges')
        .insert({
          'group_id': groupId,
          'created_by': userId,
          'title': title,
          'type': type,
          'target_days': targetDays,
          'starts_at': now.toIso8601String().split('T').first,
          'ends_at': ends.toIso8601String().split('T').first,
        })
        .select()
        .single();
    return Challenge.fromJson(res);
  }

  static Future<void> join({
    required String challengeId,
    required String userId,
  }) async {
    await Supabase.instance.client.from('challenge_participants').upsert({
      'challenge_id': challengeId,
      'user_id': userId,
      'progress': 0,
    });
  }

  static Future<List<ChallengeParticipant>> participants(
      String challengeId) async {
    final res = await Supabase.instance.client
        .from('challenge_participants')
        .select()
        .eq('challenge_id', challengeId);
    return (res as List)
        .map((e) => ChallengeParticipant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Called after a prayer is recorded to advance any active challenges
  /// the user participates in.
  ///
  /// NOTE: race-condition-safe increment is delegated to a future
  /// `advance_challenge` RPC. For MVP, this is best-effort.
  static Future<void> advanceOnPrayer({
    required String userId,
    required String prayer,
  }) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final res = await Supabase.instance.client
        .from('challenge_participants')
        .select('challenge_id, challenges!inner(type, ends_at, target_days)')
        .eq('user_id', userId)
        .eq('completed', false);

    for (final row in (res as List)) {
      final ch = row['challenges'] as Map<String, dynamic>;
      final type = ch['type'] as String;
      final endsAt = ch['ends_at'] as String;
      if (endsAt.compareTo(todayStr) < 0) continue;

      bool qualifies = false;
      if (type == 'fajr_streak' && prayer == 'fajr') qualifies = true;
      if (type == 'all_prayers') qualifies = true;
      if (!qualifies) continue;

      final p = await Supabase.instance.client
          .from('challenge_participants')
          .select('progress')
          .eq('challenge_id', row['challenge_id'])
          .eq('user_id', userId)
          .single();
      final newProgress = (p['progress'] as int) + 1;
      final target = ch['target_days'] as int;
      await Supabase.instance.client
          .from('challenge_participants')
          .update({
            'progress': newProgress,
            'completed': newProgress >= target,
          })
          .eq('challenge_id', row['challenge_id'])
          .eq('user_id', userId);
    }
  }
}