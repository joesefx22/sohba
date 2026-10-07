import 'package:flutter/material.dart';

enum BadgeTier { bronze, silver, gold, platinum }

enum BadgeCategory { prayer, streak, athkar, special }

extension BadgeTierX on BadgeTier {
  Color get color {
    switch (this) {
      case BadgeTier.bronze:
        return const Color(0xFFB87333);
      case BadgeTier.silver:
        return const Color(0xFFB8B8B8);
      case BadgeTier.gold:
        return const Color(0xFFD8B65A);
      case BadgeTier.platinum:
        return const Color(0xFF6DE7B0);
    }
  }

  String get labelAr {
    switch (this) {
      case BadgeTier.bronze:
        return 'برونزي';
      case BadgeTier.silver:
        return 'فضي';
      case BadgeTier.gold:
        return 'ذهبي';
      case BadgeTier.platinum:
        return 'بلاتيني';
    }
  }
}

extension BadgeCategoryX on BadgeCategory {
  String get labelAr {
    switch (this) {
      case BadgeCategory.prayer:
        return 'الصلاة';
      case BadgeCategory.streak:
        return 'المواصلة';
      case BadgeCategory.athkar:
        return 'الأذكار';
      case BadgeCategory.special:
        return 'خاصة';
    }
  }
}

class Badge {
  final String id;
  final String nameAr;
  final String description;
  final String icon;
  final BadgeTier tier;
  final BadgeCategory category;
  final String condition;
  final int? targetValue;

  /// Optional compound requirements.
  ///
  /// Only populated when [condition] == 'compound'. Consumed by
  /// [CompoundBadgeEngine.evaluate].
  ///
  /// Expected shape (Supabase `badges.requirements` jsonb):
  /// ```json
  /// {
  ///   "all_of": ["isha_congregation", "fajr_congregation", "witr", "shaf"],
  ///   "min_sunnah_rakat": 12,
  ///   "has_duha": true
  /// }
  /// ```
  final Map<String, dynamic>? requirements;

  final int rewardXp;
  final int rewardHasanat;
  final bool isSecret;

  const Badge({
    required this.id,
    required this.nameAr,
    required this.description,
    required this.icon,
    required this.tier,
    required this.category,
    required this.condition,
    this.targetValue,
    this.requirements,
    this.rewardXp = 0,
    this.rewardHasanat = 0,
    this.isSecret = false,
  });

  /// True when the badge's unlock logic is delegated to
  /// [CompoundBadgeEngine] instead of the simple [BadgeContext] comparison.
  bool get isCompound => condition == 'compound' && requirements != null;

  IconData get iconData {
    const map = {
      'wb_twilight': Icons.wb_twilight,
      'mosque': Icons.mosque,
      'nightlight': Icons.nightlight,
      'book': Icons.menu_book,
      'local_fire_department': Icons.local_fire_department,
      'crown': Icons.workspace_premium,
      'workspace_premium': Icons.workspace_premium,
      'star': Icons.star,
      'sparkle': Icons.auto_awesome,
      'wb_sunny': Icons.wb_sunny,
    };
    return map[icon] ?? Icons.emoji_events;
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      tier: BadgeTier.values.byName(json['tier'] as String),
      category: BadgeCategory.values.byName(json['category'] as String),
      condition: json['condition'] as String,
      targetValue: json['target_value'] as int?,
      requirements: json['requirements'] != null
          ? Map<String, dynamic>.from(json['requirements'] as Map)
          : null,
      rewardXp: json['reward_xp'] as int? ?? 0,
      rewardHasanat: json['reward_hasanat'] as int? ?? 0,
      isSecret: json['is_secret'] as bool? ?? false,
    );
  }

  /// Debug helper.
  @override
  String toString() =>
      'Badge($id, tier: ${tier.name}, category: ${category.name}, '
      'condition: $condition, compound: $isCompound)';
}

class UserBadge {
  final String badgeId;
  final DateTime unlockedAt;

  const UserBadge({required this.badgeId, required this.unlockedAt});

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      badgeId: json['badge_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }
}

/// Context used by the badge engine to evaluate conditions.
class BadgeContext {
  final int fajrCongregationStreak;
  final int allPrayersOnTimeDays;
  final int qiyamStreak;
  final int athkarStreak;
  final int overallStreak;
  final int totalHasanat;

  const BadgeContext({
    this.fajrCongregationStreak = 0,
    this.allPrayersOnTimeDays = 0,
    this.qiyamStreak = 0,
    this.athkarStreak = 0,
    this.overallStreak = 0,
    this.totalHasanat = 0,
  });

  int valueFor(String condition) {
    switch (condition) {
      case 'fajr_congregation_streak':
        return fajrCongregationStreak;
      case 'all_prayers_on_time':
        return allPrayersOnTimeDays;
      case 'qiyam_streak':
        return qiyamStreak;
      case 'athkar_streak':
        return athkarStreak;
      case 'overall_streak':
        return overallStreak;
      case 'total_hasanat':
        return totalHasanat;
      default:
        return 0;
    }
  }
}