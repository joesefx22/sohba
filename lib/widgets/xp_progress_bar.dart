import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// An animated XP progress bar with gradient fill, shine sweep, and level-up pulse.
///
/// Features:
/// - Gradient fill (Teal)
/// - Animated progress on XP change
/// - Continuous shine sweep animation
/// - Pulse effect when close to level-up (>= 80%)
/// - Level markers
class XpProgressBar extends StatefulWidget {
  /// Current XP amount.
  final int currentXP;

  /// Maximum XP needed for next level.
  final int maxXP;

  /// Current level number.
  final int level;

  /// Whether animations are enabled.
  final bool animated;

  /// Height of the progress bar.
  final double height;

  /// Whether to show the level label.
  final bool showLevel;

  /// Whether to show the XP text (current/max).
  final bool showXpText;

  const XpProgressBar({
    super.key,
    required this.currentXP,
    required this.maxXP,
    required this.level,
    this.animated = true,
    this.height = 12,
    this.showLevel = true,
    this.showXpText = true,
  });

  @override
  State<XpProgressBar> createState() => _XpProgressBarState();
}

class _XpProgressBarState extends State<XpProgressBar>
    with TickerProviderStateMixin {
  // Progress fill animation
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  // Shine sweep animation (continuous)
  late AnimationController _shineController;

  // Pulse animation for near level-up
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  /// Threshold for "almost level up" pulse effect (80%)
  static const double _nearLevelUpThreshold = 0.8;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final initialProgress = _calculateProgress();
    _previousProgress = initialProgress;

    // Progress fill animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: initialProgress,
      end: initialProgress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    // Shine sweep animation (continuous, 2 seconds per sweep)
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    if (widget.animated) {
      _shineController.repeat();
    }

    // Pulse animation for near level-up
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse if near level-up
    _updatePulseState(initialProgress);
  }

  double _calculateProgress() {
    if (widget.maxXP <= 0) return 0;
    return (widget.currentXP / widget.maxXP).clamp(0.0, 1.0);
  }

  void _updatePulseState(double progress) {
    if (!widget.animated) return;

    if (progress >= _nearLevelUpThreshold && progress < 1.0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void didUpdateWidget(XpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newProgress = _calculateProgress();

    // Animate progress change
    if (oldWidget.currentXP != widget.currentXP ||
        oldWidget.maxXP != widget.maxXP) {
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));

      if (widget.animated) {
        _progressController.forward(from: 0);
      } else {
        _progressController.value = 1.0;
      }
      _previousProgress = newProgress;
    }

    // Update pulse state
    _updatePulseState(newProgress);

    // Handle animation toggle
    if (oldWidget.animated != widget.animated) {
      if (widget.animated) {
        _shineController.repeat();
        _updatePulseState(newProgress);
      } else {
        _shineController.stop();
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row with level and XP text
        if (widget.showLevel || widget.showXpText)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.showLevel)
                  _buildLevelBadge()
                else
                  const SizedBox.shrink(),
                if (widget.showXpText)
                  Text(
                    '${widget.currentXP} / ${widget.maxXP}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        // Progress bar
        AnimatedBuilder(
          animation: Listenable.merge([
            _progressAnimation,
            _shineController,
            _pulseAnimation,
          ]),
          builder: (context, child) {
            final progress = _progressAnimation.value.clamp(0.0, 1.0);
            final pulseScale = _pulseAnimation.value;

            return Transform.scale(
              scale: pulseScale,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(77),
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  border: Border.all(
                    color: AppColors.teal.withAlpha(51),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  child: Stack(
                    children: [
                      // Level markers
                      _buildLevelMarkers(),
                      // Gradient fill
                      _buildGradientFill(progress),
                      // Shine sweep overlay
                      if (widget.animated && progress > 0)
                        _buildShineOverlay(progress),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.teal.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.teal.withAlpha(102),
          width: 1,
        ),
      ),
      child: Text(
        'Level ${widget.level}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.teal,
        ),
      ),
    );
  }

  Widget _buildGradientFill(double progress) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: progress,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.teal, // #4ECDC4
              Color(0xFF45B7D1), // Sky Blue
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withAlpha(153),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShineOverlay(double progress) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shinePosition = _shineController.value;
          final barWidth = constraints.maxWidth * progress;
          final shineWidth = 40.0;

          // Calculate shine position within the filled area
          final shineX = (barWidth * shinePosition) - shineWidth / 2;

          return ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: shineX,
                  top: 0,
                  bottom: 0,
                  width: shineWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(0),
                          Colors.white.withAlpha(77),
                          Colors.white.withAlpha(128),
                          Colors.white.withAlpha(77),
                          Colors.white.withAlpha(0),
                        ],
                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelMarkers() {
    // Show markers at 25%, 50%, 75%
    return Row(
      children: [
        Expanded(flex: 25, child: Container()),
        _buildMarker(),
        Expanded(flex: 25, child: Container()),
        _buildMarker(),
        Expanded(flex: 25, child: Container()),
        _buildMarker(),
        Expanded(flex: 25, child: Container()),
      ],
    );
  }

  Widget _buildMarker() {
    return Container(
      width: 1,
      height: widget.height,
      color: Colors.white.withAlpha(38),
    );
  }
}
