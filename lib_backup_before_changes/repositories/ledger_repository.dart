import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ledger_entry.dart';

class LedgerRepository {
  final SupabaseClient _client;
  LedgerRepository(this._client);

  Future<List<LedgerEntry>> getEntries({
    required String userId,
    int limit = 100,
    int offset = 0,
  }) async {
    final res = await _client.rpc('get_ledger', params: {
      'p_user_id': userId,
      'p_limit': limit,
      'p_offset': offset,
    });
    return (res as List)
        .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getSummary(String userId) async {
    final res = await _client.rpc(
      'ledger_summary',
      params: {'p_user_id': userId},
    );
    return Map<String, dynamic>.from(res as Map);
  }
}