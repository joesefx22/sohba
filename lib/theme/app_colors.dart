import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================
  // Backgrounds — أخضر ليلي
  // ============================================
  static const background          = Color(0xFF0C211C);
  static const backgroundSecondary = Color(0xFF0F2822);
  static const surface             = Color(0xFF18372D);
  static const surfaceElevated     = Color(0xFF21463A);

  // ============================================
  // Brand
  // ============================================
  static const emerald    = Color(0xFF3DB884);  // CTA/primary
  static const mint       = Color(0xFF6DE7B0);  // icons/spinners
  static const gold       = Color(0xFFE6C878);  // achievement
  static const goldBright = Color(0xFFF5DDA0);
  static const iman       = Color(0xFF5DD6D0);

  // ============================================
  // Feedback
  // ============================================
  static const success = Color(0xFFD7EEE1);  // نعناعي — success text
  static const error   = Color(0xFFD96B6B);
  static const warning = Color(0xFFE0A458);
  static const streak  = Color(0xFFE88B4D);

  // ============================================
  // Text
  // ============================================
  static const text          = Color(0xFFF5F7F4);
  static const textSecondary = Color(0xFF9EAEA7);

  // ============================================
  // Rarity
  // ============================================
  static const rarityCommon    = Color(0xFFB8B8B8);
  static const rarityRare      = Color(0xFF5B9BD5);
  static const rarityEpic      = Color(0xFF9B7BD5);
  static const rarityLegendary = gold;

  // ============================================
  // Gradients
  // ============================================
  static const progressGradient = LinearGradient(colors: [emerald, mint]);
  static const goldGradient     = LinearGradient(colors: [gold, goldBright]);
  static const backgroundLinearGradient = LinearGradient(
    colors: [background, backgroundSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================
  // Legacy aliases
  // ============================================
  @Deprecated('Use AppColors.emerald')
  static const Color primaryStart = emerald;
  @Deprecated('Use AppColors.mint')
  static const Color primaryEnd = mint;
  @Deprecated('Use AppColors.mint')
  static const Color teal = mint;
  @Deprecated('Use AppColors.emerald')
  static const Color successOld = emerald;
  @Deprecated('Use AppColors.background')
  static const Color backgroundStart = background;
  @Deprecated('Use AppColors.backgroundSecondary')
  static const Color backgroundEnd = backgroundSecondary;
  @Deprecated('Use AppColors.iman')
  static const Color rarityRareAlias = iman;
  @Deprecated('Use AppColors.progressGradient.colors')
  static const List<Color> primaryGradient = [emerald, mint];
  @Deprecated('Use AppColors.backgroundLinearGradient.colors')
  static const List<Color> backgroundGradient = [background, backgroundSecondary];
  @Deprecated('Use AppColors.progressGradient')
  static LinearGradient get primaryLinearGradient => progressGradient;
  @Deprecated('Use AppColors.goldGradient')
  static LinearGradient get goldLinearGradient => goldGradient;

  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary': return rarityLegendary;
      case 'epic':      return rarityEpic;
      case 'rare':      return rarityRare;
      default:          return rarityCommon;
    }
  }
}