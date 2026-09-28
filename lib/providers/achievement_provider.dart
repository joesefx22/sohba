import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../models/enums.dart';
import '../services/storage_service.dart';

/// Context data for checking achievement conditions
class AchievementContext {
  final int questsCompleted;
  final int epicQuestsCompleted;
  final int legendaryQuestsCompleted;
  final int currentStreak;
  final int longestStreak;
  final int totalPointsEarned;
  final int totalPointsSpent;
  final int rewardsPurchased;
  final int level;
  final int totalXP;

  const AchievementContext({
    this.questsCompleted = 0,
    this.epicQuestsCompleted = 0,
    this.legendaryQuestsCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalPointsEarned = 0,
    this.totalPointsSpent = 0,
    this.rewardsPurchased = 0,
    this.level = 1,
    this.totalXP = 0,
  });
}

/// Callback when an achievement is unlocked
typedef AchievementUnlockedCallback = void Function(
  String heroId,
  Achievement achievement,
);

class AchievementProvider extends ChangeNotifier {
  List<Achievement> _achievements = [];
  Map<String, List<AchievementProgress>> _progress = {};

  List<Achievement> get achievements => List.unmodifiable(_achievements);
  Map<String, List<AchievementProgress>> get progress =>
      Map.unmodifiable(_progress);

  static const String _achievementsKey = 'achievements';
  static const String _progressKey = 'achievement_progress';

  /// Callback triggered when an achievement is unlocked
  AchievementUnlockedCallback? onAchievementUnlocked;

  // Getters

  /// Get all achievements for a hero with their progress
  List<(Achievement, AchievementProgress?)> getAchievementsWithProgress(
      String heroId) {
    final heroProgress = _progress[heroId] ?? [];
    return _achievements.map((achievement) {
      final prog = heroProgress
          .where((p) => p.achievementId == achievement.id)
          .firstOrNull;
      return (achievement, prog);
    }).toList();
  }

  /// Get unlocked achievements for a hero
  List<Achievement> getUnlockedAchievements(String heroId) {
    final heroProgress = _progress[heroId] ?? [];
    final unlockedIds = heroProgress
        .where((p) => p.isUnlocked)
        .map((p) => p.achievementId)
        .toSet();
    return _achievements.where((a) => unlockedIds.contains(a.id)).toList();
  }

  /// Get locked achievements for a hero (excluding secrets)
  List<Achievement> getLockedAchievements(String heroId) {
    final heroProgress = _progress[heroId] ?? [];
    final unlockedIds = heroProgress
        .where((p) => p.isUnlocked)
        .map((p) => p.achievementId)
        .toSet();
    return _achievements
        .where((a) => !unlockedIds.contains(a.id) && !a.isSecret)
        .toList();
  }

  /// Get progress for a specific achievement
  AchievementProgress? getProgress(String heroId, String achievementId) {
    final heroProgress = _progress[heroId] ?? [];
    return heroProgress
        .where((p) => p.achievementId == achievementId)
        .firstOrNull;
  }

  /// Check if achievement is unlocked
  bool isUnlocked(String heroId, String achievementId) {
    return getProgress(heroId, achievementId)?.isUnlocked ?? false;
  }

  /// Get achievement by ID
  Achievement? getAchievement(String achievementId) {
    return _achievements.where((a) => a.id == achievementId).firstOrNull;
  }

  /// Get achievements by category
  List<Achievement> getByCategory(AchievementCategory category) {
    return _achievements.where((a) => a.category == category).toList();
  }

  // Load from storage

  Future<void> loadData() async {
    try {
      // Load achievements
      _achievements = await StorageService.loadList(
        _achievementsKey,
        Achievement.fromJson,
      );

      // Load progress
      final progressList = await StorageService.loadList(
        _progressKey,
        AchievementProgress.fromJson,
      );

      // Group by heroId
      _progress = {};
      for (final prog in progressList) {
        if (!_progress.containsKey(prog.heroId)) {
          _progress[prog.heroId] = [];
        }
        _progress[prog.heroId]!.add(prog);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AchievementProvider.loadData error: $e');
    }
  }

  /// Initialize with default achievements (if empty)
  Future<void> initialize(List<Achievement> defaultAchievements) async {
    if (_achievements.isEmpty) {
      _achievements = defaultAchievements;
      await _saveAchievements();
      notifyListeners();
    }
  }

  /// Initialize progress for a hero (creates empty progress entries)
  Future<void> initializeProgress(String heroId) async {
    if (_progress.containsKey(heroId)) return;

    _progress[heroId] = _achievements.map((a) {
      return AchievementProgress(
        id: '${heroId}_${a.id}',
        heroId: heroId,
        achievementId: a.id,
        currentProgress: 0,
        targetProgress: a.targetValue ?? 1,
      );
    }).toList();

    await _saveProgress();
    notifyListeners();
  }

  /// Check all achievements against current context and unlock any that are completed
  Future<List<Achievement>> checkAchievements(
    String heroId,
    AchievementContext context,
  ) async {
    final unlockedNow = <Achievement>[];

    // Ensure progress exists
    if (!_progress.containsKey(heroId)) {
      await initializeProgress(heroId);
    }

    final heroProgress = _progress[heroId]!;

    for (final achievement in _achievements) {
      final progIndex =
          heroProgress.indexWhere((p) => p.achievementId == achievement.id);
      if (progIndex == -1) continue;

      final prog = heroProgress[progIndex];

      // Skip already unlocked
      if (prog.isUnlocked) continue;

      // Evaluate condition and get current value
      final currentValue = _evaluateCondition(achievement.condition, context);
      final targetValue = achievement.targetValue ?? 1;

      // Update progress
      final updatedProgress = prog.copyWith(
        currentProgress: currentValue,
        targetProgress: targetValue,
      );

      // Check if completed
      if (currentValue >= targetValue) {
        // Unlock!
        heroProgress[progIndex] = updatedProgress.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          currentProgress: targetValue,
        );
        unlockedNow.add(achievement);

        // Trigger callback
        onAchievementUnlocked?.call(heroId, achievement);
      } else {
        heroProgress[progIndex] = updatedProgress;
      }
    }

    if (unlockedNow.isNotEmpty || heroProgress.isNotEmpty) {
      await _saveProgress();
      notifyListeners();
    }

    return unlockedNow;
  }

