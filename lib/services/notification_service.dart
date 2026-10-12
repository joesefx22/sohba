import 'package:shared_preferences/shared_preferences.dart';

/// User preferences for notifications.
///
/// Owns the WHAT (which notifications are enabled) — the WHEN and HOW
/// live in [NotificationScheduler] and [PushNotificationService].
class NotificationService {
  NotificationService._();

  static const _keyEnabled              = 'notif_enabled';
  static const _keyAdhanEnabled         = 'notif_adhan';
  static const _keyReminderMinutes      = 'notif_reminder_minutes';
  static const _keyStreakReminder       = 'notif_streak';
  static const _keyStreakReminderHour   = 'notif_streak_hour';
  static const _keyOnboardingShown      = 'notif_onboarding_shown';

  // ============================================
  // MASTER
  // ============================================

  static Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyEnabled) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyEnabled, value);
  }

  // ============================================
  // ADHAN
  // ============================================

  static Future<bool> isAdhanEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyAdhanEnabled) ?? true;
  }

  static Future<void> setAdhanEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyAdhanEnabled, value);
  }

  // ============================================
  // PRE-ADHAN REMINDER
  // ============================================

  static Future<int> reminderMinutes() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyReminderMinutes) ?? 5;
  }

  static Future<void> setReminderMinutes(int value) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyReminderMinutes, value);
  }

  // ============================================
  // STREAK REMINDER
  // ============================================

  static Future<bool> isStreakReminderEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyStreakReminder) ?? true;
  }

  static Future<void> setStreakReminderEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyStreakReminder, value);
  }

  static Future<int> streakReminderHour() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyStreakReminderHour) ?? 21; // 9 PM
  }

  static Future<void> setStreakReminderHour(int hour) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyStreakReminderHour, hour);
  }

  // ============================================
  // ONBOARDING
  // ============================================

  /// Whether we've already shown the permission request dialog.
  static Future<bool> hasShownOnboarding() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyOnboardingShown) ?? false;
  }

  static Future<void> markOnboardingShown() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyOnboardingShown, true);
  }
}