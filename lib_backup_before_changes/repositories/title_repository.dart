import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/title.dart';

class TitleRepository {
  final SupabaseClient _client;
  TitleRepository(this._client);

  Future<List<Title>> getAllTitles() async {
    final res = await _client.from('titles').select().order('display_order');
    return (res as List)
        .map((e) => Title.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserTitle>> getUserTitles(String userId) async {
    final res = await _client
        .from('user_titles')
        .select()
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);
    return (res as List)
        .map((e) => UserTitle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> unlockTitle({
    required String userId,
    required String titleId,
  }) async {
    await _client.rpc('unlock_title', params: {
      'p_user_id': userId,
      'p_title_id': titleId,
    });
  }

  Future<void> setActiveTitle({
    required String userId,
    required String titleId,
  }) async {
    await _client.rpc('set_active_title', params: {
      'p_user_id': userId,
      'p_title_id': titleId,
    });
  }
}