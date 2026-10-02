import 'package:flutter/material.dart';

/// Sohba — Islamic-themed color palette
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY — Deep Islamic Green
  // ============================================
  static const Color primaryStart = Color(0xFF198754);
  static const Color primaryEnd = Color(0xFF0F5132);
  static const List<Color> primaryGradient = [primaryStart, primaryEnd];

  // ============================================
  // BACKGROUND — Dark green-teal
  // ============================================
  static const Color backgroundStart = Color(0xFF0A1F1A);
  static const Color backgroundEnd = Color(0xFF142B25);
  static const List<Color> backgroundGradient = [backgroundStart, backgroundEnd];

  // ============================================
  // SURFACE
  // ============================================
  static const Color surface = Color(0xFF1E3A32);
  static const Color surfaceElevated = Color(0xFF2A4A40);

  // ============================================
  // ACCENT — Traditional Gold
  // ============================================
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldBright = Color(0xFFF4D03F);

  // ============================================
  // TEXT
  // ============================================
  static const Color text = Color(0xFFF5F5F0);
  static const Color textSecondary = Color(0xFFA8B5B0);

  // ============================================
  // RARITY (mapped to spiritual significance)
  // ============================================
  static const Color rarityCommon = Color(0xFFB8B8B8);
  static const Color rarityRare = Color(0xFF4A9DFF);
  static const Color rarityEpic = Color(0xFFA855F7);
  static const Color rarityLegendary = Color(0xFFD4AF37);

  // ============================================
  // SEMANTIC
  // ============================================
  static const Color teal = Color(0xFF2ECC71);
  static const Color success = Color(0xFF198754);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ============================================
  // GRADIENTS
  // ============================================
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

  static LinearGradient get goldLinearGradient => const LinearGradient(
        colors: [goldBright, gold],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return rarityLegendary;
      case 'epic':
        return rarityEpic;
      case 'rare':
        return rarityRare;
      default:
        return rarityCommon;
    }
  }
}