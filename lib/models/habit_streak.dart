class HabitStreak {
  final String habitKey;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  const HabitStreak({
    required this.habitKey,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });

  String get labelAr {
    switch (habitKey) {
      case 'fajr_congregation': return 'الفجر جماعة';
      case 'dhuhr_congregation': return 'الظهر جماعة';
      case 'asr_congregation': return 'العصر جماعة';
      case 'maghrib_congregation': return 'المغرب جماعة';
      case 'isha_congregation': return 'العشاء جماعة';
      case 'qiyam': return 'قيام الليل';
      case 'duha': return 'صلاة الضحى';
      case 'sunnah_12': return '12 ركعة سنة';
      default: return habitKey;
    }
  }

  factory HabitStreak.fromJson(Map<String, dynamic> j) => HabitStreak(
        habitKey: j['habit_key'] as String,
        currentStreak: j['current_streak'] as int? ?? 0,
        longestStreak: j['longest_streak'] as int? ?? 0,
        lastActiveDate: j['last_active_date'] != null
            ? DateTime.parse(j['last_active_date'] as String)
            : null,
      );
}