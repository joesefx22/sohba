import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_log.dart';
import 'adhan_service.dart';

/// إدارة إعدادات الإشعارات + حساب جدول اليوم.
///
/// ⚠️ TODO (production): اربط هذه الخدمة بـ `flutter_local_notifications`
/// أو FCM لإرسال الإشعارات فعليًا. حاليًا نحفظ الإعدادات ونحسب الجدول فقط.
class NotificationService {
  NotificationService._();

  static const _keyEnabled = 'notif_enabled';
  static const _keyAdhanEnabled = 'notif_adhan';
  static const _keyReminderMinutes = 'notif_reminder_minutes';
  static const _keyStreakReminderEnabled = 'notif_streak';
  static const _keyStreakReminderHour = 'notif_streak_hour';

  // ── Preferences ────────────────────────────────────────────────

  static Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyEnabled) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyEnabled, value);
  }

  static Future<bool> isAdhanEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyAdhanEnabled) ?? true;
  }

  static Future<void> setAdhanEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyAdhanEnabled, value);
  }

  static Future<int> reminderMinutes() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyReminderMinutes) ?? 5;
  }

  static Future<void> setReminderMinutes(int value) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyReminderMinutes, value);
  }

  static Future<bool> isStreakReminderEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyStreakReminderEnabled) ?? true;
  }

  static Future<void> setStreakReminderEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyStreakReminderEnabled, value);
  }

  static Future<int> streakReminderHour() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyStreakReminderHour) ?? 21;
  }

  static Future<void> setStreakReminderHour(int hour) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyStreakReminderHour, hour);
  }

  // ── Schedule building ──────────────────────────────────────────

  static List<PrayerReminder> buildRemindersForToday() {
    final reminders = <PrayerReminder>[];
    for (final prayer in PrayerName.values) {
      final adhan = AdhanService.timeFor(prayer);
      reminders.add(PrayerReminder(
        prayer: prayer,
        title: 'حان وقت ${prayer.arabicName}',
        body: _bodyFor(prayer),
        scheduledAt: adhan,
      ));
    }
    return reminders;
  }

  static String _bodyFor(PrayerName prayer) {
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

  static String describeSchedule() {
    final reminders = buildRemindersForToday();
    return reminders
        .map((r) =>
            '${r.prayer.arabicName}: ${AdhanService.formatTime(r.scheduledAt)}')
        .join('\n');
  }

  static void debugLogSchedule() {
    debugPrint('جدول إشعارات اليوم:');
    for (final r in buildRemindersForToday()) {
      debugPrint('  ${r.prayer.arabicName} — ${AdhanService.formatTime(r.scheduledAt)}');
    }
  }
}

class PrayerReminder {
  final PrayerName prayer;
  final String title;
  final String body;
  final DateTime scheduledAt;

  const PrayerReminder({
    required this.prayer,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });
}