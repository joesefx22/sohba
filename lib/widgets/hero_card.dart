import 'package:flutter/material.dart';
import '../models/hero.dart' as app;
import '../services/level_service.dart';
import '../theme/app_colors.dart';

class HeroCard extends StatefulWidget {
  final app.Hero hero;
  final bool compact;
  final VoidCallback? onTap;

  const HeroCard({
    super.key,
    required this.hero,
    this.compact = false,
    this.onTap,
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _xpAnimationController;
  late Animation<double> _xpAnimation;
  double _previousXpProgress = 0;

  @override
  void initState() {
    super.initState();
    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _previousXpProgress = widget.hero.xpProgress;
    _xpAnimation = Tween<double>(
      begin: _previousXpProgress,
      end: _previousXpProgress,
    ).animate(CurvedAnimation(
      parent: _xpAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(HeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hero.xpProgress != widget.hero.xpProgress) {
      _xpAnimation = Tween<double>(
        begin: _previousXpProgress,
        end: widget.hero.xpProgress,
      ).animate(CurvedAnimation(
        parent: _xpAnimationController,
        curve: Curves.easeOutCubic,
      ));
      _xpAnimationController.forward(from: 0);
      _previousXpProgress = widget.hero.xpProgress;
    }
  }

  @override
  void dispose() {
    _xpAnimationController.dispose();
    super.dispose();
  }

  /// Returns gradient colors based on hero level tier
  List<Color> _getLevelTierGradient() {
    final level = widget.hero.level;
    if (level <= 10) {
      // Novice - Green/Teal
      return [const Color(0xFF2D4A3E), const Color(0xFF1A3A2E)];
    } else if (level <= 25) {
      // Apprentice - Blue
      return [const Color(0xFF2A3F5F), const Color(0xFF1A2B4A)];
    } else if (level <= 50) {
      // Champion - Purple
      return [const Color(0xFF3D2A5F), const Color(0xFF2A1B4A)];
    } else {
      // Legend - Gold/Orange
      return [const Color(0xFF5F4A2A), const Color(0xFF4A3A1B)];
    }
  }

  /// Returns glow color based on hero level tier
  Color _getLevelTierGlow() {
    return LevelService.colorForLevel(widget.hero.level);
  }

  /// Returns avatar background color based on appearance
  Color _getAvatarColor() {
    final skinColor = widget.hero.appearance.skinColor.toLowerCase();
    switch (skinColor) {
      case 'light':
        return const Color(0xFFFFDBB4);
      case 'medium':
        return const Color(0xFFD4A574);
      case 'dark':
        return const Color(0xFF8B6F47);
      default:
        return AppColors.primaryStart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getLevelTierGradient();
    final glowColor = _getLevelTierGlow();
    final title = LevelService.titleForLevel(widget.hero.level);

    if (widget.compact) {
      return _buildCompactCard(gradientColors, glowColor, title);
    }

    return _buildFullCard(gradientColors, glowColor, title);
  }

  Widget _buildFullCard(
    List<Color> gradientColors,
    Color glowColor,
    String title,
  ) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: glowColor.withAlpha(128),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withAlpha(77),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(size: 80),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.hero.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Level + Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: glowColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: glowColor.withAlpha(128),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Level ${widget.hero.level}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: glowColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(179),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // XP Progress Bar
                    _buildXpProgressBar(glowColor),
                    const SizedBox(height: 12),
                    // Streak
                    if (widget.hero.currentStreak > 0) _buildStreakDisplay(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(
    List<Color> gradientColors,
    Color glowColor,
    String title,
  ) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: glowColor.withAlpha(102),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withAlpha(51),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(size: 48),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      widget.hero.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Level + Title
                    Text(
                      'Lvl ${widget.hero.level} • $title',
                      style: TextStyle(
                        fontSize: 12,
                        color: glowColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Streak
              if (widget.hero.currentStreak > 0) ...[
                const SizedBox(width: 8),
                _buildStreakBadge(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({required double size}) {
    final avatarColor = _getAvatarColor();
    final initial = widget.hero.name.isNotEmpty
        ? widget.hero.name[0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            avatarColor,
            avatarColor.withAlpha(204),
          ],
        ),
        border: Border.all(
          color: Colors.white.withAlpha(77),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withAlpha(102),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(77),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpProgressBar(Color glowColor) {
    return AnimatedBuilder(
      animation: _xpAnimation,
      builder: (context, child) {
        final progress = _xpAnimation.value.clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(153),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${widget.hero.currentXP} / ${widget.hero.xpToNextLevel}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(153),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(77),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.teal,
                            AppColors.teal,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withAlpha(128),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakDisplay() {
    return Row(
      children: [
        const Icon(
          Icons.local_fire_department,
          size: 20,
          color: AppColors.primaryStart,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.hero.currentStreak} Tage',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryStart,
          ),
        ),
        if (widget.hero.longestStreak > widget.hero.currentStreak) ...[
          const SizedBox(width: 8),
          Text(
            'Best: ${widget.hero.longestStreak}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withAlpha(128),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryStart.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryStart.withAlpha(128),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 14,
            color: AppColors.primaryStart,
          ),
          const SizedBox(width: 2),
          Text(
            '${widget.hero.currentStreak}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryStart,
            ),
          ),
        ],
      ),
    );
  }
}
