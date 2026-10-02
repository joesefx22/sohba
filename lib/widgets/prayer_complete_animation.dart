import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../models/prayer_log.dart';
import '../theme/app_colors.dart';

/// Full-screen celebration shown after a prayer is recorded.
class PrayerCompleteAnimation extends StatefulWidget {
  final PrayerName prayer;
  final PrayerStatus status;
  final int hasanat;
  final int? streak;
  final VoidCallback onComplete;

  const PrayerCompleteAnimation({
    super.key,
    required this.prayer,
    required this.status,
    required this.hasanat,
    this.streak,
    required this.onComplete,
  });

  static Future<void> show({
    required BuildContext context,
    required PrayerName prayer,
    required PrayerStatus status,
    required int hasanat,
    int? streak,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, __) => PrayerCompleteAnimation(
        prayer: prayer,
        status: status,
        hasanat: hasanat,
        streak: streak,
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<PrayerCompleteAnimation> createState() =>
      _PrayerCompleteAnimationState();
}

class _PrayerCompleteAnimationState extends State<PrayerCompleteAnimation>
    with TickerProviderStateMixin {
  late AnimationController _cardCtrl;
  late AnimationController _iconCtrl;
  late AnimationController _pointCtrl;
  late AnimationController _buttonCtrl;
  late ConfettiController _confetti;

  late Animation<double> _cardScale;
  late Animation<double> _cardSlide;
  late Animation<double> _iconScale;
  late Animation<int> _pointCount;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    _cardCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cardScale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut),
    );
    _cardSlide = Tween(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut),
    );

    _iconCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _iconScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut),
    );

    _pointCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _pointCount = IntTween(begin: 0, end: widget.hasanat).animate(
      CurvedAnimation(parent: _pointCtrl, curve: Curves.easeOut),
    );

    _buttonCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonFade = CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut);

    _confetti = ConfettiController(duration: const Duration(seconds: 2));

    _start();
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _iconCtrl.forward();
    _confetti.play();
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _pointCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _buttonCtrl.forward();
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _iconCtrl.dispose();
    _pointCtrl.dispose();
    _buttonCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _skip() {
    _cardCtrl.value = 1;
    _iconCtrl.value = 1;
    _pointCtrl.value = 1;
    _buttonCtrl.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _buttonCtrl.isCompleted ? widget.onComplete : _skip,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(color: Colors.black.withAlpha(210)),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 25,
                gravity: 0.15,
                shouldLoop: false,
                colors: const [
                  AppColors.gold,
                  AppColors.teal,
                  AppColors.primaryStart,
                  Colors.white,
                ],
              ),
            ),
            Center(
              child: SlideTransition(
                position: _cardSlide.drive(
                  Tween(begin: const Offset(0, 1), end: Offset.zero),
                ),
                child: ScaleTransition(
                  scale: _cardScale,
                  child: _buildCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withAlpha(128), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withAlpha(80),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: AppColors.gold, size: 26),
              SizedBox(width: 8),
              Text(
                'تقبّل الله',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.check_circle, color: AppColors.gold, size: 26),
            ],
          ),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _iconScale,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.status.color.withAlpha(50),
                border: Border.all(color: widget.status.color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: widget.status.color.withAlpha(120),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Icon(
                widget.prayer.icon,
                size: 48,
                color: widget.status.color,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.prayer.arabicName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.status.arabicLabel,
            style: TextStyle(
              fontSize: 16,
              color: widget.status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.hasanat > 0) ...[
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _pointCount,
              builder: (_, __) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withAlpha(90)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: AppColors.gold, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      '+${_pointCount.value}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'حسنة',
                      style: TextStyle(fontSize: 16, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (widget.streak != null && widget.streak! > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(38),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withAlpha(102)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.streak} يوم مواصلة',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _buttonFade,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _buttonCtrl.isCompleted ? widget.onComplete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStart,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'الحمد لله',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}