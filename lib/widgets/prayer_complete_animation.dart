import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/prayer_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Calm success moment (~1.1s): check appears -> "+N حسنات" -> drifts up
/// toward the hasanat counter -> streak pulse -> auto-close. No confetti,
/// no elastic curves. Tap anywhere to dismiss early.
/// Public API unchanged.
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _card, _check, _points, _streak, _fly;
  bool _closed = false;

  Animation<double> _iv(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: c));

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _card = _iv(0.0, 0.25);
    _check = _iv(0.08, 0.38);
    _points = _iv(0.32, 0.58);
    _streak = _iv(0.55, 0.85, Curves.linear);
    _fly = _iv(0.68, 1.0, Curves.easeInCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      HapticFeedback.lightImpact();
      await _c.forward();
    }
    await Future.delayed(const Duration(milliseconds: 300));
    _close();
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                    color: Colors.black
                        .withAlpha((150 * _card.value).round())),
              ),
              Center(
                child: Opacity(
                  opacity: _card.value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - _card.value)),
                    child: Transform.scale(
                      scale: 0.96 + 0.04 * _card.value,
                      child: _buildCard(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final pulse = 1 + 0.08 * sin(pi * _streak.value);
    final count = (widget.hasanat * _points.value).round();

    return Container(
      width: 270,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.emerald.withAlpha(60)),
        boxShadow: [
          BoxShadow(
              color: AppColors.emerald.withAlpha(40),
              blurRadius: 30,
              spreadRadius: -4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: _check.value,
            child: Transform.scale(
              scale: 0.85 + 0.15 * _check.value,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald.withAlpha(30),
                  border: Border.all(color: AppColors.emerald.withAlpha(120)),
                ),
                child: const Icon(Icons.check, size: 38, color: AppColors.mint),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.prayer.arabicName,
              style: AppText.heading.copyWith(fontSize: 24)),
          const SizedBox(height: 2),
          Text(widget.status.arabicLabel,
              style: AppText.body.copyWith(color: widget.status.color)),
          const SizedBox(height: 4),
          Text('تقبّل الله', style: AppText.caption.copyWith(fontSize: 13)),
          if (widget.hasanat > 0) ...[
            const SizedBox(height: 18),
            Opacity(
              opacity: (_points.value * (1 - _fly.value)).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -56 * _fly.value),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 18, color: AppColors.goldBright),
                    const SizedBox(width: 8),
                    Text('+$count',
                        style: AppText.number
                            .copyWith(fontSize: 30, color: AppColors.gold)),
                    const SizedBox(width: 6),
                    Text('حسنات',
                        style: AppText.body.copyWith(color: AppColors.gold)),
                  ],
                ),
              ),
            ),
          ],
          if (widget.streak != null && widget.streak! > 0) ...[
            const SizedBox(height: 14),
            Transform.scale(
              scale: pulse,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department,
                      size: 18, color: AppColors.streak),
                  const SizedBox(width: 4),
                  Text('${widget.streak} يوم متواصل',
                      style: AppText.caption.copyWith(
                          color: AppColors.streak,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}