import 'package:flutter/material.dart';
import '../services/streak_service.dart';
import '../theme/app_colors.dart';

enum StreakWidgetVariant { compact, expanded }

class StreakWidget extends StatefulWidget {
  final int streak;
  final StreakWidgetVariant variant;
  final List<DateTime>? activityDates;
  final VoidCallback? onTap;

  const StreakWidget({
    super.key,
    required this.streak,
    this.variant = StreakWidgetVariant.compact,
    this.activityDates,
    this.onTap,
  });

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget>
    with TickerProviderStateMixin {
  static const Color fireColor = AppColors.primaryStart;
  static const Color fireColorBright = AppColors.primaryEnd;
  static const Color inactiveColor = AppColors.surfaceElevated;

  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  int _previousStreak = 0;

  @override
  void initState() {
    super.initState();
    _previousStreak = widget.streak;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(StreakWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak > _previousStreak) {
      _shakeController.forward(from: 0);
    }
    _previousStreak = widget.streak;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: widget.variant == StreakWidgetVariant.compact
          ? _buildCompact()
          : _buildExpanded(),
    );
  }

  Widget _buildCompact() {
    final bonusPercent = StreakService.streakBonusPercent(widget.streak);

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = _shakeAnimation.value * 3 *
            ((_shakeAnimation.value * 10).toInt() % 2 == 0 ? 1 : -1);

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: widget.streak > 0
                  ? const LinearGradient(
                      colors: [fireColor, fireColorBright],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.streak == 0 ? inactiveColor : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.streak > 0
                  ? [
                      BoxShadow(
                        color: fireColor.withAlpha(100),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.streak > 0 ? _pulseAnimation.value : 1.0,
                      child: Icon(
                        widget.streak > 0
                            ? Icons.local_fire_department
                            : Icons.air,
                        color: widget.streak > 0
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.streak}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (bonusPercent > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$bonusPercent%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpanded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get start of current week (Monday)
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final startOfWeek = today.subtract(Duration(days: weekday - 1));

    // Normalize activity dates to midnight
    final activitySet = widget.activityDates
            ?.map((d) => DateTime(d.year, d.month, d.day))
            .toSet() ??
        {};

    final bonusPercent = StreakService.streakBonusPercent(widget.streak);
    final nextMilestone = StreakService.nextMilestone(widget.streak);
    final progress = StreakService.progressToNextMilestone(widget.streak);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.streak > 0
              ? fireColor.withAlpha(77)
              : Colors.white.withAlpha(26),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.streak > 0 ? _pulseAnimation.value : 1.0,
                    child: Icon(
                      widget.streak > 0
                          ? Icons.local_fire_department
                          : Icons.air,
                      color: widget.streak > 0
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      size: 32,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${widget.streak} Tage',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (bonusPercent > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [fireColor, fireColorBright],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+$bonusPercent% Bonus',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    StreakService.streakMessage(widget.streak),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Week view
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = startOfWeek.add(Duration(days: index));
              final isToday = day == today;
              final isFuture = day.isAfter(today);
              final hasActivity = activitySet.contains(day);
              final dayLabel = _getDayLabel(index);

              return _buildDayCircle(
                label: dayLabel,
                isToday: isToday,
                isFuture: isFuture,
                hasActivity: hasActivity,
              );
            }),
          ),

          // Next milestone progress
          if (nextMilestone != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nächster Meilenstein',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(153),
                            ),
                          ),
                          Text(
                            '$nextMilestone Tage',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(153),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withAlpha(26),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            fireColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCircle({
    required String label,
    required bool isToday,
    required bool isFuture,
    required bool hasActivity,
  }) {
    final Color circleColor;
    final Color textColor;
    final bool showGlow;

    if (isFuture) {
      circleColor = Colors.transparent;
      textColor = Colors.white.withAlpha(77);
      showGlow = false;
    } else if (hasActivity) {
      circleColor = fireColor;
      textColor = Colors.white;
      showGlow = true;
    } else {
      circleColor = inactiveColor;
      textColor = Colors.white.withAlpha(128);
      showGlow = false;
    }

    Widget circle = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor,
        border: isFuture
            ? Border.all(color: Colors.white.withAlpha(51), width: 2)
            : null,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: fireColor.withAlpha(128),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Center(
        child: hasActivity && !isFuture
            ? const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 18,
              )
            : null,
      ),
    );

    // Pulse animation for today
    if (isToday && !isFuture) {
      circle = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * 0.9 + 0.1,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasActivity ? fireColor : AppColors.teal,
                border: Border.all(
                  color: Colors.white.withAlpha(128),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (hasActivity ? fireColor : AppColors.teal)
                        .withAlpha(128),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Center(
                child: hasActivity
                    ? const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 18,
                      )
                    : const Text('?', style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        circle,
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.white : textColor,
          ),
        ),
      ],
    );
  }

  String _getDayLabel(int index) {
    const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return labels[index];
  }
}
