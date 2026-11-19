import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared Midnight Royal background used by the main app shell.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundLinearGradient,
              ),
            ),
          ),
          Positioned(
            top: -130,
            right: -105,
            child: IgnorePointer(
              child: _AmbientGlow(
                size: 340,
                color: const Color(0xFF7652C8),
              ),
            ),
          ),
          Positioned(
            top: 390,
            left: -150,
            child: IgnorePointer(
              child: _AmbientGlow(
                size: 300,
                color: AppColors.gold,
                opacity: 0.055,
              ),
            ),
          ),
          SafeArea(child: body),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
    this.opacity = 0.11,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }
}