import 'dart:async';
import 'package:flutter/material.dart';
import '../models/prayer_log.dart';
import '../services/prayer_engine.dart';
import '../services/adhan_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';
import 'press_scale.dart';
import 'prayer_status_chip.dart';

String _fmt(Duration d) {
  if (d.isNegative) return 'الآن';
  if (d.inHours > 0) return '${d.inHours}س ${d.inMinutes % 60}د';
  return '${d.inMinutes}د';
}

/// Short, live hint for the current phase.
String prayerPhaseHint(PrayerPhase phase, PrayerTimeline tl, DateTime now) {
  switch (phase) {
    case PrayerPhase.beforeAdhan:
      return 'يتبقى ${_fmt(tl.adhan.difference(now))} للأذان';
    case PrayerPhase.waitingForCongregation:
      return 'الجماعة بعد ${_fmt(tl.congregationOpen.difference(now))}';
    case PrayerPhase.congregationOpen:
      return 'وقت الجماعة — ${_fmt(tl.congregationClose.difference(now))}';
    case PrayerPhase.individualOpen:
      return 'وقت الانفراد — ${_fmt(tl.individualClose.difference(now))}';
    case PrayerPhase.qadaOpen:
      return 'وقت القضاء — ${_fmt(tl.qadaClose.difference(now))}';
    case PrayerPhase.missed:
      return 'فاتت الصلاة — يمكنك التوبة والقضاء';
  }
}

/// One prayer. `isCurrent: true` renders the hero version (bigger icon,
/// glow, live countdown, CTA). Default = compact row. Constructor is
/// backwards compatible.
class PrayerCard extends StatelessWidget {
  final PrayerName prayer;
  final PrayerLog log;
  final PrayerTimeline timeline;
  final VoidCallback onTap;
  final bool isCurrent;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.log,
    required this.timeline,
    required this.onTap,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) =>
      isCurrent ? _hero(context) : _compact(context);

  // ── Compact ────────────────────────────────────────────────
  Widget _compact(BuildContext context) {
    final phase = timeline.phaseAt(DateTime.now());
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: log.status.color.withAlpha(36),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              prayer.icon,
              size: 22,
              color: log.status == PrayerStatus.pending
                  ? AppColors.textSecondary
                  : log.status.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prayer.arabicName,
                    style: AppText.section.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(AdhanService.formatTime(timeline.adhan),
                    style: AppText.caption.copyWith(fontSize: 13)),
                if (phase == PrayerPhase.congregationOpen &&
                    !log.isRecorded) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.emerald, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('وقت الجماعة مفتوح',
                          style: AppText.caption.copyWith(
                              color: AppColors.mint,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PrayerStatusChip(status: log.status),
        ],
      ),
    );
  }

  // ── Hero (current prayer) ──────────────────────────────────
  Widget _hero(BuildContext context) {
    final phase = timeline.phaseAt(DateTime.now());
    final label =
        phase == PrayerPhase.beforeAdhan ? 'الصلاة القادمة' : 'الصلاة الآن';

    return GlassContainer(
      level: GlassLevel.featured,
      borderRadius: 24,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(prayer.icon, size: 32, color: AppColors.mint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppText.caption.copyWith(
                            color: AppColors.mint,
                            fontWeight: FontWeight.w600)),
                    Text(prayer.arabicName,
                        style: AppText.heading.copyWith(fontSize: 26)),
                  ],
                ),
              ),
              PrayerStatusChip(status: log.status),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AdhanService.formatTime(timeline.adhan),
                  style: AppText.number.copyWith(fontSize: 34)),
              const Spacer(),
              Flexible(
                child: _LivePhaseHint(timeline: timeline),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!log.isRecorded)
            PressScale(
              onTap: onTap,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.progressGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('سجّل صلاتك',
                    style: AppText.section.copyWith(
                        fontSize: 16, color: AppColors.background)),
              ),
            )
          else
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 20, color: AppColors.mint),
                const SizedBox(width: 8),
                Text('تم تسجيل الصلاة',
                    style: AppText.body.copyWith(color: AppColors.mint)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Re-renders the countdown every 30s without touching providers.
class _LivePhaseHint extends StatefulWidget {
  const _LivePhaseHint({required this.timeline});
  final PrayerTimeline timeline;

  @override
  State<_LivePhaseHint> createState() => _LivePhaseHintState();
}

class _LivePhaseHintState extends State<_LivePhaseHint> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Text(
      prayerPhaseHint(widget.timeline.phaseAt(now), widget.timeline, now),
      textAlign: TextAlign.end,
      style: AppText.caption.copyWith(fontSize: 13),
    );
  }
}