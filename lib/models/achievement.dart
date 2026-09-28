import 'package:flutter/material.dart';
import 'enums.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementTier tier;
  final AchievementCategory category;
  final String condition;
  final int? targetValue;
  final int rewardXP;
  final int? rewardPoints;
  final String? rewardItem;
  final bool isSecret;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.category,
    required this.condition,
    this.targetValue,
    required this.rewardXP,
    this.rewardPoints,
    this.rewardItem,
    this.isSecret = false,
  });

  Color get tierColor {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'tier': tier.name,
      'category': category.name,
      'condition': condition,
      'targetValue': targetValue,
      'rewardXP': rewardXP,
      'rewardPoints': rewardPoints,
      'rewardItem': rewardItem,
      'isSecret': isSecret,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      tier: AchievementTier.values.byName(json['tier'] as String),
      category: AchievementCategory.values.byName(json['category'] as String),
      condition: json['condition'] as String,
      targetValue: json['targetValue'] as int?,
      rewardXP: json['rewardXP'] as int,
      rewardPoints: json['rewardPoints'] as int?,
      rewardItem: json['rewardItem'] as String?,
      isSecret: json['isSecret'] as bool,
    );
  }

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    AchievementTier? tier,
    AchievementCategory? category,
    String? condition,
    int? targetValue,
    int? rewardXP,
    int? rewardPoints,
    String? rewardItem,
    bool? isSecret,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      tier: tier ?? this.tier,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      targetValue: targetValue ?? this.targetValue,
      rewardXP: rewardXP ?? this.rewardXP,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      rewardItem: rewardItem ?? this.rewardItem,
      isSecret: isSecret ?? this.isSecret,
    );
  }
}

class AchievementProgress {
  final String id;
  final String heroId;
  final String achievementId;
  final int currentProgress;
  final int targetProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.id,
    required this.heroId,
    required this.achievementId,
    this.currentProgress = 0,
    required this.targetProgress,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  double get progressPercent =>
      targetProgress > 0 ? currentProgress / targetProgress : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'heroId': heroId,
      'achievementId': achievementId,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      id: json['id'] as String,
      heroId: json['heroId'] as String,
      achievementId: json['achievementId'] as String,
      currentProgress: json['currentProgress'] as int,
      targetProgress: json['targetProgress'] as int,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  AchievementProgress copyWith({
    String? id,
    String? heroId,
    String? achievementId,
    int? currentProgress,
    int? targetProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementProgress(
      id: id ?? this.id,
      heroId: heroId ?? this.heroId,
      achievementId: achievementId ?? this.achievementId,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
