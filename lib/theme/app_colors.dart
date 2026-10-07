import 'package:flutter/material.dart';

/// Sohba design tokens.
/// Gold = important things only (not every icon/number).
class AppColors {
  AppColors._();

  // ============================================
  // Backgrounds & surfaces
  // ============================================
  static const background          = Color(0xFF071612);
  static const backgroundSecondary = Color(0xFF0B211A);
  static const surface             = Color(0xFF102A21);
  static const surfaceElevated     = Color(0xFF15352A);

  // ============================================
  // Brand
  // ============================================
  static const emerald    = Color(0xFF35C98A);
  static const mint       = Color(0xFF6DE7B0);
  static const gold       = Color(0xFFD8B65A);
  static const goldBright = Color(0xFFF0D37A);
  static const iman       = Color(0xFF5DD6D0);

  // ============================================
  // Text
  // ============================================
  static const text          = Color(0xFFF5F7F4);
  static const textSecondary = Color(0xFF9EAEA7);

  // ============================================
  // Feedback
  // ============================================
  static const error   = Color(0xFFD96B6B);
  static const warning = Color(0xFFE0A458);
  static const streak  = Color(0xFFE88B4D);

  // ============================================
  // Rarity — badges only
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
  // 🔻 BACKWARD-COMPAT ALIASES (deprecated)
  // ============================================
  // Legacy code still uses these; remove once all callers migrate.

  @Deprecated('Use AppColors.emerald instead')
  static const Color primaryStart = emerald;

  @Deprecated('Use AppColors.mint instead')
  static const Color primaryEnd = mint;

  @Deprecated('Use AppColors.mint instead')
  static const Color teal = mint;

  @Deprecated('Use AppColors.emerald instead')
  static const Color success = emerald;

  @Deprecated('Use AppColors.background instead')
  static const Color backgroundStart = background;

  @Deprecated('Use AppColors.backgroundSecondary instead')
  static const Color backgroundEnd = backgroundSecondary;

  @Deprecated('Use AppColors.iman instead')
  static const Color rarityRareAlias = iman;

  @Deprecated('Use AppColors.progressGradient.colors instead')
  static const List<Color> primaryGradient = [emerald, mint];

  @Deprecated('Use AppColors.backgroundLinearGradient.colors instead')
  static const List<Color> backgroundGradient = [background, backgroundSecondary];

  @Deprecated('Use AppColors.progressGradient instead')
  static LinearGradient get primaryLinearGradient => progressGradient;

  @Deprecated('Use AppColors.goldGradient instead')
  static LinearGradient get goldLinearGradient => goldGradient;

  // ============================================
  // Helpers
  // ============================================
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary': return rarityLegendary;
      case 'epic':      return rarityEpic;
      case 'rare':      return rarityRare;
      default:          return rarityCommon;
    }
  }
}