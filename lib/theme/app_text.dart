import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Sohba — Typography scale (SINGLE SOURCE OF TRUTH).
///
/// All text styles in the app must use these. Do not define `AppText`
/// anywhere else — `app_theme.dart` re-exports this file for convenience.
class AppText {
  AppText._();

  /// Arabic font — loaded via google_fonts (no asset needed).
  static TextStyle _f(TextStyle s) => GoogleFonts.tajawal(textStyle: s);

  static const _tabular = [FontFeature.tabularFigures()];

  // ============================================
  // HEADINGS
  // ============================================

  /// Main page title (e.g. "الصلاة", "الأذكار").
  static final TextStyle heading = _f(const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.text,
  ));

  /// Section title inside a page.
  static final TextStyle section = _f(const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.text,
  ));

  /// Sub-section title (inside cards).
  static final TextStyle subtitle = _f(const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.text,
  ));

  // ============================================
  // BODY
  // ============================================

  /// Primary body text.
  static final TextStyle body = _f(const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.text,
  ));

  /// Secondary / caption text.
  static final TextStyle caption = _f(const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  ));

  /// Very small labels (badges, chips).
  static final TextStyle label = _f(const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textSecondary,
  ));

  // ============================================
  // NUMBERS / STATS
  // ============================================

  /// Large number (e.g. Iman balance).
  static final TextStyle numberLarge = _f(const TextStyle(
    fontSize: 46,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AppColors.text,
    fontFeatures: _tabular,
  ));

  /// Medium number.
  static final TextStyle numberMedium = _f(const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.text,
    fontFeatures: _tabular,
  ));

  /// Small number (small stat cards).
  static final TextStyle numberSmall = _f(const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    fontFeatures: _tabular,
  ));

  /// Hero number — aliases `numberLarge` for backward compatibility.
  static TextStyle get number => numberLarge;

  // ============================================
  // SPECIAL
  // ============================================

  /// Invite code / keys (wide letter spacing).
  static final TextStyle code = _f(const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.gold,
    letterSpacing: 6,
    height: 1.2,
  ));

  /// Primary button label.
  static final TextStyle button = _f(const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  ));
}