import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  late final NotificationRepository _repo;
  List<Map<String, dynamic>> _items = [];
  StreamSubscription? _sub;

  NotificationProvider() {
    _repo = NotificationRepository(Supabase.instance.client);
  }

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  int unreadCount() => _items.where((n) => n['is_read'] != true).length;

  Future<void> loadForUser(String userId) async {
    _items = await _repo.getForUser(userId);
    notifyListeners();
    _subscribe(userId);
  }

  void _subscribe(String userId) {
    _sub?.cancel();
    _sub = _repo.streamForUser(userId).listen((rows) {
      _items = rows.reversed.toList();
      notifyListeners();
    });
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
  }

  Future<void> markAllRead(String userId) async {
    await _repo.markAllRead(userId);
  }

  Future<void> create({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? icon,
  }) async {
    await _repo.create(
      userId: userId,
      type: type,
      title: title,
      message: message,
      icon: icon,
    );
  }

  void clear() {
    _sub?.cancel();
    _items = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}