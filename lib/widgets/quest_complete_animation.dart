import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/quest.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'xp_progress_bar.dart';

/// A full-screen animation overlay displayed when a quest is completed.
///
/// Animation Sequence:
/// 1. Screen overlay fades in
/// 2. Quest card slides up and centers
/// 3. Checkmark animation plays
/// 4. Confetti explosion
/// 5. Points count up
/// 6. XP bar fills
/// 7. "Weiter" button appears
///
/// The animation is skippable by tapping anywhere or pressing the button.
class QuestCompleteAnimation extends StatefulWidget {
  /// The completed quest.
  final Quest quest;

  /// Points earned for this quest completion.
  final int earnedPoints;

  /// XP earned for this quest completion.
  final int earnedXP;

  /// Current total XP before this quest completion.
  final int currentXP;

  /// XP needed to reach next level.
  final int xpToNextLevel;

  /// Current level.
  final int currentLevel;

  /// Optional streak count to display.
  final int? streak;

  /// Callback when animation is complete or skipped.
  final VoidCallback onComplete;

  const QuestCompleteAnimation({
    super.key,
    required this.quest,
    required this.earnedPoints,
    required this.earnedXP,
    required this.currentXP,
    required this.xpToNextLevel,
    required this.currentLevel,
    this.streak,
    required this.onComplete,
  });

  @override
  State<QuestCompleteAnimation> createState() => _QuestCompleteAnimationState();

