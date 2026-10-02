/// Sohba — Application Constants
///
/// Central place for everything that's fixed across the app:
/// prayer calculation method, madhab, default location (Egypt),
/// and the prayer engine timeline windows.
class AppConfig {
  AppConfig._();

  // ============================================
  // APP INFO
  // ============================================
  static const String appName = 'صحبة';
  static const String appTagline = 'رفيقك على طريق الطاعة';
  static const String appVersion = '0.1.0';

  // ============================================
  // LOCATION — Egypt only (MVP)
  // ============================================
  /// Default location: Cairo, Egypt
  static const double defaultLatitude = 30.0444;
  static const double defaultLongitude = 31.2357;

  /// Default timezone
  static const String timezone = 'Africa/Cairo';

  /// Country code
  static const String countryCode = 'EG';

  // ============================================
  // PRAYER CALCULATION — Egypt + Shafi
  // ============================================
  /// Egyptian General Authority of Survey
  /// Fajr angle: 19.5°, Isha angle: 17.5°
  static const String calculationMethod = 'egyptian';

  /// Shafi madhab (earlier Asr time)
  static const String madhab = 'shafi';

  // ============================================
  // PRAYER ENGINE TIMELINE
  // ============================================
  //
  // For each prayer, the timeline has 4 windows:
  //
  //   [Adhan]
  //      │
  //      ├─► Congregation window: opens +40min, lasts 30min
  //      │   └─ if confirmed: +27 hasanat
  //      │
  //      ├─► Individual window: from end of congregation
  //      │   until (next prayer adhan - 15min)
  //      │   └─ if confirmed: +1 hasanat
  //      │
  //      ├─► Qada window: from end of individual
  //      │   until same prayer tomorrow
  //      │   └─ if confirmed: QADA + tawbah (sayyiat → repented)
  //      │
  //      └─► Missed: after qada window
  //          └─ +200 sayyiat (UNREPENTED)
  //
  // All durations in minutes.

  /// Minutes after adhan before the congregation window opens.
  static const int congregationWindowOpenDelay = 40;

  /// How long the congregation window stays open.
  static const int congregationWindowDuration = 30;

  /// How many minutes before the next prayer adhan the
  /// individual window closes.
  static const int individualWindowCloseBuffer = 15;

  /// Qada window duration (extends until the same prayer next day).
  static const Duration qadaWindowDuration = Duration(hours: 24);

  // ============================================
  // GAME ECONOMY
  // ============================================
  static const int hasanatPerCongregation = 27;
  static const int hasanatPerIndividual = 1;
  static const int hasanatPerSunnah = 15;
  static const int hasanatPerQiyam = 30;
  static const int hasanatPerDuaInQiyam = 10;
  static const int hasanatPerDhikrWard = 10;

  static const int sayyiatPerMissedPrayer = 200;

  // Conversion rates
  static const int hasanatPerIman = 100;
  static const int sayyiatPerIman = 50;

  // ============================================
  // STREAK THRESHOLDS
  // ============================================
  static const int streakMilestone7 = 7;
  static const int streakMilestone14 = 14;
  static const int streakMilestone30 = 30;
  static const int streakMilestone60 = 60;
  static const int streakMilestone100 = 100;
  static const int streakMilestone365 = 365;

  static const List<int> streakMilestones = [
    streakMilestone7,
    streakMilestone14,
    streakMilestone30,
    streakMilestone60,
    streakMilestone100,
    streakMilestone365,
  ];

  // ============================================
  // ATHKAR
  // ============================================
  static const String athkarAssetPath = 'assets/athkar/hisnul_muslim.json';
  static const int mandatoryMorningAthkarCount = 5;
  static const int mandatoryEveningAthkarCount = 5;

  // ============================================
  // SUPABASE TABLES (for type-safety)
  // ============================================
  static const String tableProfiles = 'profiles';
  static const String tableGroups = 'groups';
  static const String tableGroupMembers = 'group_members';
  static const String tablePrayerLogs = 'prayer_logs';
  static const String tableAthkarCategories = 'athkar_categories';
  static const String tableAthkarItems = 'athkar_items';
  static const String tableUserAthkarLogs = 'user_athkar_logs';
  static const String tableTransactions = 'transactions';
  static const String tableBadges = 'badges';
  static const String tableUserBadges = 'user_badges';
  static const String tableNotifications = 'notifications';
}