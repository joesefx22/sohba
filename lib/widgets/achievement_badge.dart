import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/achievement.dart';
import '../theme/app_icons.dart';

enum AchievementBadgeSize { small, medium, large }

class AchievementBadge extends StatefulWidget {
  final Achievement achievement;
  final AchievementProgress? progress;
  final AchievementBadgeSize size;
  final bool showName;
  final bool isNewlyUnlocked;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.progress,
    this.size = AchievementBadgeSize.medium,
    this.showName = true,
    this.isNewlyUnlocked = false,
    this.onTap,
  });

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Shimmer animation for unlocked badges
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Particle animation for newly unlocked
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    // Pulse animation for in-progress
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    if (_isUnlocked) {
      _shimmerController.repeat();
      if (widget.isNewlyUnlocked) {
        _particleController.forward();
      }
    }
  }

  @override
  void didUpdateWidget(AchievementBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNewlyUnlocked && !oldWidget.isNewlyUnlocked) {
      _particleController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isUnlocked => widget.progress?.isUnlocked ?? false;
  bool get _isInProgress =>
      widget.progress != null &&
      !_isUnlocked &&
      widget.progress!.currentProgress > 0;
  bool get _isLocked => !_isUnlocked && !_isInProgress;

  double get _badgeSize {
    switch (widget.size) {
      case AchievementBadgeSize.small:
        return 48;
      case AchievementBadgeSize.medium:
        return 72;
      case AchievementBadgeSize.large:
        return 96;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AchievementBadgeSize.small:
        return 20;
      case AchievementBadgeSize.medium:
        return 32;
      case AchievementBadgeSize.large:
        return 44;
    }
  }

  double get _borderWidth {
    switch (widget.size) {
      case AchievementBadgeSize.small:
        return 2;
      case AchievementBadgeSize.medium:
        return 3;
      case AchievementBadgeSize.large:
        return 4;
    }
  }

  Color get _tierColor => widget.achievement.tierColor;

  Color get _tierColorDark {
    final hsl = HSLColor.fromColor(_tierColor);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBadge(),
          if (widget.showName) ...[
            SizedBox(height: widget.size == AchievementBadgeSize.small ? 4 : 8),
            _buildName(),
          ],
          if (_isInProgress && widget.size != AchievementBadgeSize.small) ...[
            const SizedBox(height: 4),
            _buildProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge() {
    Widget badge = Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect for unlocked
        if (_isUnlocked)
          Container(
            width: _badgeSize + 8,
            height: _badgeSize + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _tierColor.withAlpha(100),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

        // Main badge
        AnimatedBuilder(
          animation: _isInProgress ? _pulseAnimation : _shimmerAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isInProgress ? _pulseAnimation.value : 1.0,
              child: Container(
                width: _badgeSize,
                height: _badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isLocked
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey.shade700,
                            Colors.grey.shade800,
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _tierColor,
                            _tierColorDark,
                          ],
                        ),
                  border: Border.all(
                    color: _isLocked
                        ? Colors.grey.shade600
                        : _tierColor,
                    width: _borderWidth,
                  ),
                  boxShadow: _isUnlocked
                      ? [
                          BoxShadow(
                            color: _tierColor.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background pattern
                      if (!_isLocked) _buildBackgroundPattern(),

                      // Icon
                      _buildIcon(),

                      // Shimmer overlay for unlocked
                      if (_isUnlocked) _buildShimmer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Progress ring for in-progress
        if (_isInProgress) _buildProgressRing(),

        // Particles for newly unlocked
        if (widget.isNewlyUnlocked) _buildParticles(),
      ],
    );

    return badge;
  }

  Widget _buildBackgroundPattern() {
    return Opacity(
      opacity: 0.1,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white,
              Colors.white.withAlpha(0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    // Show question mark for locked secret achievements
    final bool showSecretIcon =
        _isLocked && widget.achievement.isSecret;

    if (showSecretIcon) {
      return Icon(Icons.help_outline, size: _iconSize, color: Colors.grey.shade500);
    }
    return Icon(
      AppIcons.get(widget.achievement.icon),
      size: _iconSize,
      color: _isLocked ? Colors.grey.shade500 : Colors.white,
    );
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            width: _badgeSize,
            height: _badgeSize,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildProgressRing() {
    final progress = widget.progress!.progressPercent;

    return SizedBox(
      width: _badgeSize + 4,
      height: _badgeSize + 4,
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 3,
        backgroundColor: Colors.white.withAlpha(26),
        valueColor: AlwaysStoppedAnimation<Color>(_tierColor),
      ),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(_badgeSize + 40, _badgeSize + 40),
          painter: _ParticlePainter(
            progress: _particleAnimation.value,
            color: _tierColor,
            particleCount: 12,
          ),
        );
      },
    );
  }

  Widget _buildName() {
    final fontSize = widget.size == AchievementBadgeSize.small ? 10.0 : 12.0;
    final maxWidth = widget.size == AchievementBadgeSize.small ? 60.0 : 80.0;

    // Show "???" for locked secret achievements
    final displayName = _isLocked && widget.achievement.isSecret
        ? '???'
        : widget.achievement.name;

    return SizedBox(
      width: maxWidth,
      child: Text(
        displayName,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: _isLocked
              ? Colors.white.withAlpha(102)
              : Colors.white.withAlpha(230),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = widget.progress!;
    final fontSize = widget.size == AchievementBadgeSize.medium ? 10.0 : 12.0;

    return Text(
      '${progress.currentProgress}/${progress.targetProgress}',
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white.withAlpha(153),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount;

  _ParticlePainter({
    required this.progress,
    required this.color,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = maxRadius * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final particleCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      final paint = Paint()
        ..color = color.withAlpha((opacity * 255).toInt())
        ..style = PaintingStyle.fill;

      final particleSize = 4.0 * (1.0 - progress * 0.5);
      canvas.drawCircle(particleCenter, particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
