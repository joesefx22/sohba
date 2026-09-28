class HeroAppearance {
  final String baseAvatar;
  final String skinColor;
  final String hairStyle;
  final String hairColor;
  final String outfit;
  final String? accessory;
  final String? pet;

  const HeroAppearance({
    required this.baseAvatar,
    required this.skinColor,
    required this.hairStyle,
    required this.hairColor,
    required this.outfit,
    this.accessory,
    this.pet,
  });

  Map<String, dynamic> toJson() {
    return {
      'baseAvatar': baseAvatar,
      'skinColor': skinColor,
      'hairStyle': hairStyle,
      'hairColor': hairColor,
      'outfit': outfit,
      'accessory': accessory,
      'pet': pet,
    };
  }

  factory HeroAppearance.fromJson(Map<String, dynamic> json) {
    return HeroAppearance(
      baseAvatar: json['baseAvatar'] as String,
      skinColor: json['skinColor'] as String,
      hairStyle: json['hairStyle'] as String,
      hairColor: json['hairColor'] as String,
      outfit: json['outfit'] as String,
      accessory: json['accessory'] as String?,
      pet: json['pet'] as String?,
    );
  }

  HeroAppearance copyWith({
    String? baseAvatar,
    String? skinColor,
    String? hairStyle,
    String? hairColor,
    String? outfit,
    String? accessory,
    String? pet,
  }) {
    return HeroAppearance(
      baseAvatar: baseAvatar ?? this.baseAvatar,
      skinColor: skinColor ?? this.skinColor,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      outfit: outfit ?? this.outfit,
      accessory: accessory ?? this.accessory,
      pet: pet ?? this.pet,
    );
  }
}

class Hero {
  final String id;
  final String userId;
  final String name;
  final int level;
  final int currentXP;
  final int xpToNextLevel;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final List<DateTime> activityDates;
  final HeroAppearance appearance;
  final List<String> unlockedItems;
  final List<String> equippedItems;
  final List<String> badges;

  const Hero({
    required this.id,
    required this.userId,
    required this.name,
    this.level = 1,
    this.currentXP = 0,
    required this.xpToNextLevel,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.activityDates = const [],
    required this.appearance,
    this.unlockedItems = const [],
    this.equippedItems = const [],
    this.badges = const [],
  });

  double get xpProgress => currentXP / xpToNextLevel;

  String get title => _getTitleForLevel(level);

  static String _getTitleForLevel(int level) {
    if (level < 10) return 'Mochi Novice';
    if (level < 25) return 'Mochi Apprentice';
    if (level < 50) return 'Mochi Champion';
    return 'Mochi Legend';
  }

  static int calculateXPForLevel(int level) {
    return 100 + (level - 1) * 50;
  }

  Hero addXP(int xp) {
    int newXP = currentXP + xp;
    int newLevel = level;
    int newXpToNextLevel = xpToNextLevel;

    while (newXP >= newXpToNextLevel) {
      newXP -= newXpToNextLevel;
      newLevel++;
      newXpToNextLevel = calculateXPForLevel(newLevel);
    }

    return copyWith(
      level: newLevel,
      currentXP: newXP,
      xpToNextLevel: newXpToNextLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'level': level,
      'currentXP': currentXP,
      'xpToNextLevel': xpToNextLevel,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'activityDates': activityDates.map((d) => d.toIso8601String()).toList(),
      'appearance': appearance.toJson(),
      'unlockedItems': unlockedItems,
      'equippedItems': equippedItems,
      'badges': badges,
    };
  }

  factory Hero.fromJson(Map<String, dynamic> json) {
    return Hero(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      currentXP: json['currentXP'] as int,
      xpToNextLevel: json['xpToNextLevel'] as int,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'] as String)
          : null,
      activityDates: json['activityDates'] != null
          ? (json['activityDates'] as List)
              .map((d) => DateTime.parse(d as String))
              .toList()
          : [],
      appearance:
          HeroAppearance.fromJson(json['appearance'] as Map<String, dynamic>),
      unlockedItems: List<String>.from(json['unlockedItems'] as List),
      equippedItems: List<String>.from(json['equippedItems'] as List),
      badges: List<String>.from(json['badges'] as List),
    );
  }

  Hero copyWith({
    String? id,
    String? userId,
    String? name,
    int? level,
    int? currentXP,
    int? xpToNextLevel,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    List<DateTime>? activityDates,
    HeroAppearance? appearance,
    List<String>? unlockedItems,
    List<String>? equippedItems,
    List<String>? badges,
  }) {
    return Hero(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      activityDates: activityDates ?? this.activityDates,
      appearance: appearance ?? this.appearance,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      equippedItems: equippedItems ?? this.equippedItems,
      badges: badges ?? this.badges,
    );
  }
}