  /// Shows the quest complete animation as an overlay.
  static Future<void> show({
    required BuildContext context,
    required Quest quest,
    required int earnedPoints,
    required int earnedXP,
    required int currentXP,
    required int xpToNextLevel,
    required int currentLevel,
    int? streak,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return QuestCompleteAnimation(
          quest: quest,
          earnedPoints: earnedPoints,
          earnedXP: earnedXP,
          currentXP: currentXP,
          xpToNextLevel: xpToNextLevel,
          currentLevel: currentLevel,
          streak: streak,
          onComplete: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

class _QuestCompleteAnimationState extends State<QuestCompleteAnimation>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _overlayController;
  late AnimationController _cardController;
  late AnimationController _checkmarkController;
  late AnimationController _pointsController;
  late AnimationController _xpController;
  late AnimationController _buttonController;

  // Animations
  late Animation<double> _overlayAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _checkmarkAnimation;
  late Animation<int> _pointsCountAnimation;
  late Animation<double> _xpFillAnimation;
  late Animation<double> _buttonAnimation;

  // Confetti
  late ConfettiController _confettiController;

  // State
  bool _isSkipped = false;
  bool _showButton = false;

  // Timing constants (in milliseconds)
  static const int _overlayDuration = 300;
  static const int _cardDuration = 500;
  static const int _checkmarkDuration = 600;
  static const int _pointsDuration = 800;
  static const int _xpDuration = 800;
  static const int _buttonDuration = 300;

  // Delays between animations
  static const int _cardDelay = 100;
  static const int _checkmarkDelay = 400;
  static const int _confettiDelay = 600;
  static const int _pointsDelay = 800;
  static const int _xpDelay = 1600;
  static const int _buttonDelay = 2400;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Overlay fade in
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: _overlayDuration),
      vsync: this,
    );
    _overlayAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeOut),
    );

    // Card slide up and scale
    _cardController = AnimationController(
      duration: const Duration(milliseconds: _cardDuration),
      vsync: this,
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));
    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    // Checkmark draw animation
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: _checkmarkDuration),
      vsync: this,
    );
    _checkmarkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.easeInOut),
    );

    // Points count up
    _pointsController = AnimationController(
      duration: const Duration(milliseconds: _pointsDuration),
      vsync: this,
    );
    _pointsCountAnimation = IntTween(begin: 0, end: widget.earnedPoints).animate(
      CurvedAnimation(parent: _pointsController, curve: Curves.easeOut),
    );

    // XP bar fill
    _xpController = AnimationController(
      duration: const Duration(milliseconds: _xpDuration),
      vsync: this,
    );
    _xpFillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.easeOut),
    );

    // Button fade in
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: _buttonDuration),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _startAnimationSequence() async {
    if (_isSkipped) return;

    // 1. Overlay fades in
    _overlayController.forward();

    // 2. Card slides up
    await Future.delayed(const Duration(milliseconds: _cardDelay));
    if (_isSkipped) return;
    _cardController.forward();

    // 3. Checkmark animation
    await Future.delayed(const Duration(milliseconds: _checkmarkDelay));
    if (_isSkipped) return;
    _checkmarkController.forward();

    // 4. Confetti
    await Future.delayed(const Duration(milliseconds: _confettiDelay - _checkmarkDelay));
    if (_isSkipped) return;
    _confettiController.play();

    // 5. Points count up
    await Future.delayed(const Duration(milliseconds: _pointsDelay - _confettiDelay));
    if (_isSkipped) return;
    _pointsController.forward();

    // 6. XP bar fill
    await Future.delayed(const Duration(milliseconds: _xpDelay - _pointsDelay));
    if (_isSkipped) return;
    _xpController.forward();

    // 7. Button appears
    await Future.delayed(const Duration(milliseconds: _buttonDelay - _xpDelay));
    if (_isSkipped) return;
    setState(() => _showButton = true);
    _buttonController.forward();
  }

  void _skipAnimation() {
    if (_isSkipped) return;
    _isSkipped = true;

    // Complete all animations immediately
    _overlayController.value = 1;
    _cardController.value = 1;
    _checkmarkController.value = 1;
    _pointsController.value = 1;
    _xpController.value = 1;
    _buttonController.value = 1;
    _confettiController.play();

    setState(() => _showButton = true);
  }

  void _complete() {
    widget.onComplete();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _cardController.dispose();
    _checkmarkController.dispose();
    _pointsController.dispose();
    _xpController.dispose();
    _buttonController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showButton ? _complete : _skipAnimation,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark overlay
            AnimatedBuilder(
              animation: _overlayAnimation,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withAlpha(
                    (200 * _overlayAnimation.value).toInt(),
                  ),
                );
              },
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // downwards
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  AppColors.gold,
                  AppColors.teal,
                  AppColors.primaryStart,
                  AppColors.primaryEnd,
                  Colors.white,
                ],
              ),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _cardController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _cardSlideAnimation,
                    child: ScaleTransition(
                      scale: _cardScaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: _buildCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.quest.rarityColor.withAlpha(128),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.quest.rarityColor.withAlpha(77),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quest Complete Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Quest Icon with Checkmark
          _buildQuestIcon(),
          const SizedBox(height: 16),

          // Quest Name
          Text(
            widget.quest.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Points Earned
          _buildPointsSection(),
          const SizedBox(height: 20),

          // XP Progress
          _buildXpSection(),
          const SizedBox(height: 8),

          // Streak (if applicable)
          if (widget.streak != null && widget.streak! > 0) ...[
            const SizedBox(height: 16),
            _buildStreakBadge(),
          ],

          // Continue Button
          const SizedBox(height: 24),
          _buildButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.emoji_events,
          color: AppColors.gold,
          size: 28,
        ),
        const SizedBox(width: 8),
        Text(
          'Quest Abgeschlossen!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.emoji_events,
          color: AppColors.gold,
          size: 28,
        ),
      ],
    );
  }

  Widget _buildQuestIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Quest icon background
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: widget.quest.rarityColor.withAlpha(51),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.quest.rarityColor,
              width: 3,
            ),
          ),
          child: Center(
            child: Icon(AppIcons.get(widget.quest.icon), size: 36, color: Colors.white),
          ),
        ),

        // Animated checkmark overlay
        AnimatedBuilder(
          animation: _checkmarkAnimation,
          builder: (context, child) {
            return Positioned(
              right: -4,
              bottom: -4,
              child: Transform.scale(
                scale: _checkmarkAnimation.value,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withAlpha(128),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _CheckmarkPainter(
                      progress: _checkmarkAnimation.value,
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPointsSection() {
    return AnimatedBuilder(
      animation: _pointsCountAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gold.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withAlpha(77),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars,
                color: AppColors.gold,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                '+${_pointsCountAnimation.value}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Punkte',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.gold.withAlpha(200),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildXpSection() {
    return AnimatedBuilder(
      animation: _xpFillAnimation,
      builder: (context, child) {
        final animatedXP = (widget.earnedXP * _xpFillAnimation.value).toInt();
        final displayXP = widget.currentXP + animatedXP;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppColors.teal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '+$animatedXP XP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            XpProgressBar(
              currentXP: displayXP,
              maxXP: widget.xpToNextLevel,
              level: widget.currentLevel,
              animated: false,
              height: 16,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withAlpha(102),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.streak} Tage Streak!',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _buttonAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _buttonAnimation.value)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _showButton ? _complete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Text(
            'Weiter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for animated checkmark.
class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 24;

    // Checkmark path points (relative to center)
    final start = Offset(center.dx - 5 * scale, center.dy);
    final mid = Offset(center.dx - 1 * scale, center.dy + 4 * scale);
    final end = Offset(center.dx + 6 * scale, center.dy - 4 * scale);

    final path = Path();

    if (progress <= 0.5) {
      // Draw first part of checkmark
      final t = progress * 2;
      final currentPoint = Offset.lerp(start, mid, t)!;
      path.moveTo(start.dx, start.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      // Draw complete first part and partial second part
      path.moveTo(start.dx, start.dy);
      path.lineTo(mid.dx, mid.dy);

      final t = (progress - 0.5) * 2;
      final currentPoint = Offset.lerp(mid, end, t)!;
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
