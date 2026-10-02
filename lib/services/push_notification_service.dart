import 'package:flutter/foundation.dart';

/// Skeleton for real push notifications.
///
/// INTEGRATION STEPS (production):
///   1. flutter pub add flutter_local_notifications timezone
///   2. Initialize in main() before runApp()
///   3. Call scheduleAll() after login and after AdhanService.setLocation()
///
/// For now this is a no-op wrapper so the rest of the app can call it safely.
class PushNotificationService {
  PushNotificationService._();

  static bool _enabled = false;

  static Future<void> init() async {
    // TODO: initialize FlutterLocalNotificationsPlugin here.
    _enabled = false;
    debugPrint('PushNotificationService: init (skeleton)');
  }

  /// Recompute and schedule all 5 daily prayer notifications.
  static Future<void> scheduleAll({
    required List<({String id, String title, String body, DateTime at})> items,
  }) async {
    if (!_enabled) return;
    // TODO: cancelAll() then schedule each `items[i]` with zonedSchedule.
    for (final it in items) {
      debugPrint('schedule ${it.title} @ ${it.at}');
    }
  }

  static Future<void> cancelAll() async {
    if (!_enabled) return;
    // TODO: cancelAll()
  }

  /// One-off: streak reminder at a given hour.
  static Future<void> scheduleStreakReminder(int hour) async {
    if (!_enabled) return;
    debugPrint('streak reminder @ $hour:00');
  }
}