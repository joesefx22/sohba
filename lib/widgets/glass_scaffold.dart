import 'package:flutter/material.dart';

import '../services/background_service.dart';
import '../theme/app_colors.dart';

class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final bg = BackgroundService().currentBackground;
    final hasBg = bg.isNotEmpty;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Layer 1: Background (image or gradient fallback)
          SizedBox.expand(
            child: hasBg
                ? Image.asset(bg, fit: BoxFit.cover)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.backgroundLinearGradient,
                    ),
                  ),
          ),
          // Layer 2: Dark gradient overlay
          SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(26),
                    Colors.black.withAlpha(77),
                  ],
                ),
              ),
            ),
          ),
          // Layer 3: Content
          body,
        ],
      ),
    );
  }
}