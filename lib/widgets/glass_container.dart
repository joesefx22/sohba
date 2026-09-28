import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A frosted-glass card widget that applies a blur effect over its background.
///
/// Drop-in replacement for `Container`/`Card` patterns used throughout the app.
/// Requires an ancestor with visual content behind it (e.g. a background image)
/// for the blur effect to be visible.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.tintColor,
    this.borderRadius = 16,
    this.padding,
    this.margin,
  });

  final Widget child;

  /// Blur sigma for the frosted glass effect.
  final double blur;

  /// Tint color overlaid on the blurred area.
  /// Defaults to [AppColors.surface] at 50% opacity.
  final Color? tintColor;

  /// Border radius for the glass card.
  final double borderRadius;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tint = tintColor ?? AppColors.surface.withAlpha(77);
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                color: tint,
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withAlpha(26),
                ),
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
