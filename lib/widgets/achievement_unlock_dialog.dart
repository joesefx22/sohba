import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/achievement.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Shows a celebratory dialog when an achievement is unlocked
class AchievementUnlockDialog extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  /// Show the dialog as an overlay
  static Future<void> show(
    BuildContext context,
    Achievement achievement, {
    VoidCallback? onDismiss,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AchievementUnlockDialog(
          achievement: achievement,
          onDismiss: onDismiss,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  @override
  State<AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with TickerProviderStateMixin {
  late AnimationController _badgeController;
  late AnimationController _contentController;
  late AnimationController _confettiController;
  late AnimationController _rewardsController;

  late Animation<double> _badgeScale;
  late Animation<double> _badgeRotation;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _confettiProgress;

  final List<_RewardAnimation> _rewardAnimations = [];

  @override
  void initState() {
    super.initState();

    // Badge animation
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _badgeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _badgeController,
        curve: Curves.elasticOut,
      ),
    );
    _badgeRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _badgeController,
        curve: Curves.easeOut,
      ),
    );

    // Content animation
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOut,
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOut,
      ),
    );

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _confettiProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      _confettiController,
    );

    // Rewards animation
    _rewardsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _setupRewardAnimations();
    _startAnimations();
  }

  void _setupRewardAnimations() {
    final rewards = <(IconData, String)>[];

    rewards.add((Icons.bolt, '+${widget.achievement.rewardXP} XP'));

    if (widget.achievement.rewardPoints != null) {
      rewards.add((Icons.auto_awesome, '+${widget.achievement.rewardPoints} Points'));
    }

    if (widget.achievement.rewardItem != null) {
      rewards.add((Icons.card_giftcard, widget.achievement.rewardItem!));
    }

    for (int i = 0; i < rewards.length; i++) {
      final delay = i * 0.2;
      _rewardAnimations.add(_RewardAnimation(
        icon: rewards[i].$1,
        text: rewards[i].$2,
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _rewardsController,
            curve: Interval(delay, delay + 0.6, curve: Curves.elasticOut),
          ),
        ),
      ));
    }
  }

  void _startAnimations() async {
    // Start badge animation
    _badgeController.forward();
    _confettiController.forward();

    // Wait a bit, then show content
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _contentController.forward();

    // Wait a bit more, then show rewards
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _rewardsController.forward();
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _contentController.dispose();
    _confettiController.dispose();
    _rewardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Confetti layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiProgress,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _confettiProgress.value,
                    color: widget.achievement.tierColor,
                  ),
                );
              },
            ),
          ),

          // Dialog content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: const Text(
                        'Achievement Freigeschaltet!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Badge
                  AnimatedBuilder(
                    animation: _badgeController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _badgeScale.value,
                        child: Transform.rotate(
                          angle: _badgeRotation.value,
                          child: _buildBadge(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Name
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Text(
                        widget.achievement.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tier badge
                  FadeTransition(
                    opacity: _contentFade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.achievement.tierColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.achievement.tierColor.withAlpha(128),
                        ),
                      ),
                      child: Text(
                        widget.achievement.tier.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.achievement.tierColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Text(
                        widget.achievement.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withAlpha(179),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Rewards
                  _buildRewards(),
                  const SizedBox(height: 32),

                  // Button
                  FadeTransition(
                    opacity: _contentFade,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDismiss?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.achievement.tierColor,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Toll!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.achievement.tierColor,
            HSLColor.fromColor(widget.achievement.tierColor)
                .withLightness(
                    (HSLColor.fromColor(widget.achievement.tierColor).lightness -
                            0.2)
                        .clamp(0.0, 1.0))
                .toColor(),
          ],
        ),
        border: Border.all(
          color: widget.achievement.tierColor,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.achievement.tierColor.withAlpha(128),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Icon(AppIcons.get(widget.achievement.icon), size: 56, color: Colors.white),
      ),
    );
  }

  Widget _buildRewards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _rewardAnimations.map((reward) {
        return AnimatedBuilder(
          animation: reward.animation,
          builder: (context, child) {
            return Transform.scale(
              scale: reward.animation.value,
              child: Opacity(
                opacity: reward.animation.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(51),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        reward.icon,
                        size: 28,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _RewardAnimation {
  final IconData icon;
  final String text;
  final Animation<double> animation;

  _RewardAnimation({
    required this.icon,
    required this.text,
    required this.animation,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount = 100;

  _ConfettiPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final colors = [
      color,
      AppColors.primaryStart,
      AppColors.teal,
      AppColors.gold,
      AppColors.rarityEpic,
      Colors.white,
    ];

    for (int i = 0; i < particleCount; i++) {
      final particleRandom = math.Random(i);
      final startX = particleRandom.nextDouble() * size.width;
      final startY = -20.0 - particleRandom.nextDouble() * 100;

      final endX = startX + (particleRandom.nextDouble() - 0.5) * 200;
      final endY = size.height + 50;

      final currentX = startX + (endX - startX) * progress;
      final currentY = startY + (endY - startY) * progress;

      final rotation = progress * math.pi * 4 * (particleRandom.nextDouble() + 0.5);
      final particleColor = colors[i % colors.length];
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = particleColor.withAlpha((opacity * 255).toInt())
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(rotation);

      // Draw different shapes
      final shapeType = i % 3;
      final particleSize = 6.0 + particleRandom.nextDouble() * 6;

      if (shapeType == 0) {
        // Rectangle
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particleSize,
            height: particleSize * 0.6,
          ),
          paint,
        );
      } else if (shapeType == 1) {
        // Circle
        canvas.drawCircle(Offset.zero, particleSize * 0.4, paint);
      } else {
        // Triangle
        final path = Path()
          ..moveTo(0, -particleSize * 0.5)
          ..lineTo(particleSize * 0.4, particleSize * 0.3)
          ..lineTo(-particleSize * 0.4, particleSize * 0.3)
          ..close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
