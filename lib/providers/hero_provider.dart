import 'package:flutter/foundation.dart';
import '../models/hero.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';

typedef LevelUpCallback = void Function(String userId, int oldLevel, int newLevel);
typedef StreakMilestoneCallback = void Function(String userId, int milestone);
typedef StreakLostCallback = void Function(String userId, int previousStreak);

class HeroProvider extends ChangeNotifier {
  Map<String, Hero> _heroes = {};
  String? _currentUserId;

  Map<String, Hero> get heroes => Map.unmodifiable(_heroes);

  static const String _heroesKey = 'heroes';

  // Callbacks
  LevelUpCallback? onLevelUp;
  StreakMilestoneCallback? onStreakMilestone;
  StreakLostCallback? onStreakLost;

  // Getters
  Hero? get currentHero {
    if (_currentUserId == null) return null;
    return _heroes[_currentUserId];
  }

  Hero? heroForUser(String userId) => _heroes[userId];

  // Set current user (called when user logs in)
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  // Load from storage
  Future<void> loadData() async {
    try {
      final heroesList = await StorageService.loadList(
        _heroesKey,
        Hero.fromJson,
      );
      _heroes = {for (var hero in heroesList) hero.userId: hero};
      notifyListeners();
    } catch (e) {
      debugPrint('HeroProvider.loadData error: $e');
    }
  }

  // Initialize hero for user
  Future<Hero> initialize(String userId, String name) async {
    if (_heroes.containsKey(userId)) {
      return _heroes[userId]!;
    }

    final hero = Hero(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      level: 1,
      currentXP: 0,
      xpToNextLevel: Hero.calculateXPForLevel(1),
      appearance: const HeroAppearance(
        baseAvatar: 'default',
        skinColor: 'light',
        hairStyle: 'short',
        hairColor: 'brown',
        outfit: 'casual',
      ),
    );

    _heroes[userId] = hero;
    await _saveHeroes();
    notifyListeners();

    return hero;
  }

  // Add XP and check for level up
  Future<bool> addXP(String userId, int amount) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      final oldLevel = hero.level;
      final updatedHero = hero.addXP(amount);
      _heroes[userId] = updatedHero;

      // Check for level up
      if (updatedHero.level > oldLevel) {
        onLevelUp?.call(userId, oldLevel, updatedHero.level);
      }

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.addXP error: $e');
      return false;
    }
  }

  /// Record activity for today and update streak
  ///
  /// This is the main method to call when a user completes an action.
  /// Returns true if activity was recorded (false if already recorded today).
  Future<bool> recordActivity(String userId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if already recorded today
      if (StreakService.hasActivityToday(hero.lastActiveDate)) {
        return false; // Already recorded
      }

      // Check if streak was lost before recording new activity
      final oldStreak = hero.currentStreak;
      final wasActive = StreakService.isStreakActive(hero.lastActiveDate);

      // Add today to activity dates
      final updatedDates = [...hero.activityDates, today];

      // Calculate new streak
      final newStreak = StreakService.calculateStreak(updatedDates);
      final newLongestStreak =
          newStreak > hero.longestStreak ? newStreak : hero.longestStreak;

      // Update hero
      _heroes[userId] = hero.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        lastActiveDate: now,
        activityDates: updatedDates,
      );

      await _saveHeroes();
      notifyListeners();

      // Check for streak lost (had streak, but it was broken)
      if (wasActive == false && oldStreak > 0) {
        onStreakLost?.call(userId, oldStreak);
      }

      // Check for milestone
      final milestone = StreakService.checkStreakMilestone(oldStreak, newStreak);
      if (milestone != null) {
        onStreakMilestone?.call(userId, milestone);
      }

      return true;
    } catch (e) {
      debugPrint('HeroProvider.recordActivity error: $e');
      return false;
    }
  }

  /// Check and update streak status without recording new activity
  ///
  /// Call this on app start to detect if streak was lost while away.
  Future<void> checkStreak(String userId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return;

      final wasActive = StreakService.isStreakActive(hero.lastActiveDate);

      if (!wasActive && hero.currentStreak > 0) {
        // Streak was lost while away
        final lostStreak = hero.currentStreak;

        _heroes[userId] = hero.copyWith(
          currentStreak: 0,
        );

        await _saveHeroes();
        notifyListeners();

        onStreakLost?.call(userId, lostStreak);
      }
    } catch (e) {
      debugPrint('HeroProvider.checkStreak error: $e');
    }
  }

  /// Legacy method - calls recordActivity internally
  @Deprecated('Use recordActivity instead')
  Future<bool> updateStreak(String userId) async {
    return recordActivity(userId);
  }

  /// Get streak bonus multiplier for a user
  double getStreakBonus(String userId) {
    final hero = _heroes[userId];
    if (hero == null) return 1.0;
    return StreakService.streakBonusMultiplier(hero.currentStreak);
  }

  /// Get streak bonus as percentage for display
  int getStreakBonusPercent(String userId) {
    final hero = _heroes[userId];
    if (hero == null) return 0;
    return StreakService.streakBonusPercent(hero.currentStreak);
  }

  // Equip item
  Future<bool> equipItem(String userId, String itemId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      // Check if item is unlocked
      if (!hero.unlockedItems.contains(itemId)) return false;

      // Check if already equipped
      if (hero.equippedItems.contains(itemId)) return true;

      final updatedItems = [...hero.equippedItems, itemId];
      _heroes[userId] = hero.copyWith(equippedItems: updatedItems);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.equipItem error: $e');
      return false;
    }
  }

  // Unequip item
  Future<bool> unequipItem(String userId, String itemId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      if (!hero.equippedItems.contains(itemId)) return true;

      final updatedItems = hero.equippedItems.where((i) => i != itemId).toList();
      _heroes[userId] = hero.copyWith(equippedItems: updatedItems);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.unequipItem error: $e');
      return false;
    }
  }

  // Unlock item
  Future<bool> unlockItem(String userId, String itemId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      if (hero.unlockedItems.contains(itemId)) return true;

      final updatedItems = [...hero.unlockedItems, itemId];
      _heroes[userId] = hero.copyWith(unlockedItems: updatedItems);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.unlockItem error: $e');
      return false;
    }
  }

  // Add badge
  Future<bool> addBadge(String userId, String badgeId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      if (hero.badges.contains(badgeId)) return true;

      final updatedBadges = [...hero.badges, badgeId];
      _heroes[userId] = hero.copyWith(badges: updatedBadges);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.addBadge error: $e');
      return false;
    }
  }

  // Update hero name and/or appearance
  Future<bool> updateHero(String userId, {String? name, HeroAppearance? appearance}) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      _heroes[userId] = hero.copyWith(
        name: name,
        appearance: appearance,
      );

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.updateHero error: $e');
      return false;
    }
  }

  // Update appearance
  Future<bool> updateAppearance(String userId, HeroAppearance appearance) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      _heroes[userId] = hero.copyWith(appearance: appearance);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.updateAppearance error: $e');
      return false;
    }
  }

  // Persistence
  Future<void> _saveHeroes() async {
    await StorageService.saveList(
      _heroesKey,
      _heroes.values.toList(),
      (h) => h.toJson(),
    );
  }
}
