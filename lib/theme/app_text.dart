import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Sohba — Typography scale
///
/// كل النصوص في التطبيق تستخدم هذه الـ styles بدل TextStyle الخام،
/// لضمان تجانس الأحجام والألوان في كل الشاشات.
class AppText {
  AppText._();

  // ============================================
  // HEADINGS
  // ============================================

  /// العنوان الرئيسي للصفحة (مثلاً: "الصلاة", "الأذكار", "الميداليات").
  static const TextStyle heading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.3,
  );

  /// عنوان قسم داخل الصفحة (مثلاً: "صلوات اليوم", "الأعضاء").
  static const TextStyle section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.3,
  );

  /// عنوان فرعي أصغر (مثلاً داخل الكروت).
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
  );

  // ============================================
  // BODY
  // ============================================

  /// النص الأساسي.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
    height: 1.5,
  );

  /// نص ثانوي / وصف تحت العناصر.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// نص صغير جدًا (badges، labels).
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // ============================================
  // NUMBERS / STATS
  // ============================================

  /// رقم كبير للعرض (مثلاً رصيد الإيمان).
  static const TextStyle numberLarge = TextStyle(
    fontSize: 46,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.1,
  );

  /// رقم متوسط (في كروت الإحصائيات).
  static const TextStyle numberMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.2,
  );

  /// رقم صغير (في stat cards الصغيرة).
  static const TextStyle numberSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.2,
  );

  // ============================================
  // SPECIAL
  // ============================================

  /// أرقام الكود/الدعوة (letterSpacing واسع).
  static const TextStyle code = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.gold,
    letterSpacing: 6,
    height: 1.2,
  );

  /// نص الزر الأساسي.
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}