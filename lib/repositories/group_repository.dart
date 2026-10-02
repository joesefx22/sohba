import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for group CRUD and membership.
class GroupRepository {
  final SupabaseClient _client;
  GroupRepository(this._client);

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _generateInviteCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => _alphabet[rng.nextInt(_alphabet.length)]).join();
  }

  /// Create a new group. Creator becomes admin automatically.
  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String userId,
    String? description,
  }) async {
    // Check name uniqueness (case-insensitive)
    final existing = await _client
        .from('groups')
        .select('id')
        .ilike('name', name.trim())
        .maybeSingle();
    if (existing != null) {
      throw Exception('اسم المجموعة مستخدم بالفعل');
    }

    // Ensure code is unique (retry up to 5 times)
    String code = _generateInviteCode();
    for (int i = 0; i < 5; i++) {
      final clash = await _client
          .from('groups')
          .select('id')
          .eq('invite_code', code)
          .maybeSingle();
      if (clash == null) break;
      code = _generateInviteCode();
    }

    final group = await _client
        .from('groups')
        .insert({
          'name': name.trim(),
          'invite_code': code,
          'description': description,
          'created_by': userId,
        })
        .select()
        .single();

    // Add creator as admin
    await _client.from('group_members').insert({
      'group_id': group['id'],
      'user_id': userId,
      'role': 'admin',
    });

    // Point profile to this group
    await _client
        .from('profiles')
        .update({'current_group_id': group['id']})
        .eq('id', userId);

    return group;
  }

  /// Join a group by name + invite code.
  Future<Map<String, dynamic>> joinGroup({
    required String name,
    required String inviteCode,
    required String userId,
  }) async {
    final group = await _client
        .from('groups')
        .select()
        .ilike('name', name.trim())
        .eq('invite_code', inviteCode.trim().toUpperCase())
        .maybeSingle();

    if (group == null) {
      throw Exception('اسم المجموعة أو الكود غير صحيح');
    }

    // Check if already a member
    final existing = await _client
        .from('group_members')
        .select()
        .eq('group_id', group['id'])
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('group_members').insert({
        'group_id': group['id'],
        'user_id': userId,
        'role': 'member',
      });
    }

    await _client
        .from('profiles')
        .update({'current_group_id': group['id']})
        .eq('id', userId);

    return group;
  }

  /// Get the current group of a user (with metadata).
  Future<Map<String, dynamic>?> getMyGroup(String userId) async {
    final profile = await _client
        .from('profiles')
        .select('current_group_id')
        .eq('id', userId)
        .maybeSingle();

    if (profile == null || profile['current_group_id'] == null) return null;

    final group = await _client
        .from('groups')
        .select()
        .eq('id', profile['current_group_id'])
        .maybeSingle();

    return group;
  }

  /// All members of a group with profile info.
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final res = await _client
        .from('group_members')
        .select('''
          role,
          joined_at,
          user_id,
          profiles:user_id (id, name, avatar_url, iman, current_streak, total_hasanat)
        ''')
        .eq('group_id', groupId);

    // Sort by iman desc
    final list = (res as List).cast<Map<String, dynamic>>();
    list.sort((a, b) {
      final aIman = (a['profiles']?['iman'] ?? 0) as num;
      final bIman = (b['profiles']?['iman'] ?? 0) as num;
      return bIman.compareTo(aIman);
    });
    return list;
  }

  /// Realtime stream of members for a group.
  Stream<List<Map<String, dynamic>>> streamGroupMembers(String groupId) {
    return _client
        .from('group_members')
        .stream(primaryKey: ['group_id', 'user_id'])
        .eq('group_id', groupId)
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

  /// Leave a group.
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);

    await _client
        .from('profiles')
        .update({'current_group_id': null})
        .eq('id', userId);
  }
}