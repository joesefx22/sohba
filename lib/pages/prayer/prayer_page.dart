import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../services/adhan_service.dart';
import '../../services/prayer_engine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/ribbon_card.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () => prayer.load(),
          child: _buildBody(prayer),
        ),
      ),
    );
  }

  Widget _buildBody(PrayerProvider prayer) {
    if (prayer.loading && prayer.statuses.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final now = DateTime.now();
    final arrived = PrayerEngine.arrivedPrayers(
      date: prayer.selectedDate,
      now: now,
    );
    final times = AdhanService.timesForDate(prayer.selectedDate);

    if (arrived.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('الصلاة', style: AppText.heading),
          const SizedBox(height: 4),
          Text('لم يأذّن أي صلاة بعد اليوم', style: AppText.caption),
          const SizedBox(height: 120),
          const Center(
            child: Icon(Icons.wb_twilight,
                size: 80, color: AppColors.gold),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'استعد لصلاة الفجر',
              style: AppText.section.copyWith(fontSize: 18),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('الصلاة', style: AppText.heading),
        const SizedBox(height: 4),
        Text('صلوات اليوم — سجّل كل صلاة قبل فجر اليوم التالي',
            style: AppText.caption),
        const SizedBox(height: 20),
        for (final p in arrived)
          _PrayerRow(
            prayer: p,
            status: prayer.statuses[p] ?? PrayerStatus.pending,
            adhanTime: times[p]!,
            onCongregation: () =>
                _record(context, prayer, p, congregation: true),
            onIndividual: () =>
                _record(context, prayer, p, congregation: false),
          ),
      ],
    );
  }

  Future<void> _record(
    BuildContext context,
    PrayerProvider prov,
    PrayerName prayer, {
    required bool congregation,
  }) async {
    final ok = await prov.record(prayer, congregation: congregation);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهى وقت هذه الصلاة')),
      );
      return;
    }
    // تحديث الـ profile عشان الحسنات تظهر في الداشبورد
    try {
      await context.read<AuthProvider>().refreshProfile();
    } catch (_) {}
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.status,
    required this.adhanTime,
    required this.onCongregation,
    required this.onIndividual,
  });

  final PrayerName prayer;
  final PrayerStatus status;
  final DateTime adhanTime;
  final VoidCallback onCongregation;
  final VoidCallback onIndividual;

  @override
  Widget build(BuildContext context) {
    final accent = status.color;
    final canRecord = status.isRecordable;

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
                child: Icon(prayer.icon, color: accent, size: 26),
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
                      'الأذان: ${AdhanService.formatTime(adhanTime)}',
                      style: AppText.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: .55)),
                ),
                child: Text(
                  status.arabicLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (canRecord)
            Row(
              children: [
                Expanded(
                  child: _btn(
                    label: 'صليت جماعة',
                    color: AppColors.emerald,
                    onTap: onCongregation,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _btn(
                    label: 'صليت فردي',
                    color: AppColors.mint,
                    onTap: onIndividual,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  status == PrayerStatus.missed
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  color: accent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  status == PrayerStatus.missed
                      ? 'فاتت — 200 سيئة'
                      : 'تم التسجيل',
                  style: AppText.caption.copyWith(color: accent),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _btn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}