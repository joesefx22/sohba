import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_colors.dart';
import '../services/level_service.dart';

/// A full-screen animation overlay displayed when the hero levels up.
///
/// Animation Sequence:
/// 1. Full-screen overlay fades in
/// 2. "LEVEL UP!" text scales up with glow
/// 3. Old → New level number transition
/// 4. New title (if changed) slides in
/// 5. Particle explosion
/// 6. Rewards preview (unlocked features)
/// 7. "Weiter" button appears
///
/// The animation is skippable by tapping anywhere or pressing the button.
class LevelUpAnimation extends StatefulWidget {
  /// The previous level before leveling up.
  final int oldLevel;

  /// The new level after leveling up.
  final int newLevel;

  /// Optional list of unlocked rewards/features.
  final List<String>? unlockedRewards;

  /// Callback when animation is complete or skipped.
  final VoidCallback onComplete;

  const LevelUpAnimation({
    super.key,
    required this.oldLevel,
    required this.newLevel,
    this.unlockedRewards,
    required this.onComplete,
  });

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();

  /// Shows the level up animation as an overlay.
  static Future<void> show({
    required BuildContext context,
    required int oldLevel,
    required int newLevel,
    List<String>? unlockedRewards,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return LevelUpAnimation(
          oldLevel: oldLevel,
          newLevel: newLevel,
          unlockedRewards: unlockedRewards,
          onComplete: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _overlayController;
  late AnimationController _levelUpTextController;
  late AnimationController _levelNumberController;
  late AnimationController _titleController;
  late AnimationController _rewardsController;
  late AnimationController _buttonController;
  late AnimationController _glowController;

  // Animations
  late Animation<double> _overlayAnimation;
  late Animation<double> _levelUpScaleAnimation;
  late Animation<double> _levelUpOpacityAnimation;
  late Animation<double> _levelNumberAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<double> _rewardsAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _glowAnimation;

  // Confetti
  late ConfettiController _confettiController;

  // State
  bool _isSkipped = false;
  bool _showButton = false;
  int _displayedLevel = 0;

  // Timing constants (in milliseconds)
  static const int _overlayDuration = 300;
  static const int _levelUpTextDuration = 600;
  static const int _levelNumberDuration = 800;
  static const int _titleDuration = 500;
  static const int _rewardsDuration = 400;
  static const int _buttonDuration = 300;

  // Delays
  static const int _levelUpDelay = 200;
  static const int _levelNumberDelay = 800;
  static const int _confettiDelay = 1200;
  static const int _titleDelay = 1600;
  static const int _rewardsDelay = 2200;
  static const int _buttonDelay = 2800;

  @override
  void initState() {
    super.initState();
    _displayedLevel = widget.oldLevel;
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

    // "LEVEL UP!" text scale and opacity
    _levelUpTextController = AnimationController(
      duration: const Duration(milliseconds: _levelUpTextDuration),
      vsync: this,
    );
    _levelUpScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _levelUpTextController, curve: Curves.elasticOut),
    );
    _levelUpOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _levelUpTextController,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Level number transition
    _levelNumberController = AnimationController(
      duration: const Duration(milliseconds: _levelNumberDuration),
      vsync: this,
    );
    _levelNumberAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _levelNumberController, curve: Curves.easeOutCubic),
    );
    _levelNumberController.addListener(_updateDisplayedLevel);