  /// Manually unlock an achievement (for special cases)
  Future<bool> unlockAchievement(String heroId, String achievementId) async {
    try {
      final achievement = getAchievement(achievementId);
      if (achievement == null) return false;

      // Ensure progress exists
      if (!_progress.containsKey(heroId)) {
        await initializeProgress(heroId);
      }

      final heroProgress = _progress[heroId]!;
      final progIndex =
          heroProgress.indexWhere((p) => p.achievementId == achievementId);

      if (progIndex == -1) return false;

      final prog = heroProgress[progIndex];
      if (prog.isUnlocked) return true; // Already unlocked

      heroProgress[progIndex] = prog.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        currentProgress: prog.targetProgress,
      );

      await _saveProgress();
      notifyListeners();

      // Trigger callback
      onAchievementUnlocked?.call(heroId, achievement);

      return true;
    } catch (e) {
      debugPrint('AchievementProvider.unlockAchievement error: $e');
      return false;
    }
  }

  /// Update progress for an achievement manually
  Future<bool> updateProgress(
    String heroId,
    String achievementId,
    int newProgress,
  ) async {
    try {
      if (!_progress.containsKey(heroId)) {
        await initializeProgress(heroId);
      }

      final heroProgress = _progress[heroId]!;
      final progIndex =
          heroProgress.indexWhere((p) => p.achievementId == achievementId);

      if (progIndex == -1) return false;

      final prog = heroProgress[progIndex];
      if (prog.isUnlocked) return true; // Already unlocked

      final updatedProgress = prog.copyWith(currentProgress: newProgress);

      // Check if completed
      if (newProgress >= prog.targetProgress) {
        heroProgress[progIndex] = updatedProgress.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          currentProgress: prog.targetProgress,
        );

        final achievement = getAchievement(achievementId);
        if (achievement != null) {
          onAchievementUnlocked?.call(heroId, achievement);
        }
      } else {
        heroProgress[progIndex] = updatedProgress;
      }

      await _saveProgress();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AchievementProvider.updateProgress error: $e');
      return false;
    }
  }

  /// Evaluate a condition string against the context
  int _evaluateCondition(String condition, AchievementContext context) {
    switch (condition) {
      case 'questsCompleted':
        return context.questsCompleted;
      case 'epicQuestsCompleted':
        return context.epicQuestsCompleted;
      case 'legendaryQuestsCompleted':
        return context.legendaryQuestsCompleted;
      case 'currentStreak':
        return context.currentStreak;
      case 'longestStreak':
        return context.longestStreak;
      case 'totalPointsEarned':
        return context.totalPointsEarned;
      case 'totalPointsSpent':
        return context.totalPointsSpent;
      case 'rewardsPurchased':
        return context.rewardsPurchased;
      case 'level':
        return context.level;
      case 'totalXP':
        return context.totalXP;
      default:
        debugPrint('Unknown achievement condition: $condition');
        return 0;
    }
  }

  // Persistence

  Future<void> _saveAchievements() async {
    await StorageService.saveList(
      _achievementsKey,
      _achievements,
      (a) => a.toJson(),
    );
  }

  Future<void> _saveProgress() async {
    final allProgress = <AchievementProgress>[];
    for (final progressList in _progress.values) {
      allProgress.addAll(progressList);
    }
    await StorageService.saveList(
      _progressKey,
      allProgress,
      (p) => p.toJson(),
    );
  }

  /// Get total unlocked count for a hero
  int getUnlockedCount(String heroId) {
    final heroProgress = _progress[heroId] ?? [];
    return heroProgress.where((p) => p.isUnlocked).length;
  }

  /// Get total achievements count
  int get totalCount => _achievements.length;

  /// Get completion percentage for a hero
  double getCompletionPercent(String heroId) {
    if (_achievements.isEmpty) return 0;
    return getUnlockedCount(heroId) / _achievements.length;
  }
}
