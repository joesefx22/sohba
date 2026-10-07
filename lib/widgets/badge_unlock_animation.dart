import 'dart:async';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../models/badge.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Premium achievement reveal:
/// dark overlay -> ambient glow -> medal enters slowly -> light sweep ->
/// "ميدالية جديدة" -> name -> description -> a few small particles.
/// Public API unchanged.
class BadgeUnlockAnimation extends StatefulWidget {
  final Badge badge;
  final VoidCallback onComplete;

  const BadgeUnlockAnimation({
    super.key,
    required this.badge,
    required this.onComplete,
  });

  static Future<void> show({
    required BuildContext context,
    required Badge badge,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, __) => BadgeUnlockAnimation(
        badge: badge,
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<BadgeUnlockAnimation> createState() => _BadgeUnlockAnimationState();
}

class _BadgeUnlockAnimationState extends State<BadgeUnlockAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final ConfettiController _confetti;
  late final Animation<double> _overlay, _glow, _badge, _sweep, _label, _name,
      _desc, _btn;
  final _timers = <Timer>[];

  Animation<double> _iv(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: c));

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _confetti = ConfettiController(duration: const Duration(seconds: 1));

    _overlay = _iv(0.0, 0.1);
    _glow = _iv(0.05, 0.3);
    _badge = _iv(0.1, 0.4);
    _sweep = _iv(0.4, 0.58, Curves.easeInOut);
    _label = _iv(0.55, 0.68);
    _name = _iv(0.62, 0.76);
    _desc = _iv(0.72, 0.86);
    _btn = _iv(0.86, 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
        return;
      }
      _c.forward();
      // Heavy haptic only when the medal lands.
      _timers.add(Timer(const Duration(milliseconds: 1150),
          () => HapticFeedback.heavyImpact()));
      // Small, brief particles after the text is in.
      _timers.add(Timer(const Duration(milliseconds: 2000), () {
        if (mounted) _confetti.play();
      }));
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _c.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.badge.tier.color;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ColoredBox(
                  color: Colors.black.withAlpha((225 * _overlay.value).round())),
            ),
            // Ambient glow
            Opacity(
              opacity: _glow.value,
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    color.withAlpha(70),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: 3.14159 / 2,
                maxBlastForce: 4,
                minBlastForce: 2,
                emissionFrequency: 0.04,
                numberOfParticles: 10,
                gravity: 0.1,
                shouldLoop: false,
                colors: [color, AppColors.gold, Colors.white],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _badge.value,
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * _badge.value,
                    child: _medal(color),
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: _label.value,
                  child: Text('ميدالية جديدة',
                      style: AppText.caption.copyWith(
                          fontSize: 14,
                          color: AppColors.goldBright,
                          letterSpacing: 1.2)),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: _name.value,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - _name.value)),
                    child: Column(
                      children: [
                        Text(widget.badge.nameAr,
                            textAlign: TextAlign.center,
                            style: AppText.heading.copyWith(fontSize: 28)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(40),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withAlpha(130)),
                          ),
                          child: Text(widget.badge.tier.labelAr,
                              style: AppText.caption.copyWith(
                                  color: color, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Opacity(
                  opacity: _desc.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(widget.badge.description,
                        textAlign: TextAlign.center,
                        style: AppText.body
                            .copyWith(color: Colors.white.withAlpha(180))),
                  ),
                ),
                const SizedBox(height: 32),
                Opacity(
                  opacity: _btn.value,
                  child: IgnorePointer(
                    ignoring: _btn.value < 0.5,
                    child: GestureDetector(
                      onTap: widget.onComplete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 44, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.progressGradient,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text('ما شاء الله',
                            style: AppText.section.copyWith(
                                fontSize: 16, color: AppColors.background)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _medal(Color color) {
    // Light sweep: a soft white band travelling across the medal.
    final x0 = -2.0 + 3.5 * _sweep.value;
    final medal = Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(color: color.withAlpha(110), blurRadius: 36, spreadRadius: 2),
        ],
      ),
      child: Icon(widget.badge.iconData, size: 64, color: Colors.white),
    );

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment(x0, -0.4),
        end: Alignment(x0 + 1.0, 0.4),
        colors: [
          Colors.transparent,
          Colors.white.withAlpha(120),
          Colors.transparent,
        ],
      ).createShader(rect),
      child: medal,
    );
  }
}