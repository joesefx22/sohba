import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/badge.dart';
import '../../models/prayer_log.dart';
import '../../providers/athkar_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/daily_lesson_provider.dart';
import '../../providers/habit_streak_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/title_provider.dart';
import '../../services/prayer_engine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/iman_progress_bar.dart';
import '../../widgets/streak_protection_sheet.dart';
import '../athkar/athkar_detail_page.dart';
import '../lessons/daily_lesson_page.dart';
import '../prayer/prayer_page.dart';
import '../qiyam/qiyam_page.dart';
import '../titles/titles_page.dart';

class DashboardV2 extends StatelessWidget {
  const DashboardV2({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prayer = context.watch<PrayerProvider>();
    final athkar = context.watch<AthkarProvider>();
    final streak = context.watch<StreakProvider>();
    final lesson = context.watch<DailyLessonProvider>();
    final badges = context.watch<BadgeProvider>();
    final habits = context.watch<HabitStreakProvider>();
    final titles = context.watch<TitleProvider>();

    final profile = auth.profile;
    final iman = ((profile?['iman'] ?? 0) as num).toDouble();
    final hasanat = (profile?['total_hasanat'] ?? 0) as int;
    final sayyiat = (profile?['total_sayyiat_unrepented'] ?? 0) as int;

    final level = (iman / 100).floor() + 1;
    final progressInLevel = (iman % 100) / 100.0;
    final remaining = 100 - (iman % 100);

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.emerald,
        onRefresh: () async {
          final uid = auth.user!.id;
          await Future.wait([
            prayer.loadToday(uid),
            athkar.loadAll(uid),
            streak.loadForUser(uid),
            habits.loadForUser(uid),
            auth.refreshProfile(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
          children: [
            // 1. Greeting + streak + title
            _pad(_greeting(context, auth, streak, titles)),
            const SizedBox(height: 12),

            // 2. Iman hero
            _pad(GlassContainer(
              level: GlassLevel.featured,
              accent: AppColors.gold,
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppColors.gold, size: 20),
                      const SizedBox(width: 8),
                      Text('رصيد الإيمان',
                          style: AppText.body
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedNumber(value: iman, decimals: 1),
                  const SizedBox(height: 14),
                  ImanProgressBar(
                    currentIman: progressInLevel * 100,
                    nextTierAt: 100,
                    level: level,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${remaining.toStringAsFixed(1)} حتى المستوى التالي',
                    style: AppText.caption.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _miniStat('حسنات', '$hasanat', AppColors.emerald),
                      const SizedBox(width: 8),
                      _miniStat('سيئات', '$sayyiat', AppColors.error),
                    ],
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),

            // 3. حماية الستريك (إن لزم)
            if (streak.canProtectYesterday) ...[
              _pad(GlassContainer(
                level: GlassLevel.featured,
                accent: AppColors.warning,
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                onTap: () => StreakProtectionSheet.show(context),
                child: Row(
                  children: [
                    const Icon(Icons.shield,
                        color: AppColors.warning, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('فاتك يوم أمس — احمِ سلسلتك',
                              style: AppText.body
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            'ادفع 1 همّة للمحافظة على ${streak.currentStreak} يوم',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left,
                        color: AppColors.textSecondary),
                  ],
                ),
              )),
              const SizedBox(height: 12),
            ],

            // 4. 🎯 "الآن" — card واحد فقط
            _pad(_nowCard(context, prayer, athkar)),
            const SizedBox(height: 12),

            // 5. 🌱 عادات اليوم
            if (habits.active.isNotEmpty || athkar.mandatoryCategories.isNotEmpty) ...[
              _pad(_habitsCard(context, athkar, habits, prayer)),
              const SizedBox(height: 12),
            ],

            // 6. 🏆 إنجازك القادم
            _pad(_nextAchievementCard(context, badges)),
            const SizedBox(height: 12),

            // 7. 🎧 درس اليوم
            if (lesson.lesson != null)
              _pad(_lessonCard(context, lesson)),
            const SizedBox(height: 12),

            // 8. روابط سريعة
            _pad(Row(
              children: [
                Expanded(
                  child: _quickLink(
                    context,
                    icon: Icons.nights_stay,
                    label: 'القيام',
                    onTap: () => _push(context, const QiyamPage()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _quickLink(
                    context,
                    icon: Icons.workspace_premium,
                    label: 'ألقابي',
                    badge: titles.unlockedIds.isEmpty
                        ? null
                        : '${titles.unlockedIds.length}',
                    onTap: () => _push(context, const TitlesPage()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _quickLink(
                    context,
                    icon: Icons.mosque,
                    label: 'صلواتي',
                    badge: '${prayer.todayCompletedCount}/5',
                    onTap: () => _push(context, const PrayerPage()),
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 1. Greeting
  // ═══════════════════════════════════════════
  Widget _greeting(BuildContext context, AuthProvider auth,
      StreakProvider streak, TitleProvider titles) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('السلام عليكم،',
                  style: AppText.caption.copyWith(fontSize: 13)),
              Text(auth.displayName,
                  style: AppText.heading.copyWith(fontSize: 24)),
              if (titles.activeTitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(titles.activeTitle!.nameAr,
                      style: AppText.caption.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        if (streak.currentStreak > 0)
          AppMotion.pulse(
            context,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.streak.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.streak.withAlpha(40), blurRadius: 10)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppColors.streak, size: 16),
                  const SizedBox(width: 4),
                  Text('${streak.currentStreak}',
                      style: AppText.caption.copyWith(
                          color: AppColors.streak,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            ),
            trigger: streak.currentStreak,
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 2. "الآن" — card واحد ذكي
  // ═══════════════════════════════════════════
  Widget _nowCard(
      BuildContext context, PrayerProvider prayer, AthkarProvider athkar) {
    final now = DateTime.now();
    final focus = prayer.currentFocusPrayer;

    // أولوية 1: صلاة في نافذة الجماعة/الانفراد
    if (focus != null) {
      final log = prayer.todayLogs[focus];
      if (log == null || !log.isRecorded) {
        return _actionCard(
          context,
          icon: focus.icon,
          label: 'الصلاة الآن',
          title: focus.arabicName,
          subtitle: prayer.phaseFor(focus) == PrayerPhase.congregationOpen
              ? 'وقت الجماعة مفتوح — سجّل صلاتك'
              : 'وقت الانفراد — سجّل صلاتك',
          ctaLabel: 'سجّل صلاتك',
          accent: AppColors.emerald,
          onTap: () => _push(context, PrayerDetailPage(prayer: focus)),
        );
      }
    }

    // أولوية 2: أذكار الصباح/المساء حسب الوقت
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      final morning = athkar.categories
          .where((c) => c.id == 'morning')
          .firstOrNull;
      if (morning != null && athkar.completionFor(morning) < 1.0) {
        final done = athkar.completedCountIn(morning);
        return _actionCard(
          context,
          icon: Icons.wb_twilight,
          label: 'الآن',
          title: 'أذكار الصباح',
          subtitle: '$done / ${morning.totalCount} مكتمل',
          ctaLabel: 'ابدأ الأذكار',
          accent: AppColors.gold,
          onTap: () =>
              _push(context, AthkarDetailPage(category: morning)),
        );
      }
    }
    if (hour >= 16 && hour < 22) {
      final evening = athkar.categories
          .where((c) => c.id == 'evening')
          .firstOrNull;
      if (evening != null && athkar.completionFor(evening) < 1.0) {
        final done = athkar.completedCountIn(evening);
        return _actionCard(
          context,
          icon: Icons.nights_stay,
          label: 'الآن',
          title: 'أذكار المساء',
          subtitle: '$done / ${evening.totalCount} مكتمل',
          ctaLabel: 'ابدأ الأذكار',
          accent: AppColors.gold,
          onTap: () =>
              _push(context, AthkarDetailPage(category: evening)),
        );
      }
    }

    // أولوية 3: الصلاة القادمة
    final next = prayer.currentFocusPrayer ??
        _nextPrayerAfter(prayer.todayLogs);
    if (next != null) {
      final tl = prayer.timelineFor(next);
      final diff = tl.adhan.difference(now);
      return _actionCard(
        context,
        icon: next.icon,
        label: 'الصلاة القادمة',
        title: next.arabicName,
        subtitle: _fmtDiff(diff),
        ctaLabel: 'التفاصيل',
        accent: AppColors.iman,
        onTap: () => _push(context, PrayerDetailPage(prayer: next)),
      );
    }

    // fallback
    return _actionCard(
      context,
      icon: Icons.check_circle,
      label: 'الحمد لله',
      title: 'كل الصلوات مكتملة',
      subtitle: 'استمر على هذا الخير',
      ctaLabel: 'صلواتي',
      accent: AppColors.emerald,
      onTap: () => _push(context, const PrayerPage()),
    );
  }

  PrayerName? _nextPrayerAfter(Map<PrayerName, PrayerLog> logs) {
    for (final p in PrayerName.values) {
      final log = logs[p];
      if (log == null || !log.isRecorded) return p;
    }
    return null;
  }

  String _fmtDiff(Duration d) {
    if (d.isNegative) return 'الآن';
    if (d.inHours > 0) return 'باقي ${d.inHours}س ${d.inMinutes % 60}د';
    return 'باقي ${d.inMinutes}د';
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
    required String ctaLabel,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      level: GlassLevel.featured,
      accent: accent,
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withAlpha(40),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppText.caption.copyWith(
                            color: accent, fontWeight: FontWeight.w600)),
                    Text(title,
                        style: AppText.section.copyWith(fontSize: 20)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(subtitle, style: AppText.caption.copyWith(fontSize: 13)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(ctaLabel,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 3. عادات اليوم (مضغوطة)
  // ═══════════════════════════════════════════
  Widget _habitsCard(
    BuildContext context,
    AthkarProvider athkar,
    HabitStreakProvider habits,
    PrayerProvider prayer,
  ) {
    final rows = <Widget>[];

    // أذكار الصباح
    final morning = athkar.categories.where((c) => c.id == 'morning').firstOrNull;
    if (morning != null) {
      final done = athkar.completedCountIn(morning);
      rows.add(_habitRow(
        icon: Icons.wb_twilight,
        title: 'أذكار الصباح',
        progress: '$done/${morning.totalCount}',
        completed: done >= morning.totalCount,
        onTap: () => _push(context, AthkarDetailPage(category: morning)),
      ));
    }

    // أذكار المساء
    final evening = athkar.categories.where((c) => c.id == 'evening').firstOrNull;
    if (evening != null) {
      final done = athkar.completedCountIn(evening);
      rows.add(_habitRow(
        icon: Icons.nights_stay,
        title: 'أذكار المساء',
        progress: '$done/${evening.totalCount}',
        completed: done >= evening.totalCount,
        onTap: () => _push(context, AthkarDetailPage(category: evening)),
      ));
    }

    // الصلوات المتبقية
    final remainingPrayers = PrayerName.values
        .where((p) {
          final log = prayer.todayLogs[p];
          return log == null || !log.isRecorded;
        })
        .toList();
    if (remainingPrayers.isNotEmpty) {
      rows.add(_habitRow(
        icon: Icons.mosque,
        title: 'صلوات متبقية',
        progress: '${remainingPrayers.length}/5',
        completed: false,
        onTap: () => _push(context, const PrayerPage()),
      ));
    }

    // عادات متصلة (Streaks)
    for (final h in habits.active.take(2)) {
      rows.add(_habitRow(
        icon: Icons.local_fire_department,
        title: h.labelAr,
        progress: '${h.currentStreak} يوم',
        completed: true,
        accent: AppColors.streak,
        onTap: null,
      ));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: AppColors.mint, size: 18),
              const SizedBox(width: 8),
              Text('عادات اليوم', style: AppText.section),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _habitRow({
    required IconData icon,
    required String title,
    required String progress,
    required bool completed,
    Color? accent,
    VoidCallback? onTap,
  }) {
    final color = completed ? AppColors.mint : (accent ?? AppColors.textSecondary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(36),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(completed ? Icons.check : icon,
                  color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: AppText.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            Text(progress,
                style: AppText.caption.copyWith(
                    fontSize: 12,
                    color: completed
                        ? AppColors.mint
                        : AppColors.textSecondary)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_left,
                  size: 16, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 4. إنجازك القادم
  // ═══════════════════════════════════════════
  Widget _nextAchievementCard(BuildContext context, BadgeProvider badges) {
    // ابحث عن أقرب ميدالية مقفلة
    final locked = badges.allBadges
        .where((b) => !badges.isUnlocked(b.id) && b.targetValue != null)
        .toList();

    if (locked.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.gold, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text('فتحت كل الميداليات — ما شاء الله',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    // اختر أول ميدالية (بترتيب target_value)
    locked.sort((a, b) => (a.targetValue ?? 0).compareTo(b.targetValue ?? 0));
    final next = locked.first;
    final target = next.targetValue ?? 1;

    // حساب التقدم الحالي (تقريبي — بالميداليات المحسوبة)
    // نستخدم unlockedCount كتقدير
    final currentProgress = 0; // Badge engine بيحسبها server-side
    final ratio = (currentProgress / target).clamp(0.0, 1.0);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text('إنجازك القادم', style: AppText.section),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: next.tier.color.withAlpha(40),
                  border: Border.all(color: next.tier.color.withAlpha(150)),
                ),
                child: Icon(next.iconData,
                    color: next.tier.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(next.nameAr,
                        style: AppText.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(next.description,
                        style: AppText.caption.copyWith(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(26),
              valueColor: AlwaysStoppedAnimation(next.tier.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'الهدف: $target يوم',
            style: AppText.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 5. درس اليوم
  // ═══════════════════════════════════════════
  Widget _lessonCard(BuildContext context, DailyLessonProvider lesson) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      onTap: () => _push(context, const DailyLessonPage()),
      child: Row(
        children: [
          const Icon(Icons.headphones, color: AppColors.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('درس اليوم', style: AppText.caption),
                Text(lesson.lesson!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(lesson.lesson!.durationLabel, style: AppText.caption),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 6. Quick links
  // ═══════════════════════════════════════════
  Widget _quickLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(13)),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(icon, color: AppColors.mint, size: 24),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(badge,
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.background,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label,
                style: AppText.caption.copyWith(
                    fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════
  Widget _pad(Widget c) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: c);

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: AppText.numberSmall.copyWith(
                    fontSize: 15, color: color)),
            const SizedBox(width: 6),
            Text(label, style: AppText.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}