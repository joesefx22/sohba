/// Sohba — Application Constants
/// مبسّط: بدون أذكار، بدون سنن، بدون إيمان. الميداليات باقية.
class AppConfig {
  AppConfig._();

  // App Info
  static const String appName = 'صحبة';
  static const String appTagline = 'رفيقك على طريق الطاعة';
  static const String appVersion = '0.2.0';

  // Location
  static const double defaultLatitude = 30.0444;
  static const double defaultLongitude = 31.2357;
  static const String timezone = 'Africa/Cairo';
  static const String countryCode = 'EG';

  // Prayer Calculation
  static const String calculationMethod = 'egyptian';
  static const String madhab = 'shafi';

  // Rewards (بدون إيمان — حسنات وسيئات مباشرة)
  static const int hasanatPerCongregation = 27;
  static const int hasanatPerIndividual = 1;
  static const int sayyiatPerMissedPrayer = 200;

  // Himmah (نظام الحماية — زي ما هو)
  static const int himmahProtectStreakCost = 1;
  static const int himmahSkipOptionalCost = 2;
  static const Map<int, int> himmahMilestones = {
    7: 3, 14: 5, 30: 10, 60: 20, 100: 50, 365: 200,
  };

  // Streak Milestones
  static const List<int> streakMilestones = [7, 14, 30, 60, 100, 365];

  // Supabase Tables
  static const String tableProfiles = 'profiles';
  static const String tableGroups = 'groups';
  static const String tableGroupMembers = 'group_members';
  static const String tablePrayerLogs = 'prayer_logs';
  static const String tableTransactions = 'transactions';
  static const String tableBadges = 'badges';
  static const String tableUserBadges = 'user_badges';
  static const String tableNotifications = 'notifications';
  static const String tableAppVersions = 'app_versions';
}