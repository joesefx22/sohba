import 'dart:math';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../models/badge.dart';
import '../theme/app_colors.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _badgeCtrl;
  late AnimationController _textCtrl;
  late AnimationController _btnCtrl;
  late ConfettiController _confetti;

  late Animation<double> _badgeScale;
  late Animation<double> _badgeRotate;
  late Animation<double> _textFade;
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();

    _badgeCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _badgeScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut),
    );
    _badgeRotate = Tween(begin: -0.4, end: 0.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOut),
    );

    _textCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    _btnCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut);

    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _start();
  }

  Future<void> _start() async {
    HapticFeedback.heavyImpact();
    _badgeCtrl.forward();
    _confetti.play();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    _textCtrl.dispose();
    _btnCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.badge.tier.color;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Container(color: Colors.black.withAlpha(220)),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              maxBlastForce: 6,
              minBlastForce: 3,
              emissionFrequency: 0.04,
              numberOfParticles: 35,
              gravity: 0.12,
              shouldLoop: false,
              colors: [color, AppColors.gold, Colors.white, AppColors.teal],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _textFade,
                  child: const Text(
                    'ميدالية جديدة!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _badgeCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: _badgeScale.value,
                    child: Transform.rotate(
                      angle: _badgeRotate.value,
                      child: _buildMedal(color),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      Text(
                        widget.badge.nameAr,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withAlpha(51),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: color.withAlpha(150)),
                        ),
                        child: Text(
                          widget.badge.tier.labelAr.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          widget.badge.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withAlpha(180),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _btnFade,
                  child: ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'ما شاء الله!',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedal(Color color) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(140),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        widget.badge.iconData,
        size: 64,
        color: Colors.white,
      ),
    );
  }
}