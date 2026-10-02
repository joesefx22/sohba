import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/badge.dart';
import '../../services/prayer_engine.dart';
import '../../services/adhan_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/prayer_complete_animation.dart';
import '../../widgets/badge_unlock_animation.dart';
import '../../widgets/error_state.dart';
import '../../widgets/app_button.dart';

/// Full-page prayer view with action buttons per window.
class PrayerPage extends StatelessWidget {
  const PrayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => prayer.loadToday(auth.user!.id),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'الصلاة',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'سجّل صلاتك في الوقت المناسب',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ...PrayerName.values.map((p) => _PrayerRow(prayer: p)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final PrayerName prayer;
  const _PrayerRow({required this.prayer});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final auth = context.read<AuthProvider>();
    final log = provider.todayLogs[prayer]!;
    final timeline = provider.timelineFor(prayer);
    final now = DateTime.now();
    final phase = timeline.phaseAt(now);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(prayer.icon,
                  color: log.status == PrayerStatus.pending
                      ? AppColors.textSecondary
                      : log.status.color,
                  size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.arabicName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'الأذان: ${AdhanService.formatTime(timeline.adhan)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: log.status.color.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: log.status.color.withAlpha(150)),
                ),
                child: Text(
                  log.status.arabicLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: log.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _phaseInfo(phase, timeline),
          const SizedBox(height: 14),
          if (log.isRecorded)
            _recordedActions(context, log)
          else
            _actionButtons(context, phase, provider, auth),
        ],
      ),
    );
  }

  Widget _phaseInfo(PrayerPhase phase, PrayerTimeline tl) {
    String text;
    switch (phase) {
      case PrayerPhase.beforeAdhan:
        text =
            'يتبقى ${_fmt(tl.adhan.difference(DateTime.now()))} للأذان';
        break;
      case PrayerPhase.waitingForCongregation:
        text =
            'وقت الجماعة يفتح بعد ${_fmt(tl.congregationOpen.difference(DateTime.now()))}';
        break;
      case PrayerPhase.congregationOpen:
        text =
            'وقت الجماعة — يتبقى ${_fmt(tl.congregationClose.difference(DateTime.now()))}';
        break;
      case PrayerPhase.individualOpen:
        text =
            'وقت الانفراد — يتبقى ${_fmt(tl.individualClose.difference(DateTime.now()))}';
        break;
      case PrayerPhase.qadaOpen:
        text = 'وقت القضاء — يتبقى ${_fmt(tl.qadaClose.difference(DateTime.now()))}';
        break;
      case PrayerPhase.missed:
        text = 'فاتت الصلاة — يمكنك التوبة والقضاء';
        break;
    }
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    );
  }

  Widget _recordedActions(BuildContext context, PrayerLog log) {
    if (log.hasUnrepentedSayyiat) {
      return Row(
        children: [
          Expanded(
            child: AppButton.primary(
              onPressed: () => _markRepented(context),
              label: 'توبة',
              icon: Icons.replay,
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _actionButtons(
    BuildContext context,
    PrayerPhase phase,
    PrayerProvider provider,
    AuthProvider auth,
  ) {
    final canCongregation = phase == PrayerPhase.congregationOpen;
    final canIndividual = phase == PrayerPhase.individualOpen ||
        phase == PrayerPhase.congregationOpen;
    final canQada = phase == PrayerPhase.qadaOpen;

    return Row(
      children: [
        if (canCongregation)
          Expanded(
            child: AppButton.primary(
              onPressed: () =>
                  _record(context, PrayerStatus.congregation),
              label: 'جماعة +27',
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        if (canCongregation || canIndividual) const SizedBox(width: 8),
        if (canIndividual)
          Expanded(
            child: AppButton.primary(
              onPressed: () => _record(context, PrayerStatus.individual),
              label: 'منفردًا +1',
              backgroundColor: AppColors.rarityRare,
              foregroundColor: Colors.white,
            ),
          ),
        if (canQada)
          Expanded(
            child: AppButton.primary(
              onPressed: () => _record(context, PrayerStatus.qada),
              label: 'قضاء',
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black87,
            ),
          ),
        if (!canCongregation && !canIndividual && !canQada)
          const Expanded(
            child: Text(
              'لا يمكن التسجيل الآن',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Future<void> _record(BuildContext context, PrayerStatus status) async {
    final auth = context.read<AuthProvider>();
    final prayerProv = context.read<PrayerProvider>();
    final streakProv = context.read<StreakProvider>();
    final badgeProv = context.read<BadgeProvider>();
    final notifProv = context.read<NotificationProvider>();

    final result = await prayerProv.recordPrayer(
      userId: auth.user!.id,
      prayer: prayer,
      status: status,
    );

    if (!context.mounted) return;

    if (!result.success) {
      AppSnackbar.error(context, result.error ?? 'فشل التسجيل');
      return;
    }

    // Show animation
    await PrayerCompleteAnimation.show(
      context: context,
      prayer: prayer,
      status: status,
      hasanat: result.hasanat,
      streak: streakProv.currentStreak,
    );

    // Update streak
    final milestone =
        await streakProv.recordActivity(userId: auth.user!.id);

    // Notify milestone
    if (milestone != null) {
      await notifProv.create(
        userId: auth.user!.id,
        type: 'streak_milestone',
        title: 'مواصلة $milestone يوم!',
        message: 'ما شاء الله، استمر على الطاعة!',
        icon: 'local_fire_department',
      );
    }

    // Check badges
    final unlocked = await badgeProv.checkConditions(
      userId: auth.user!.id,
      context: BadgeContext(overallStreak: streakProv.currentStreak),
    );

    for (final badge in unlocked) {
      if (!context.mounted) break;
      await BadgeUnlockAnimation.show(context: context, badge: badge);
      await notifProv.create(
        userId: auth.user!.id,
        type: 'badge_unlock',
        title: 'ميدالية: ${badge.nameAr}',
        message: badge.description,
        icon: badge.icon,
      );
    }
  }

  Future<void> _markRepented(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final prayerProv = context.read<PrayerProvider>();

    final r = await prayerProv.markRepented(
      userId: auth.user!.id,
      prayer: prayer,
    );

    if (!context.mounted) return;

    if (r.success) {
      AppSnackbar.success(context, 'تم قبول التوبة إن شاء الله');
    } else {
      AppSnackbar.error(context, r.error ?? 'فشل');
    }
  }

  String _fmt(Duration d) {
    if (d.isNegative) return 'الآن';
    if (d.inHours > 0) return '${d.inHours}س ${d.inMinutes % 60}د';
    return '${d.inMinutes}د';
  }
}

// ═══════════════════════════════════════════════════════════════════
// PRAYER DETAIL PAGE (opened from Home card tap)
// ═══════════════════════════════════════════════════════════════════

class PrayerDetailPage extends StatelessWidget {
  final PrayerName prayer;
  const PrayerDetailPage({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      appBar: AppBar(
        title: Text(prayer.arabicName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _PrayerRow(prayer: prayer),
      ),
    );
  }
}