import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Iman progress bar. API and visible texts unchanged (tests keep working);
/// only styling changed: emerald -> mint fill with a very soft glow.
class ImanProgressBar extends StatelessWidget {
  final double currentIman;
  final double nextTierAt;
  final int level;
  final bool animated;
  final double height;

  const ImanProgressBar({
    super.key,
    required this.currentIman,
    required this.nextTierAt,
    required this.level,
    this.animated = true,
    this.height = 12,
  });

  double get _progress {
    if (nextTierAt <= 0) return 0;
    return (currentIman / nextTierAt).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final instant = !animated || AppMotion.reduced(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'المستوى $level',
                style: AppText.caption.copyWith(
                    color: AppColors.mint, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${currentIman.toStringAsFixed(1)} / ${nextTierAt.toStringAsFixed(0)}',
              style: AppText.caption
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _progress),
          duration: instant ? Duration.zero : const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(color: Colors.white.withAlpha(13)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.progressGradient,
                        borderRadius: BorderRadius.circular(height / 2),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.emerald.withAlpha(80),
                              blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}