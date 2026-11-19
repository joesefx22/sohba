import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge.dart';

class ChallengeService {
  ChallengeService._();

  static Future<List<Challenge>> forGroup(String groupId) async {
    final res = await Supabase.instance.client
        .from('challenges')
        .select()
        .eq('group_id', groupId)
        .gte('ends_at', _todayStr())
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
          'starts_at': _todayStr(),
          'ends_at': _dateStr(ends),
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

  /// Server-authoritative, idempotent per day.
  ///
  /// Safe to call multiple times — the server tracks a daily log
  /// so each qualifying day counts exactly once.
  static Future<int> advanceOnPrayer({
    required String userId,
    required String prayer,
  }) async {
    try {
      final res = await Supabase.instance.client.rpc(
        'advance_challenge',
        params: {
          'p_user_id': userId,
          'p_prayer': prayer,
        },
      );
      return (res as num).toInt();
    } catch (e) {
      // Never break prayer recording because of a challenge failure.
      // ignore: avoid_print
      print('ChallengeService.advanceOnPrayer: $e');
      return 0;
    }
  }

  static String _todayStr() => _dateStr(DateTime.now());

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}