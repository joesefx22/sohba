import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/prayer_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/athkar_provider.dart';
import '../../providers/title_provider.dart';
import '../../repositories/prayer_repository.dart';
import '../../repositories/qiyam_repository.dart';
import '../../services/prayer_engine.dart';
import '../../services/adhan_service.dart';
import '../../services/challenge_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badge_unlock_animation.dart';
import '../../widgets/error_state.dart';
import '../../widgets/prayer_complete_animation.dart';
import '../../widgets/ribbon_card.dart';

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
          color: AppColors.gold,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () => prayer.loadToday(auth.user!.id),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text('الصلاة', style: AppText.heading),
              const SizedBox(height: 4),
              Text('سجّل صلاتك في الوقت المناسب', style: AppText.caption),
              const SizedBox(height: 20),
              ...PrayerName.values.map((p) => _PrayerRow(prayer: p)),

              if (prayer.missedHistory.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.history,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'صلوات تحتاج متابعة',
                      style:
                          AppText.section.copyWith(color: AppColors.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...prayer.missedHistory.map(
                  (log) => _MissedPrayerCard(log: log),
                ),
              ],
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

  Color _accentFor(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.pending:
        return AppColors.gold;
      case PrayerStatus.congregation:
        return AppColors.emerald;
      case PrayerStatus.individual:
        return AppColors.mint;
      case PrayerStatus.qada:
        return AppColors.warning;
      case PrayerStatus.missed:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final log = provider.todayLogs[prayer] ??
        PrayerLog.empty(
          userId: '',
          date: provider.todayDate,
          prayer: prayer,
        );
    final timeline = provider.timelineFor(prayer);
    final now = DateTime.now();
    final phase = timeline.phaseAt(now);
    final accent = _accentFor(log.status);

    return RibbonCard(
      accent: accent,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: .35),
                  ),
                ),
                child: Icon(
                  prayer.icon,
                  color: log.status == PrayerStatus.pending
                      ? AppColors.goldBright
                      : log.status.color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.arabicName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'الأذان: ${AdhanService.formatTime(timeline.adhan)}',
                      style: AppText.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: log.status.color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: log.status.color.withValues(alpha: .55)),
                ),
                child: Text(
                  log.status.arabicLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
            _actionButtons(context, phase),
        ],
      ),
    );
  }

  Widget _phaseInfo(PrayerPhase phase, PrayerTimeline tl) {
    String text;
    switch (phase) {
      case PrayerPhase.beforeAdhan:
        text = 'يتبقى ${_fmt(tl.adhan.difference(DateTime.now()))} للأذان';
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
        text =
            'وقت القضاء — يتبقى ${_fmt(tl.qadaClose.difference(DateTime.now()))}';
        break;
      case PrayerPhase.missed:
        text = 'فاتت الصلاة — يمكنك التوبة والقضاء';
        break;
    }
    return Text(text, style: AppText.caption.copyWith(fontSize: 12));
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
              backgroundColor: AppColors.mint,
              foregroundColor: AppColors.background,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _actionButtons(BuildContext context, PrayerPhase phase) {
    final canCongregation = phase == PrayerPhase.congregationOpen;
    final canIndividual = phase == PrayerPhase.individualOpen ||
        phase == PrayerPhase.congregationOpen;
    final canQada = phase == PrayerPhase.qadaOpen;

    return Row(
      children: [
        if (canCongregation)
          Expanded(
            child: AppButton.primary(
              onPressed: () => _record(context, PrayerStatus.congregation),
              label: 'جماعة +27',
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.background,
            ),
          ),
        if (canCongregation || canIndividual) const SizedBox(width: 8),
        if (canIndividual)
          Expanded(
            child: AppButton.primary(
              onPressed: () => _record(context, PrayerStatus.individual),
              label: 'منفردًا +1',
              backgroundColor: AppColors.iman,
              foregroundColor: AppColors.background,
            ),
          ),
        if (canQada)
          Expanded(
            child: AppButton.primary(
              onPressed: () => _record(context, PrayerStatus.qada),
              label: 'قضاء',
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.background,
            ),
          ),
        if (!canCongregation && !canIndividual && !canQada)
          Expanded(
            child: Text(
              'لا يمكن التسجيل الآن',
              style: AppText.caption,
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
    final athkarProv = context.read<AthkarProvider>();

    final userId = auth.user!.id;

    final result = await prayerProv.recordPrayer(
      userId: userId,
      prayer: prayer,
      status: status,
    );

    if (!context.mounted) return;
    if (!result.success) {
      AppSnackbar.error(context, result.error ?? 'فشل التسجيل');
      return;
    }

    final milestone = await streakProv.recordActivity(userId: userId);
    await auth.refreshProfile();

    if (!context.mounted) return;

    await PrayerCompleteAnimation.show(
      context: context,
      prayer: prayer,
      status: status,
      hasanat: result.hasanat,
      streak: streakProv.currentStreak,
    );

    if (!context.mounted) return;

    if (milestone != null) {
      await notifProv.create(
        userId: userId,
        type: 'streak_milestone',
        title: 'مواصلة $milestone يوم!',
        message: 'ما شاء الله، استمر على الطاعة!',
        icon: 'local_fire_department',
      );
    }

    try {
      final prayerRepo = PrayerRepository(Supabase.instance.client);
      final recentLogs = await prayerRepo.getLogsInRange(
        userId: userId,
        from: DateTime.now().subtract(const Duration(days: 60)),
        to: DateTime.now(),
      );

      Map<String, Map<String, dynamic>> qiyamData = {};
      try {
        final qiyamRepo = QiyamRepository(Supabase.instance.client);
        qiyamData = await qiyamRepo.getRange(userId: userId, days: 60);
      } catch (e) {
        debugPrint('Qiyam load failed: $e');
      }

      if (!context.mounted) return;

      final mandatoryItems = athkarProv.allMandatoryItems;
      final unlocked = await badgeProv.evaluateAndUnlock(
        userId: userId,
        recentLogs: recentLogs,
        athkarItemsToday: mandatoryItems,
        athkarCompletedToday: athkarProv.progressMapFor(mandatoryItems),
        qiyamLogsByDate: qiyamData,
      );

      try {
        final titleProv = context.read<TitleProvider>();
        await titleProv.syncFromBadges(userId, badgeProv.unlockedIds);
      } catch (e) {
        debugPrint('Title sync error: $e');
      }

      for (final badge in unlocked) {
        if (!context.mounted) break;
        await BadgeUnlockAnimation.show(context: context, badge: badge);
        await notifProv.create(
          userId: userId,
          type: 'badge_unlock',
          title: 'ميدالية: ${badge.nameAr}',
          message: badge.description,
          icon: badge.icon,
        );
      }
    } catch (e) {
      debugPrint('Badge evaluation error: $e');
    }

    if (!context.mounted) return;

    try {
      await ChallengeService.advanceOnPrayer(
        userId: userId,
        prayer: prayer.name,
      );
    } catch (e) {
      debugPrint('Challenge advance error: $e');
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
      await auth.refreshProfile();
      if (!context.mounted) return;
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

class PrayerDetailPage extends StatelessWidget {
  final PrayerName prayer;
  const PrayerDetailPage({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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

class _MissedPrayerCard extends StatelessWidget {
  final PrayerLog log;
  const _MissedPrayerCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isQada = log.status == PrayerStatus.qada;
    final color = isQada ? AppColors.emerald : AppColors.warning;
    final dateLabel =
        '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-'
        '${log.date.day.toString().padLeft(2, '0')}';

    return RibbonCard(
      accent: color,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isQada ? Icons.check_circle : Icons.warning_amber_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.prayer.arabicName} — $dateLabel',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  isQada
                      ? 'تم القضاء والتوبة'
                      : 'لم تُسجَّل — ${log.sayyiat} سيئة',
                  style: AppText.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (!isQada)
            TextButton(
              onPressed: () => _markQada(context),
              child: Text('قضاء',
                  style: TextStyle(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Future<void> _markQada(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<PrayerProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('تأكيد القضاء',
            style: TextStyle(color: AppColors.text)),
        content: Text(
          'هل صليت ${log.prayer.arabicName} قضاءً عن يوم '
          '${log.date.day}/${log.date.month}؟',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.background,
            ),
            child: const Text('نعم، صليتها'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final r = await provider.recordQadaForDate(
      userId: auth.user!.id,
      prayer: log.prayer,
      date: log.date,
    );
    if (!context.mounted) return;
    if (r.success) {
      await auth.refreshProfile();
      if (!context.mounted) return;
      AppSnackbar.success(context, 'تم قبول القضاء إن شاء الله');
    } else {
      AppSnackbar.error(context, r.error ?? 'فشل');
    }
  }
}