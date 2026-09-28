import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Service for level and XP calculations
///
/// XP Formula: Each level requires 100 + (level-1) * 50 XP
/// - Level 1→2: 100 XP
/// - Level 2→3: 150 XP
/// - Level 3→4: 200 XP
/// - etc.
class LevelService {
  LevelService._();

  /// Color associated with the level tier.
  static Color colorForLevel(int level) {
    if (level <= 10) return AppColors.teal;
    if (level <= 25) return AppColors.rarityRare;
    if (level <= 50) return AppColors.rarityEpic;
    return AppColors.rarityLegendary;
  }

  /// XP required to go from [level] to [level + 1]
  static int xpBetweenLevels(int level) {
    return 100 + (level - 1) * 50;
  }

  /// Total cumulative XP required to reach [level] from level 1
  static int xpForLevel(int level) {
    if (level <= 1) return 0;

    // Sum of arithmetic sequence: 100 + 150 + 200 + ... + (100 + (level-2)*50)
    // = n * (first + last) / 2
    // where n = level - 1, first = 100, last = 100 + (level-2)*50
    final n = level - 1;
    final first = 100;
    final last = 100 + (level - 2) * 50;
    return n * (first + last) ~/ 2;
  }

  /// Calculate level based on total XP
  static int levelForXP(int totalXP) {
    if (totalXP <= 0) return 1;

    int level = 1;
    int cumulativeXP = 0;

    while (true) {
      final xpNeeded = xpBetweenLevels(level);
      if (cumulativeXP + xpNeeded > totalXP) {
        break;
      }
      cumulativeXP += xpNeeded;
      level++;
    }

    return level;
  }

  /// Progress to next level as a value between 0.0 and 1.0
  static double progressToNextLevel(int totalXP) {
    final currentLevel = levelForXP(totalXP);
    final xpAtCurrentLevel = xpForLevel(currentLevel);
    final xpToNextLevel = xpBetweenLevels(currentLevel);
    final xpIntoCurrentLevel = totalXP - xpAtCurrentLevel;

    return xpIntoCurrentLevel / xpToNextLevel;
  }

  /// XP remaining in current level (after subtracting previous levels)
  static int currentLevelXP(int totalXP) {
    final currentLevel = levelForXP(totalXP);
    final xpAtCurrentLevel = xpForLevel(currentLevel);
    return totalXP - xpAtCurrentLevel;
  }

  /// Title based on level
  static String titleForLevel(int level) {
    if (level <= 10) return 'Mochi Novice';
    if (level <= 25) return 'Mochi Apprentice';
    if (level <= 50) return 'Mochi Champion';
    return 'Mochi Legend';
  }

  /// Get level info as a formatted string
  static String levelInfo(int level) {
    final title = titleForLevel(level);
    return 'Level $level - $title';
  }

  /// Calculate how many levels gained from adding XP
  static int levelsGained(int currentTotalXP, int xpToAdd) {
    final currentLevel = levelForXP(currentTotalXP);
    final newLevel = levelForXP(currentTotalXP + xpToAdd);
    return newLevel - currentLevel;
  }

  /// Check if adding XP would cause a level up
  static bool wouldLevelUp(int currentTotalXP, int xpToAdd) {
    return levelsGained(currentTotalXP, xpToAdd) > 0;
  }
}