    // Title slide in
    _titleController = AnimationController(
      duration: const Duration(milliseconds: _titleDuration),
      vsync: this,
    );
    _titleSlideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    _titleOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    // Glow pulsing animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Rewards fade in
    _rewardsController = AnimationController(
      duration: const Duration(milliseconds: _rewardsDuration),
      vsync: this,
    );
    _rewardsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rewardsController, curve: Curves.easeOut),
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
      duration: const Duration(seconds: 3),
    );
  }

  void _updateDisplayedLevel() {
    final progress = _levelNumberAnimation.value;
    final newDisplayedLevel = (widget.oldLevel +
        (widget.newLevel - widget.oldLevel) * progress).round();
    if (newDisplayedLevel != _displayedLevel) {
      setState(() {
        _displayedLevel = newDisplayedLevel;
      });
      // Haptic feedback for each level increment
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _startAnimationSequence() async {
    if (_isSkipped) return;

    // Haptic feedback at start
    HapticFeedback.mediumImpact();

    // 1. Overlay fades in
    _overlayController.forward();

    // 2. "LEVEL UP!" text
    await Future.delayed(const Duration(milliseconds: _levelUpDelay));
    if (_isSkipped) return;
    _levelUpTextController.forward();
    _glowController.repeat(reverse: true);

    // 3. Level number transition
    await Future.delayed(const Duration(milliseconds: _levelNumberDelay - _levelUpDelay));
    if (_isSkipped) return;
    _levelNumberController.forward();

    // 4. Confetti explosion
    await Future.delayed(const Duration(milliseconds: _confettiDelay - _levelNumberDelay));
    if (_isSkipped) return;
    _confettiController.play();
    HapticFeedback.heavyImpact();

    // 5. Title (if changed)
    await Future.delayed(const Duration(milliseconds: _titleDelay - _confettiDelay));
    if (_isSkipped) return;
    _titleController.forward();

    // 6. Rewards preview
    await Future.delayed(const Duration(milliseconds: _rewardsDelay - _titleDelay));
    if (_isSkipped) return;
    if (widget.unlockedRewards != null && widget.unlockedRewards!.isNotEmpty) {
      _rewardsController.forward();
    }

    // 7. Button appears
    await Future.delayed(const Duration(milliseconds: _buttonDelay - _rewardsDelay));
    if (_isSkipped) return;
    _glowController.stop();
    setState(() => _showButton = true);
    _buttonController.forward();
  }

  void _skipAnimation() {
    if (_isSkipped) return;
    _isSkipped = true;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Complete all animations immediately
    _overlayController.value = 1;
    _levelUpTextController.value = 1;
    _levelNumberController.value = 1;
    _titleController.value = 1;
    _rewardsController.value = 1;
    _buttonController.value = 1;
    _glowController
      ..value = 1
      ..stop();
    _confettiController.play();

    setState(() {
      _displayedLevel = widget.newLevel;
      _showButton = true;
    });
  }

  void _complete() {
    HapticFeedback.lightImpact();
    widget.onComplete();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _levelUpTextController.dispose();
    _levelNumberController.dispose();
    _titleController.dispose();
    _glowController.dispose();
    _rewardsController.dispose();
    _buttonController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  /// Check if title changed between old and new level
  bool get _titleChanged {
    final oldTitle = LevelService.titleForLevel(widget.oldLevel);
    final newTitle = LevelService.titleForLevel(widget.newLevel);
    return oldTitle != newTitle;
  }

  String get _newTitle => LevelService.titleForLevel(widget.newLevel);

  @override
  Widget build(BuildContext context) {
    final newLevelColor = LevelService.colorForLevel(widget.newLevel);

    return GestureDetector(
      onTap: _showButton ? _complete : _skipAnimation,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark overlay with gradient
            AnimatedBuilder(
              animation: _overlayAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        newLevelColor.withAlpha((40 * _overlayAnimation.value).toInt()),
                        Colors.black.withAlpha((220 * _overlayAnimation.value).toInt()),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Confetti (from top)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                gravity: 0.15,
                shouldLoop: false,
                colors: [
                  newLevelColor,
                  AppColors.gold,
                  Colors.white,
                  AppColors.primaryStart,
                  AppColors.primaryEnd,
                ],
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "LEVEL UP!" text
                  _buildLevelUpText(newLevelColor),
                  const SizedBox(height: 32),

                  // Level number display
                  _buildLevelNumber(newLevelColor),
                  const SizedBox(height: 24),

                  // New title (if changed)
                  if (_titleChanged) _buildNewTitle(newLevelColor),

                  // Rewards preview
                  if (widget.unlockedRewards != null &&
                      widget.unlockedRewards!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildRewardsPreview(newLevelColor),
                  ],

                  // Continue button
                  const SizedBox(height: 40),
                  _buildButton(newLevelColor),
                ],
              ),
            ),

            // Particle effects (floating)
            ...List.generate(12, (index) => _buildFloatingParticle(index, newLevelColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelUpText(Color color) {
    return AnimatedBuilder(
      animation: Listenable.merge([_levelUpScaleAnimation, _levelUpOpacityAnimation, _glowAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _levelUpOpacityAnimation.value,
          child: Transform.scale(
            scale: _levelUpScaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha((100 * _glowAnimation.value).toInt()),
                    blurRadius: 40 * _glowAnimation.value,
                    spreadRadius: 10 * _glowAnimation.value,
                  ),
                ],
              ),
              child: Text(
                'LEVEL UP!',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: color,
                      blurRadius: 20,
                    ),
                    Shadow(
                      color: color.withAlpha(128),
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelNumber(Color color) {
    return AnimatedBuilder(
      animation: _levelNumberAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Old level (fading out)
            Opacity(
              opacity: (1 - _levelNumberAnimation.value).clamp(0.0, 1.0),
              child: Text(
                '${widget.oldLevel}',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withAlpha(128),
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.scale(
                scale: _levelNumberAnimation.value.clamp(0.5, 1.0),
                child: Icon(
                  Icons.arrow_forward,
                  size: 48,
                  color: color.withAlpha(
                    (255 * _levelNumberAnimation.value).toInt(),
                  ),
                ),
              ),
            ),

            // New level (fading in and scaling up)
            Transform.scale(
              scale: 0.8 + (0.2 * _levelNumberAnimation.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withAlpha((50 * _levelNumberAnimation.value).toInt()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withAlpha((200 * _levelNumberAnimation.value).toInt()),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha((100 * _levelNumberAnimation.value).toInt()),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  '$_displayedLevel',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: color,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewTitle(Color color) {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _titleSlideAnimation.value),
          child: Opacity(
            opacity: _titleOpacityAnimation.value,
            child: Column(
              children: [
                Text(
                  'Neuer Titel freigeschaltet!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(179),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withAlpha(51),
                        color.withAlpha(25),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.withAlpha(128),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.military_tech,
                        color: color,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _newTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardsPreview(Color color) {
    return AnimatedBuilder(
      animation: _rewardsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _rewardsAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _rewardsAnimation.value)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(200),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Freigeschaltet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.unlockedRewards!.map((reward) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.teal,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reward,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(Color color) {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showButton ? _complete : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: color.withAlpha(128),
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
      ),
    );
  }

  Widget _buildFloatingParticle(int index, Color color) {
    final random = Random(index);
    final startX = random.nextDouble() * MediaQuery.of(context).size.width;
    final startY = random.nextDouble() * MediaQuery.of(context).size.height;
    final size = 4.0 + random.nextDouble() * 8;
    final delay = random.nextDouble() * 2000;

    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        if (_overlayAnimation.value < 0.5) return const SizedBox.shrink();

        return Positioned(
          left: startX,
          top: startY,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 2000 + delay.toInt()),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(
                  sin(value * pi * 2 + index) * 20,
                  -value * 100 - sin(value * pi * 4) * 10,
                ),
                child: Opacity(
                  opacity: (1 - value).clamp(0.0, 0.8),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index % 3 == 0
                          ? color
                          : index % 3 == 1
                              ? AppColors.gold
                              : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(100),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
