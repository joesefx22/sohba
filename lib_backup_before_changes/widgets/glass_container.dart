import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// normal      -> most content. Faint fill, near-invisible border, no blur (cheap).
/// featured    -> current prayer / Iman. Soft glow + light blur.
/// celebration -> badge / milestone. Stronger glow.
enum GlassLevel { normal, featured, celebration }

/// Backwards compatible: `blur`, `tintColor`, `borderRadius`, `padding`,
/// `margin` behave as before. New: `level`, `accent`, `onTap`.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.level = GlassLevel.normal,
    this.blur,
    this.tintColor,
    this.accent,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final GlassLevel level;

  /// Overrides the level's default blur sigma.
  final double? blur;
  final Color? tintColor;

  /// Glow/border color for featured & celebration. Default: emerald.
  final Color? accent;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glow = accent ?? AppColors.emerald;
    final radius = BorderRadius.circular(borderRadius);

    double sigma;
    Color tint;
    Color border;
    List<BoxShadow> shadows;

    switch (level) {
      case GlassLevel.normal:
        sigma = 0;
        tint = AppColors.surface.withAlpha(184);
        border = Colors.white.withAlpha(13);
        shadows = const [];
        break;
      case GlassLevel.featured:
        sigma = 12;
        tint = AppColors.surfaceElevated.withAlpha(200);
        border = glow.withAlpha(46);
        shadows = [
          BoxShadow(color: glow.withAlpha(46), blurRadius: 24, spreadRadius: -2)
        ];
        break;
      case GlassLevel.celebration:
        sigma = 16;
        tint = AppColors.surfaceElevated.withAlpha(217);
        border = glow.withAlpha(90);
        shadows = [
          BoxShadow(color: glow.withAlpha(90), blurRadius: 40, spreadRadius: 2)
        ];
        break;
    }
    sigma = blur ?? sigma;
    tint = tintColor ?? tint;

    Widget inner = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    if (onTap != null) {
      inner = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: inner),
      );
    }

    Widget surface = Container(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: radius,
        border: Border.all(color: border),
      ),
      child: inner,
    );

    if (sigma > 0) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: surface,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: RepaintBoundary(child: surface),
      ),
    );
  }
}