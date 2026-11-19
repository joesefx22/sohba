import 'package:flutter/material.dart';

/// Sohba — Midnight Royal visual identity.
/// Semantic names are preserved so existing screens keep compiling.
class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFF080D24);
  static const backgroundSecondary = Color(0xFF0D1531);
  static const surface = Color(0xFF141D3D);
  static const surfaceElevated = Color(0xFF1B2348);

  // Brand accents
  static const emerald = Color(0xFF20C997);
  static const mint = Color(0xFF65E6C2);
  static const gold = Color(0xFFE9B95E);
  static const goldBright = Color(0xFFFFD98C);
  static const iman = Color(0xFF9C8AE8);

  // Feedback
  static const success = Color(0xFF9AE6C5);
  static const error = Color(0xFFE47783);
  static const warning = Color(0xFFF0B96A);
  static const streak = Color(0xFFFF9B50);

  // Text
  static const text = Color(0xFFF8F5FF);
  static const textSecondary = Color(0xFFB8B7CC);

  // Rarity
  static const rarityCommon = Color(0xFFB8B8C8);
  static const rarityRare = Color(0xFF66BDEB);
  static const rarityEpic = Color(0xFFAA83E8);
  static const rarityLegendary = gold;

  // Gradients
  static const progressGradient = LinearGradient(
    colors: [gold, goldBright],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFB77A2D), goldBright, Color(0xFFE9B95E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const backgroundLinearGradient = LinearGradient(
    colors: [Color(0xFF070B1D), background, Color(0xFF10152F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy aliases — retained for older screens.
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
  static const List<Color> backgroundGradient = [
    background,
    backgroundSecondary,
  ];
  @Deprecated('Use AppColors.progressGradient')
  static LinearGradient get primaryLinearGradient => progressGradient;
  @Deprecated('Use AppColors.goldGradient')
  static LinearGradient get goldLinearGradient => goldGradient;

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