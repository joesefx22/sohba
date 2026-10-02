import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Iman progress bar — Islamic-themed replacement for XP bar.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withAlpha(102)),
              ),
              child: Text(
                'المستوى $level',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ),
            Text(
              '${currentIman.toStringAsFixed(1)} / ${nextTierAt.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _progress),
          duration: animated
              ? const Duration(milliseconds: 800)
              : Duration.zero,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(90),
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(color: AppColors.gold.withAlpha(60)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryStart, AppColors.teal],
                          ),
                          borderRadius: BorderRadius.circular(height / 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withAlpha(150),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}