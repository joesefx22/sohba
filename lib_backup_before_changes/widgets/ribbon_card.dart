import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Premium card with diagonal flowing-ribbon signature.
///
/// Used across the app for consistent "Midnight Royal" look.
/// Backwards compatible with `GlassContainer` usage patterns:
/// supports `margin`, `padding`, `onTap`, and `tintColor`.
class RibbonCard extends StatelessWidget {
  const RibbonCard({
    super.key,
    required this.child,
    this.accent = AppColors.gold,
    this.radius = 22,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.tintColor,
    this.onTap,
  });

  final Widget child;
  final Color accent;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Optional solid base tint (e.g. highlight "me" in leaderboard).
  /// When set, replaces the default dark navy gradient base.
  final Color? tintColor;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColors = tintColor != null
        ? <Color>[
            tintColor!,
            Color.lerp(tintColor!, const Color(0xFF111A39), 0.55)!,
            accent.withValues(alpha: .09),
          ]
        : <Color>[
            const Color(0xFF1B2348),
            const Color(0xFF111A39),
            accent.withValues(alpha: .09),
          ];

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bgColors,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: DiagonalRibbonPainter(accent: accent),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent.withValues(alpha: .45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .12),
            blurRadius: 22,
            spreadRadius: -5,
          ),
          const BoxShadow(
            color: Color(0x66030716),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: content,
              ),
      ),
    );
  }
}

class DiagonalRibbonPainter extends CustomPainter {
  const DiagonalRibbonPainter({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ribbon = Path()
      ..moveTo(w * .60, h * 1.08)
      ..cubicTo(w * .76, h * .88, w * .81, h * .70, w * 1.08, h * .56)
      ..lineTo(w * 1.08, h * .80)
      ..cubicTo(w * .89, h * .91, w * .86, h * 1.03, w * .70, h * 1.08)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: .02),
          accent.withValues(alpha: .17),
          AppColors.goldBright.withValues(alpha: .25),
          accent.withValues(alpha: .035),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Offset.zero & size);
    canvas.drawPath(ribbon, paint);

    final highlight = Path()
      ..moveTo(w * .55, h * 1.01)
      ..cubicTo(w * .72, h * .84, w * .84, h * .70, w * 1.04, h * .59);
    canvas.drawPath(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..shader = LinearGradient(
          colors: [
            accent.withValues(alpha: .05),
            AppColors.goldBright.withValues(alpha: .65),
            accent.withValues(alpha: .12),
          ],
        ).createShader(Offset.zero & size),
    );

    final second = Path()
      ..moveTo(w * .74, h * 1.04)
      ..cubicTo(w * .86, h * .91, w * .91, h * .80, w * 1.05, h * .75);
    canvas.drawPath(
      second,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = accent.withValues(alpha: .25),
    );

    final counter = Path()
      ..moveTo(-w * .06, h * .80)
      ..cubicTo(w * .10, h * .65, w * .15, h * .60, w * .25, h * .54);
    canvas.drawPath(
      counter,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65
        ..color = accent.withValues(alpha: .10),
    );
  }

  @override
  bool shouldRepaint(covariant DiagonalRibbonPainter oldDelegate) =>
      oldDelegate.accent != accent;
}