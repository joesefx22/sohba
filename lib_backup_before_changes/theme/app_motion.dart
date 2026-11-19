import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// One animation language for the whole app.
class AppMotion {
  AppMotion._();

  // Durations
  static const page = Duration(milliseconds: 250);
  static const card = Duration(milliseconds: 250);
  static const press = Duration(milliseconds: 120);
  static const success = Duration(milliseconds: 1000); // 800-1200ms
  static const number = Duration(milliseconds: 700);

  // Curves (no elastic outside celebrations)
  static const curve = Curves.easeOutCubic;

  static const stagger = Duration(milliseconds: 50);

  static bool reduced(BuildContext c) => MediaQuery.disableAnimationsOf(c);

  /// A + B: fade + 8px translate, staggered by [index] (max 4 steps).
  static Widget entrance(BuildContext context, Widget child, {int index = 0}) {
    if (reduced(context)) return child;
    return child
        .animate(delay: stagger * index.clamp(0, 3))
        .fadeIn(duration: card, curve: curve)
        .moveY(begin: 8, end: 0, duration: card, curve: curve);
  }

  /// F: streak pulse 1.0 -> 1.08 -> 1.0.
  static Widget pulse(BuildContext context, Widget child, {Object? trigger}) {
    if (reduced(context)) return child;
    return child
        .animate(key: ValueKey(trigger))
        .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 250.ms,
            curve: Curves.easeOut)
        .then()
        .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1, 1),
            duration: 250.ms,
            curve: Curves.easeIn);
  }
}