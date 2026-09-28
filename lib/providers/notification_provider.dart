import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/storage_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];

  static const String _storageKey = 'notifications';

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// Returns notifications for a specific user, sorted newest first.
  List<AppNotification> userNotifications(String userId) {
    final userItems = _notifications.where((n) => n.userId == userId).toList();
    userItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userItems;
  }

  /// Returns the count of unread notifications for a user.
  int unreadCount(String userId) {
    return _notifications
        .where((n) => n.userId == userId && !n.isRead)
        .length;
  }

  /// Load notifications from storage.
  Future<void> loadData() async {
    try {
      _notifications = await StorageService.loadList(
        _storageKey,
        AppNotification.fromJson,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider.loadData error: $e');
    }
  }

  /// Add a new notification.
  Future<void> addNotification(AppNotification notification) async {
    _notifications.add(notification);
    await _save();
    notifyListeners();
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    await _save();
    notifyListeners();
  }

  /// Mark all notifications for a user as read.
  Future<void> markAllAsRead(String userId) async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      await _save();
      notifyListeners();
    }
  }

  /// Helper to create and add a notification in one step.
  Future<void> create({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    required String icon,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      title: title,
      message: message,
      icon: icon,
      createdAt: DateTime.now(),
    );
    await addNotification(notification);
  }

  Future<void> _save() async {
    await StorageService.saveList(
      _storageKey,
      _notifications,
      (n) => n.toJson(),
    );
  }
}
