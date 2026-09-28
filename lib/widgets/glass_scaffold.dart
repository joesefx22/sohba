import 'package:flutter/material.dart';

import '../services/background_service.dart';

/// A scaffold that displays a fullscreen background image with a dark gradient
/// overlay, providing the foundation for the frosted-glass UI.
///
/// Use this in place of [Scaffold] on pages that should have the glass effect.
/// Child widgets can use [GlassContainer] to get frosted-glass cards on top of
/// the background.
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
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Layer 1: Fullscreen background image
          SizedBox.expand(
            child: Image.asset(
              BackgroundService().currentBackground,
              fit: BoxFit.cover,
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
          // Layer 3: Actual page content
          body,
        ],
      ),
    );
  }
}
