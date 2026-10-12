import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around flutter_local_notifications.
///
/// Responsibilities:
///   - Initialize plugin + timezone DB
///   - Create Android notification channels
///   - Request permissions (Android 13+, iOS)
///   - Expose zonedSchedule / cancel / cancelAll
class PushNotificationService {
  PushNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Handler when the user taps a notification (app opened).
  static void Function(String? payload)? onTap;

  static FlutterLocalNotificationsPlugin get plugin => _plugin;
  static bool get isInitialized => _initialized;

  // ============================================
  // CHANNEL IDS
  // ============================================
  static const channelAdhan  = 'sohba.adhan';
  static const channelPrayer = 'sohba.prayer';
  static const channelStreak = 'sohba.streak';
  static const channelBadge  = 'sohba.badge';
  static const channelSystem = 'sohba.system';

  static const _channelSpecs = <({String id, String name, String desc})>[
    (id: channelAdhan,  name: 'الأذان',         desc: 'صوت الأذان عند دخول وقت الصلاة'),
    (id: channelPrayer, name: 'تنبيه الصلاة',    desc: 'تذكير قبل وبعد الأذان'),
    (id: channelStreak, name: 'المواصلة',       desc: 'تذكير قبل منتصف الليل للحفاظ على سلسلتك'),
    (id: channelBadge,  name: 'الميداليات',      desc: 'عند فتح ميدالية جديدة'),
    (id: channelSystem, name: 'تنبيهات عامة',    desc: 'إشعارات النظام'),
  ];

  // ============================================
  // INIT
  // ============================================

  static Future<void> init({
    void Function(String? payload)? onTap,
  }) async {
    if (_initialized) return;
    PushNotificationService.onTap = onTap;

    // 1. Timezone database (required for zonedSchedule)
    tz.initializeTimeZones();

    // 2. Android icon
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,  // we request explicitly later
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (res) {
        PushNotificationService.onTap?.call(res.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
    );

    // 4. Create Android channels
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        for (final spec in _channelSpecs) {
          await android.createNotificationChannel(
            AndroidNotificationChannel(
              spec.id,
              spec.name,
              description: spec.desc,
              importance: spec.id == channelAdhan
                  ? Importance.max
                  : Importance.high,
            ),
          );
        }
      }
    }

    _initialized = true;
    debugPrint('PushNotificationService: initialized');
  }

  // ============================================
  // PERMISSIONS
  // ============================================

  /// Returns true if notification permission is granted.
  static Future<bool> requestPermissions() async {
    if (!_initialized) {
      debugPrint('PushNotificationService: not initialized');
      return false;
    }

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;

      // Android 13+
      final granted = await android.requestNotificationsPermission();

      // Android 12+ exact alarms
      await android.requestExactAlarmsPermission();

      return granted ?? false;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  static Future<bool> hasPermission() async {
    if (!_initialized) return false;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final settings = await ios?.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    return true;
  }

  // ============================================
  // SCHEDULING
  // ============================================

  /// Schedule a notification at a specific local time.
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String channelId,
    String? payload,
    bool playSound = true,
    bool isAdhan = false,
  }) async {
    if (!_initialized) return;
    if (when.isBefore(DateTime.now())) return;

    final tzWhen = tz.TZDateTime.from(when, tz.local);

    // Android details
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelSpecs.firstWhere((s) => s.id == channelId).name,
      channelDescription:
          _channelSpecs.firstWhere((s) => s.id == channelId).desc,
      importance: isAdhan ? Importance.max : Importance.high,
      priority: isAdhan ? Priority.max : Priority.high,
      playSound: playSound,
      enableVibration: true,
      category: isAdhan
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      fullScreenIntent: isAdhan,
      visibility: NotificationVisibility.public,
    );

    // iOS details
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
      sound: playSound ? 'default' : null,
      interruptionLevel:
          isAdhan ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> cancelAll() => _plugin.cancelAll();

  /// Return IDs of pending notifications (useful for debugging).
  static Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();
}

/// Background tap handler (must be top-level).
@pragma('vm:entry-point')
void _backgroundHandler(NotificationResponse response) {
  debugPrint('Background notification tap: ${response.payload}');
}