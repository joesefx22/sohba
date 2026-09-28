import 'package:flutter/material.dart';

/// App color palette for the Mochi Points gaming theme.
class AppColors {
  AppColors._();

  // Primary Gradient (Coral to Orange)
  static const Color primaryStart = Color(0xFFFF6B6B);
  static const Color primaryEnd = Color(0xFFFF8E53);
  static const List<Color> primaryGradient = [primaryStart, primaryEnd];

  // Background Gradient (Dark)
  static const Color backgroundStart = Color(0xFF1A1B2E);
  static const Color backgroundEnd = Color(0xFF2D2E4A);
  static const List<Color> backgroundGradient = [backgroundStart, backgroundEnd];

  // Surface Colors
  static const Color surface = Color(0xFF2A2B42);
  static const Color surfaceElevated = Color(0xFF3A3B52);

  // Accent Colors
  static const Color gold = Color(0xFFFFE66D);
  static const Color teal = Color(0xFF4ECDC4);

  // Text Colors
  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C8);

  // Rarity Colors
  static const Color rarityCommon = Color(0xFFB8B8B8);
  static const Color rarityRare = Color(0xFF4A9DFF);
  static const Color rarityEpic = Color(0xFFA855F7);
  static const Color rarityLegendary = Color(0xFFF59E0B);

  // Semantic Colors
  static const Color success = teal;
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Gradient Helpers
  static LinearGradient get primaryLinearGradient => const LinearGradient(
        colors: primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get backgroundLinearGradient => const LinearGradient(
        colors: backgroundGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  /// Returns the color for a given rarity string.
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return rarityLegendary;
      case 'epic':
        return rarityEpic;
      case 'rare':
        return rarityRare;
      case 'common':
      default:
        return rarityCommon;
    }
  }
}
