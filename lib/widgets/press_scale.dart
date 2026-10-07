import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Press feedback: scale 1.0 -> 0.97 -> 1.0. Wrap anything tappable.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:   (_) => setState(() => _down = true),
      onTapCancel: ()  => setState(() => _down = false),
      onTapUp:     (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: (_down && !reduced) ? 0.97 : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}