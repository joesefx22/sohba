import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Smoothly counts from the previous value to the new one (Iman 42.7 -> 42.97,
/// Hasanat totals). Purely presentational: feed it the value from your provider.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    this.decimals = 1,
    this.style,
    this.suffix = '',
  });

  final double value;
  final int decimals;

  /// Optional override. Defaults to [AppText.number] if omitted.
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final d = AppMotion.reduced(context) ? Duration.zero : AppMotion.number;
    final effectiveStyle = style ??
        const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
          height: 1.2,
        );

    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: d,
      curve: AppMotion.curve,
      builder: (_, v, _) => Text(
        '${v.toStringAsFixed(decimals)}$suffix',
        style: effectiveStyle,
      ),
    );
  }
}