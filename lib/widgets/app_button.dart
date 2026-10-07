import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import 'press_scale.dart';

enum AppButtonStyle { primary, secondary, gold }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.expand = true,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
  });

  // ── Legacy factories (backwards compatible) ───────────────────
  factory AppButton.primary({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool expanded = true,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isLoading = false,
  }) =>
      AppButton(
        label: label,
        onPressed: onPressed,
        style: AppButtonStyle.primary,
        icon: icon,
        expand: expanded,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        isLoading: isLoading,
      );

  factory AppButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool expanded = true,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isLoading = false,
  }) =>
      AppButton(
        label: label,
        onPressed: onPressed,
        style: AppButtonStyle.secondary,
        icon: icon,
        expand: expanded,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        isLoading: isLoading,
      );

  factory AppButton.gold({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool expanded = true,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isLoading = false,
  }) =>
      AppButton(
        label: label,
        onPressed: onPressed,
        style: AppButtonStyle.gold,
        icon: icon,
        expand: expanded,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        isLoading: isLoading,
      );

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;
  final bool expand;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    // ── Default palette per style ─────────────────────────────────
    Gradient? bg;
    Color fg;
    Color? border;

    switch (style) {
      case AppButtonStyle.primary:
        bg = AppColors.progressGradient;
        fg = AppColors.background;
        border = null;
      case AppButtonStyle.gold:
        bg = AppColors.goldGradient;
        fg = AppColors.background;
        border = null;
      case AppButtonStyle.secondary:
        bg = null;
        fg = AppColors.mint;
        border = AppColors.emerald.withValues(alpha: 0.4);
    }

    // ── Apply overrides ───────────────────────────────────────────
    // Solid backgroundColor overrides the gradient entirely.
    if (backgroundColor != null) {
      bg = null;
    }
    if (foregroundColor != null) {
      fg = foregroundColor!;
    }

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: PressScale(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onPressed!();
              }
            : null,
        child: Container(
          height: 52,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: bg,
            color: backgroundColor ??
                (bg == null ? Colors.transparent : null),
            borderRadius: BorderRadius.circular(16),
            border: border == null ? null : Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (icon != null) ...[
                Icon(icon, color: fg, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppText.section.copyWith(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small inline icon button.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: size),
        color: color ?? AppColors.textSecondary,
        onPressed: onPressed != null
            ? () {
                HapticFeedback.selectionClick();
                onPressed!();
              }
            : null,
      );
}