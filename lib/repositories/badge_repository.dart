import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge.dart';

class BadgeRepository {
  final SupabaseClient _client;
  BadgeRepository(this._client);

  Future<List<Badge>> getAllBadges() async {
    final res = await _client.from('badges').select().order('tier');
    return (res as List)
        .map((e) => Badge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserBadge>> getUserBadges(String userId) async {
    final res = await _client
        .from('user_badges')
        .select()
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);
    return (res as List)
        .map((e) => UserBadge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> unlockBadge({
    required String userId,
    required String badgeId,
  }) async {
    await _client.from('user_badges').upsert({
      'user_id': userId,
      'badge_id': badgeId,
      'unlocked_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,badge_id');
  }
}