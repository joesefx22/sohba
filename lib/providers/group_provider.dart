import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/group_repository.dart';

class GroupProvider extends ChangeNotifier {
  late final GroupRepository _repo;
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _members = [];
  StreamSubscription? _membersSub;
  bool _loading = false;
  String? _error;

  GroupProvider() {
    _repo = GroupRepository(Supabase.instance.client);
  }

  Map<String, dynamic>? get group => _group;
  List<Map<String, dynamic>> get members => List.unmodifiable(_members);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasGroup => _group != null;

  Future<void> loadForUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _group = await _repo.getMyGroup(userId);
      if (_group != null) {
        await _refreshMembers();
        _subscribe(_group!['id'] as String);
      }
    } catch (e) {
      _error = _friendlyError(e);
      debugPrint('GroupProvider.loadForUser: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup({
    required String name,
    required String userId,
    String? description,
  }) async {
    _error = null;
    try {
      _group = await _repo.createGroup(
        name: name,
        userId: userId,
        description: description,
      );
      await _refreshMembers();
      _subscribe(_group!['id'] as String);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      debugPrint('GroupProvider.createGroup: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinGroup({
    required String name,
    required String inviteCode,
    required String userId,
  }) async {
    _error = null;
    try {
      _group = await _repo.joinGroup(
        name: name,
        inviteCode: inviteCode,
        userId: userId,
      );
      await _refreshMembers();
      _subscribe(_group!['id'] as String);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      debugPrint('GroupProvider.joinGroup: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> leaveGroup(String userId) async {
    if (_group == null) return;
    try {
      await _repo.leaveGroup(
        groupId: _group!['id'] as String,
        userId: userId,
      );
    } catch (e) {
      debugPrint('GroupProvider.leaveGroup: $e');
    } finally {
      _membersSub?.cancel();
      _membersSub = null;
      _group = null;
      _members = [];
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_group == null) return;
    await _refreshMembers();
    notifyListeners();
  }

  Future<void> _refreshMembers() async {
    if (_group == null) return;
    try {
      _members = await _repo.getGroupMembers(_group!['id'] as String);
    } catch (e) {
      debugPrint('GroupProvider._refreshMembers: $e');
    }
  }

  void _subscribe(String groupId) {
    _membersSub?.cancel();
    _membersSub = _repo.streamGroupMembers(groupId).listen(
      (_) async {
        await _refreshMembers();
        if (_group != null) notifyListeners();
      },
      onError: (e) {
        debugPrint('GroupProvider realtime error: $e');
      },
    );
  }

  /// Convert raw errors to friendly Arabic messages.
  String _friendlyError(Object e) {
    final raw = e.toString();
    final lower = raw.toLowerCase();

    // Repository throws `Exception('message')` — extract the message
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }

    if (e is PostgrestException) {
      // Duplicate name (unique index on lower(name))
      if (e.code == '23505') {
        return 'اسم المجموعة مستخدم بالفعل';
      }
      // Foreign key / permission
      if (e.code == '23503' || e.code == '42501') {
        return 'تعذّر إتمام العملية — تحقق من صلاحياتك';
      }
      return e.message;
    }

    if (lower.contains('network') || lower.contains('socket')) {
      return 'تحقق من اتصالك بالإنترنت';
    }

    return raw;
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    super.dispose();
  }
}