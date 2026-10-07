import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type scale: Heading 24-28 Bold / Section 17-19 SemiBold /
/// Body 14-16 Regular / Caption 11-13 Medium / Numbers: tabular + heavier.
class AppText {
  AppText._();

  /// Arabic font family. Loaded via google_fonts (no asset needed).
  static TextStyle _f(TextStyle s) => GoogleFonts.tajawal(textStyle: s);

  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle get heading => _f(const TextStyle(
      fontSize: 26, fontWeight: FontWeight.w700,
      height: 1.3, color: AppColors.text));
  static TextStyle get section => _f(const TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600,
      height: 1.35, color: AppColors.text));
  static TextStyle get body => _f(const TextStyle(
      fontSize: 15, fontWeight: FontWeight.w400,
      height: 1.5, color: AppColors.text));
  static TextStyle get caption => _f(const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w500,
      height: 1.4, color: AppColors.textSecondary));
  static TextStyle get number => _f(const TextStyle(
      fontSize: 44, fontWeight: FontWeight.w800,
      height: 1.1, color: AppColors.text, fontFeatures: _tabular));
  static TextStyle get numberSmall => _f(const TextStyle(
      fontSize: 20, fontWeight: FontWeight.w700,
      color: AppColors.text, fontFeatures: _tabular));
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary:   AppColors.emerald,
      secondary: AppColors.gold,
      tertiary:  AppColors.iman,
      surface:   AppColors.surface,
      error:     AppColors.error,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        headlineMedium: AppText.heading,
        titleMedium:    AppText.section,
        bodyMedium:     AppText.body,
        bodySmall:      AppText.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppText.section,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        indicatorColor: AppColors.emerald.withOpacity(0.16),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => AppText.caption
            .copyWith(
                color: s.contains(WidgetState.selected)
                    ? AppColors.mint
                    : AppColors.textSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors.mint
                : AppColors.textSecondary)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppText.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.error.withOpacity(0.7))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.emerald)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}