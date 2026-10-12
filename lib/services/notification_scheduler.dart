import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/prayer_log.dart';
import 'adhan_service.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';

/// Orchestrates all scheduled notifications.
///
/// Called from:
///   - SplashPage (after login / location resolved)
///   - SettingsPage (when user toggles options)
///   - Location change (future)
///
/// IDs are deterministic so we can cancel/reschedule cleanly.
class NotificationScheduler {
  NotificationScheduler._();

  // Deterministic IDs (avoid collisions).
  static const int _idAdhanBase   = 1000;  // 1000..1004 (5 prayers)
  static const int _idReminderBase = 2000; // 2000..2004 (reminders before adhan)
  static const int _idStreak      = 3000;
  static const int _idDailyLesson = 4000;

  /// Full reschedule — call this on app start and after any preference change.
  static Future<void> rescheduleAll() async {
    if (!PushNotificationService.isInitialized) {
      debugPrint('NotificationScheduler: plugin not initialized');
      return;
    }

    // 1. Check master toggle
    final enabled = await NotificationService.isEnabled();
    if (!enabled) {
      await PushNotificationService.cancelAll();
      debugPrint('NotificationScheduler: notifications disabled by user');
      return;
    }

    // 2. Clear old ones
    await PushNotificationService.cancelAll();

    // 3. Schedule per category
    await _schedulePrayerAdhans();
    await _scheduleStreakReminder();

    final pending = await PushNotificationService.pending();
    debugPrint('NotificationScheduler: ${pending.length} notifications scheduled');
  }

  // ============================================
  // PRAYER ADHANS + REMINDERS
  // ============================================

  static Future<void> _schedulePrayerAdhans() async {
    final adhanEnabled = await NotificationService.isAdhanEnabled();
    final reminderMinutes = await NotificationService.reminderMinutes();
    final now = DateTime.now();

    for (var i = 0; i < PrayerName.values.length; i++) {
      final prayer = PrayerName.values[i];
      final adhanTime = AdhanService.timeFor(prayer, onDate: now);

      // If adhan already passed today, skip (will be rescheduled tomorrow
      // when the app is opened again).
      if (adhanTime.isBefore(now)) continue;

      // ---- Adhan notification ----
      if (adhanEnabled) {
        await PushNotificationService.schedule(
          id: _idAdhanBase + i,
          title: 'حان وقت ${prayer.arabicName}',
          body: _adhanBody(prayer),
          when: adhanTime,
          channelId: PushNotificationService.channelAdhan,
          payload: 'prayer:${prayer.name}',
          isAdhan: true,
        );
      }

      // ---- Pre-adhan reminder ----
      if (reminderMinutes > 0) {
        final reminderTime =
            adhanTime.subtract(Duration(minutes: reminderMinutes));
        if (reminderTime.isAfter(now)) {
          await PushNotificationService.schedule(
            id: _idReminderBase + i,
            title: '${prayer.arabicName} بعد $reminderMinutes دقيقة',
            body: 'استعد للصلاة — الأذان يقترب',
            when: reminderTime,
            channelId: PushNotificationService.channelPrayer,
            payload: 'prayer:${prayer.name}:reminder',
          );
        }
      }
    }
  }

  static String _adhanBody(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return 'الصلاة خير من النوم — قم إلى الفجر';
      case PrayerName.dhuhr:
        return 'توقف عن العمل واسترح — حان وقت الظهر';
      case PrayerName.asr:
        return 'حافظ على الصلاة الوسطى — حان وقت العصر';
      case PrayerName.maghrib:
        return 'ادعُ ربك قبل المغرب — حان وقت المغرب';
      case PrayerName.isha:
        return 'اختم يومك بالصلاة — حان وقت العشاء';
    }
  }

  // ============================================
  // STREAK REMINDER (9 PM daily)
  // ============================================

  static Future<void> _scheduleStreakReminder() async {
    final enabled = await NotificationService.isStreakReminderEnabled();
    if (!enabled) return;

    final hour = await NotificationService.streakReminderHour();
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour);

    // If 9 PM already passed today, schedule for tomorrow.
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    await PushNotificationService.schedule(
      id: _idStreak,
      title: 'حافظ على مواصلتك',
      body: 'سجّل صلواتك قبل منتصف الليل حتى لا تخسر سلسلتك',
      when: target,
      channelId: PushNotificationService.channelStreak,
      payload: 'streak',
    );
  }

  // ============================================
  // ONE-OFF NOTIFICATIONS (immediate)
  // ============================================

  /// Called when a badge is unlocked — schedule for 3 seconds from now.
  static Future<void> showBadgeUnlock({
    required String badgeName,
    required String description,
  }) async {
    if (!PushNotificationService.isInitialized) return;
    if (!await NotificationService.isEnabled()) return;

    await PushNotificationService.schedule(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'ميدالية جديدة: $badgeName',
      body: description,
      when: DateTime.now().add(const Duration(seconds: 2)),
      channelId: PushNotificationService.channelBadge,
      payload: 'badge:$badgeName',
    );
  }

  /// Called when a streak milestone is reached.
  static Future<void> showStreakMilestone(int days) async {
    if (!PushNotificationService.isInitialized) return;
    if (!await NotificationService.isEnabled()) return;

    await PushNotificationService.schedule(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
      title: 'مواصلة $days يوم!',
      body: 'ما شاء الله، استمر على الطاعة!',
      when: DateTime.now().add(const Duration(seconds: 2)),
      channelId: PushNotificationService.channelStreak,
      payload: 'streak_milestone:$days',
    );
  }

  // ============================================
  // DEBUG
  // ============================================

  static Future<List<PendingNotificationRequest>> listPending() =>
      PushNotificationService.pending();

  static Future<void> cancelAll() => PushNotificationService.cancelAll();

  /// Test: schedule a notification 5 seconds from now.
  static Future<void> sendTest() async {
    await PushNotificationService.schedule(
      id: 9999,
      title: 'إشعار تجريبي',
      body: 'لو شايف الإشعار ده، الإشعارات شغّالة ✅',
      when: DateTime.now().add(const Duration(seconds: 5)),
      channelId: PushNotificationService.channelSystem,
      payload: 'test',
    );
  }
}