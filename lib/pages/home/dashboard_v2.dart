// lib/pages/home/dashboard_v2.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/athkar.dart';
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
import '../../theme/app_text.dart';
import '../../widgets/ribbon_card.dart';           // ← جديد
import '../../widgets/streak_protection_sheet.dart';
import '../athkar/athkar_detail_page.dart';
import '../content/content_tab.dart';
import '../lessons/daily_lesson_page.dart';
import '../prayer/prayer_page.dart';
import '../qiyam/qiyam_page.dart';
import '../titles/titles_page.dart';

/// Midnight Royal dashboard — hybrid of existing features + new visual language.
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
    final hasanat = ((profile?['total_hasanat'] ?? 0) as num).toInt();
    final sayyiat =
        ((profile?['total_sayyiat_unrepented'] ?? 0) as num).toInt();
    final level = (iman / 100).floor() + 1;

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () async {
        final user = auth.user;
        if (user == null) return;
        await Future.wait([
          prayer.loadToday(user.id),
          athkar.loadAll(user.id),
          streak.loadForUser(user.id),
          habits.loadForUser(user.id),
          badges.loadForUser(user.id),
          lesson.loadForUser(user.id),
          titles.loadForUser(user.id),
          auth.refreshProfile(),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
        children: [
          // 1. Hero profile with mosque
          _HeroProfile(
            name: auth.displayName,
            title: titles.activeTitle?.nameAr,
            avatarUrl: profile?['avatar_url'] as String?,
            iman: iman,
            hasanat: hasanat,
            level: level,
            streak: streak.currentStreak,
          ),
          const SizedBox(height: 18),

          // 2. Smart "الآن" card (prayer/athkar/next-prayer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _SmartNowCard(
              prayer: prayer,
              athkar: athkar,
              onPrayer: () => _push(context, const PrayerPage()),
              onAthkar: (cat) =>
                  _push(context, AthkarDetailPage(category: cat)),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Quick actions grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _QuickActions(
              onPrayer: () => _push(context, const PrayerPage()),
              onQuran: () => _push(context, const ContentTab()),
              onQiyam: () => _push(context, const QiyamPage()),
              onAthkar: () {
                final cat = athkar.categories
                    .where((c) => c.id == 'morning' || c.id == 'evening')
                    .firstOrNull;
                if (cat != null) {
                  _push(context, AthkarDetailPage(category: cat));
                }
              },
              onSunnah: () => _push(context, const QiyamPage()),
              onDaily: () => _push(context, const DailyLessonPage()),
            ),
          ),
          const SizedBox(height: 18),

          // 4. Streak achievement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _StreakAchievementCard(
              current: streak.currentStreak,
              next: streak.nextMilestone,
              progress: streak.progressToNextMilestone,
              unlockedBadges: badges.unlockedIds.length,
              totalBadges: badges.allBadges.length,
            ),
          ),

          // 5. Streak protection
          if (streak.canProtectYesterday) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RibbonCard(
                accent: AppColors.warning,
                padding: const EdgeInsets.all(15),
                onTap: () => StreakProtectionSheet.show(context),
                child: Row(
                  children: [
                    const Icon(Icons.shield_moon_outlined,
                        color: AppColors.warning, size: 27),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'فاتك يوم أمس؟ يمكنك حماية سلسلة إنجازك.',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_left,
                        color: AppColors.goldBright),
                  ],
                ),
              ),
            ),
          ],

          // 6. Habits list
          if (habits.active.isNotEmpty ||
              athkar.mandatoryCategories.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _HabitsCard(
                athkar: athkar,
                habits: habits,
                prayer: prayer,
                onAthkarTap: (cat) =>
                    _push(context, AthkarDetailPage(category: cat)),
                onPrayerTap: () => _push(context, const PrayerPage()),
              ),
            ),
          ],

          // 7. Next achievement
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _NextAchievementCard(badges: badges),
          ),

          // 8. Lesson
          if (lesson.lesson != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _LessonCard(
                title: lesson.lesson!.title,
                duration: lesson.lesson!.durationLabel,
                onTap: () => _push(context, const DailyLessonPage()),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 9. Mini balances
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: _MiniBalance(
                    label: 'الحسنات',
                    value: _compactNumber(hasanat),
                    icon: Icons.spa_rounded,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniBalance(
                    label: 'السيئات',
                    value: _compactNumber(sayyiat),
                    icon: Icons.remove_circle_outline,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _compactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}م';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}ك';
    return value.toString();
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero / profile
// ─────────────────────────────────────────────────────────────────────────────

class _HeroProfile extends StatelessWidget {
  const _HeroProfile({
    required this.name,
    required this.title,
    required this.avatarUrl,
    required this.iman,
    required this.hasanat,
    required this.level,
    required this.streak,
  });

  final String name;
  final String? title;
  final String? avatarUrl;
  final double iman;
  final int hasanat;
  final int level;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.isNotEmpty ? name.characters.first : 'ص';

    return SizedBox(
      height: 390,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 245,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(34),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/sohba/hero_mosque.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => const _MosqueFallback(),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x22050A1E),
                          Color(0x44070D25),
                          Color(0xFF080D24),
                        ],
                        stops: [0, 0.52, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 22,
                    right: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          'صحبة',
                          style: TextStyle(
                            color: AppColors.goldBright,
                            fontSize: 35,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Color(0xAAE9B95E), blurRadius: 16),
                            ],
                          ),
                        ),
                        Text(
                          'Sohba',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 17,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 0,
            child: RibbonCard(
              accent: AppColors.gold,
              radius: 30,
              padding: const EdgeInsets.fromLTRB(20, 68, 20, 18),
              child: Column(
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (title != null && title!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 34, height: 1, color: AppColors.gold),
                        const SizedBox(width: 9),
                        Text(
                          title!,
                          style: const TextStyle(
                            color: AppColors.goldBright,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(width: 34, height: 1, color: AppColors.gold),
                      ],
                    ),
                  ] else
                    const SizedBox(height: 8),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          icon: Icons.eco_rounded,
                          value: hasanat.toString(),
                          label: 'حسنات',
                          color: AppColors.emerald,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 52,
                        color: AppColors.gold.withValues(alpha: .25),
                      ),
                      Expanded(
                        child: _HeroStat(
                          icon: Icons.stars_rounded,
                          value: iman.toStringAsFixed(1),
                          label: 'رصيد الإيمان',
                          color: AppColors.goldBright,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.iman.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.iman.withValues(alpha: .35),
                          ),
                        ),
                        child: Text(
                          'المستوى $level',
                          style: const TextStyle(
                            color: Color(0xFFC5B7FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (streak > 0)
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: AppColors.streak, size: 17),
                            const SizedBox(width: 4),
                            Text(
                              '$streak يوم متواصل',
                              style: const TextStyle(
                                color: AppColors.goldBright,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: (iman % 100) / 100,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: .09),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.goldBright,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 174,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: .48),
                      blurRadius: 25,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: AppColors.background,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 43,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: AppText.caption.copyWith(fontSize: 12)),
      ],
    );
  }
}

class _MosqueFallback extends StatelessWidget {
  const _MosqueFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF151D42), Color(0xFF30234F), Color(0xFF090F29)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 32,
            left: 60,
            child: Icon(Icons.nightlight_round,
                size: 55,
                color: AppColors.goldBright.withValues(alpha: .8)),
          ),
          const Center(
            child: Icon(Icons.mosque_rounded,
                size: 150, color: Color(0x99E9B95E)),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF080D24)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart "الآن" card — keeps intelligent prioritization + gains prayer background
// ─────────────────────────────────────────────────────────────────────────────

class _SmartNowCard extends StatefulWidget {
  const _SmartNowCard({
    required this.prayer,
    required this.athkar,
    required this.onPrayer,
    required this.onAthkar,
  });

  final PrayerProvider prayer;
  final AthkarProvider athkar;
  final VoidCallback onPrayer;
  final void Function(AthkarCategory) onAthkar;

  @override
  State<_SmartNowCard> createState() => _SmartNowCardState();
}

class _SmartNowCardState extends State<_SmartNowCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final focus = widget.prayer.currentFocusPrayer;

    // Priority 1: prayer in window
    if (focus != null) {
      final log = widget.prayer.todayLogs[focus];
      if (log == null || !log.isRecorded) {
        return _prayerCard(prayer: focus, isCurrent: true);
      }
    }

    // Priority 2: morning / evening athkar
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      final morning = widget.athkar.categories
          .where((c) => c.id == 'morning')
          .firstOrNull;
      if (morning != null && widget.athkar.completionFor(morning) < 1.0) {
        return _athkarCard(morning);
      }
    }
    if (hour >= 16 && hour < 22) {
      final evening = widget.athkar.categories
          .where((c) => c.id == 'evening')
          .firstOrNull;
      if (evening != null && widget.athkar.completionFor(evening) < 1.0) {
        return _athkarCard(evening);
      }
    }

    // Priority 3: next prayer
    final next = _nextPrayerAfter(widget.prayer.todayLogs);
    if (next != null) {
      return _prayerCard(prayer: next, isCurrent: false);
    }

    // Fallback: all recorded
    return _fallbackCard();
  }

  PrayerName? _nextPrayerAfter(Map<PrayerName, PrayerLog> logs) {
    for (final p in PrayerName.values) {
      final log = logs[p];
      if (log == null || !log.isRecorded) return p;
    }
    return null;
  }

  Widget _prayerCard({
    required PrayerName prayer,
    required bool isCurrent,
  }) {
    final timeline = widget.prayer.timelineFor(prayer);
    final now = DateTime.now();
    final phase = timeline.phaseAt(now);

    String label;
    String timeLabel;
    if (isCurrent) {
      label = 'الصلاة الآن';
      timeLabel = phase == PrayerPhase.congregationOpen
          ? 'وقت الجماعة'
          : 'وقت الانفراد';
    } else {
      label = 'الصلاة القادمة';
      var adhan = timeline.adhan;
      if (prayer == PrayerName.fajr && adhan.isBefore(now)) {
        adhan = adhan.add(const Duration(days: 1));
      }
      timeLabel = _formatRemaining(adhan.difference(now));
    }

    return RibbonCard(
      accent: AppColors.gold,
      radius: 26,
      padding: EdgeInsets.zero,
      onTap: widget.onPrayer,
      child: SizedBox(
        height: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── الصورة ──
            ClipRect(
              child: Transform.scale(
                scale: 1.06,
                child: Image.asset(
                  'assets/images/sohba/prayers/${prayer.name}.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => _PrayerFallback(),
                ),
              ),
            ),

            // ── تعتيم أفقي (لقراءة النص) ──
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xDD090F29),
                    Color(0x88101936),
                    Color(0xEE080D24),
                  ],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),

            // ── fade علوي (الصورة بتذوب في الكارد) ──
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1B2348), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            // ── fade سفلي ──
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 48,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF111A39), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            // ── المحتوى ──
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeLabel,
                          style: AppText.caption.copyWith(
                            color: AppColors.text,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            final afterPrayer = widget.athkar.categories
                                .where((c) => c.id == 'after_prayer')
                                .firstOrNull;
                            if (afterPrayer != null) {
                              widget.onAthkar(afterPrayer);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.background.withValues(alpha: .58),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: .78),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book_rounded,
                                    color: AppColors.goldBright, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'أذكار الصلاة',
                                  style: TextStyle(
                                    color: AppColors.goldBright,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 105,
                    color: AppColors.gold.withValues(alpha: .3),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: AppColors.goldBright,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.access_time_rounded,
                                color: AppColors.goldBright, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prayer.arabicName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(timeline.adhan),
                          style: AppText.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _athkarCard(AthkarCategory category) {
    final done = widget.athkar.completedCountIn(category);
    final total = category.totalCount;
    return RibbonCard(
      accent: AppColors.gold,
      radius: 26,
      padding: const EdgeInsets.all(20),
      onTap: () => widget.onAthkar(category),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              category.id == 'morning'
                  ? Icons.wb_twilight
                  : Icons.nights_stay,
              color: AppColors.goldBright,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الآن',
                  style: TextStyle(
                    color: AppColors.goldBright,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.nameAr,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: total > 0 ? done / total : 0,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: .12),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.goldBright,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$done / $total',
                  style: AppText.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_left, color: AppColors.goldBright),
        ],
      ),
    );
  }

  Widget _fallbackCard() {
    return RibbonCard(
      accent: AppColors.emerald,
      padding: const EdgeInsets.all(18),
      onTap: widget.onPrayer,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.check_circle,
                color: AppColors.mint, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الحمد لله',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'كل الصلوات مكتملة — استمر على الخير',
                  style: AppText.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration diff) {
    if (diff.isNegative) return 'الآن';
    if (diff.inHours > 0) {
      return 'باقي ${diff.inHours} س ${diff.inMinutes % 60} د';
    }
    return 'باقي ${diff.inMinutes} دقيقة';
  }

  String _formatTime(DateTime value) {
    final h = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final m = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'م' : 'ص';
    return '$h:$m $suffix';
  }
}

class _PrayerFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A315B), Color(0xFF182448), Color(0xFF080D24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Icon(Icons.mosque_rounded,
            size: 110, color: Color(0x55F6D58D)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions grid
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPrayer,
    required this.onQuran,
    required this.onQiyam,
    required this.onAthkar,
    required this.onSunnah,
    required this.onDaily,
  });

  final VoidCallback onPrayer;
  final VoidCallback onQuran;
  final VoidCallback onQiyam;
  final VoidCallback onAthkar;
  final VoidCallback onSunnah;
  final VoidCallback onDaily;

  @override
  Widget build(BuildContext context) {
    final items = <_ActionData>[
      _ActionData('الصلاة', Icons.mosque_rounded, AppColors.gold, onPrayer),
      _ActionData('القرآن', Icons.menu_book_rounded,
          const Color(0xFF73C8EA), onQuran),
      _ActionData('القيام', Icons.nightlight_round,
          const Color(0xFFB18AE8), onQiyam),
      _ActionData('الأذكار', Icons.front_hand_rounded,
          const Color(0xFFE2B66D), onAthkar),
      _ActionData('السنن', Icons.account_balance_rounded,
          const Color(0xFF8EA8F2), onSunnah),
      _ActionData('الدروس', Icons.event_note_rounded,
          const Color(0xFF8B83D7), onDaily),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .98,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return RibbonCard(
          accent: item.color,
          radius: 23,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
          onTap: item.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: AppColors.goldBright, size: 34),
              const SizedBox(height: 11),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionData {
  const _ActionData(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak achievement
// ─────────────────────────────────────────────────────────────────────────────

class _StreakAchievementCard extends StatelessWidget {
  const _StreakAchievementCard({
    required this.current,
    required this.next,
    required this.progress,
    required this.unlockedBadges,
    required this.totalBadges,
  });

  final int current;
  final int? next;
  final double progress;
  final int unlockedBadges;
  final int totalBadges;

  @override
  Widget build(BuildContext context) {
    final target = next ?? current;
    return RibbonCard(
      accent: AppColors.gold,
      radius: 26,
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: .35),
                        AppColors.gold.withValues(alpha: .06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const Icon(
                  Icons.military_tech_rounded,
                  size: 86,
                  color: AppColors.goldBright,
                  shadows: [
                    Shadow(color: Color(0x99E9B95E), blurRadius: 20),
                  ],
                ),
                Positioned(
                  bottom: 3,
                  child: Text(
                    '$current',
                    style: const TextStyle(
                      color: AppColors.background,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'إنجازاتك',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 7),
                    Icon(Icons.emoji_events_rounded,
                        color: AppColors.gold, size: 23),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  '$current يومًا متتاليًا',
                  style: const TextStyle(
                    color: AppColors.goldBright,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 9,
                    backgroundColor: Colors.white.withValues(alpha: .12),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.goldBright,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? 'وصلت إلى أعلى سلسلة متاحة'
                      : '$current / $target يوم',
                  style: AppText.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 7),
                Text(
                  '$unlockedBadges من $totalBadges ميدالية مفتوحة',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habits card
// ─────────────────────────────────────────────────────────────────────────────

class _HabitsCard extends StatelessWidget {
  const _HabitsCard({
    required this.athkar,
    required this.habits,
    required this.prayer,
    required this.onAthkarTap,
    required this.onPrayerTap,
  });

  final AthkarProvider athkar;
  final HabitStreakProvider habits;
  final PrayerProvider prayer;
  final void Function(AthkarCategory) onAthkarTap;
  final VoidCallback onPrayerTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    // Remaining prayers
    final remaining = PrayerName.values.where((p) {
      final log = prayer.todayLogs[p];
      return log == null || !log.isRecorded;
    }).length;
    if (remaining > 0) {
      rows.add(_habitRow(
        icon: Icons.mosque_rounded,
        title: 'صلوات متبقية',
        progress: '$remaining / 5',
        completed: false,
        accent: AppColors.gold,
        onTap: onPrayerTap,
      ));
    }

    // Morning athkar
    final morning =
        athkar.categories.where((c) => c.id == 'morning').firstOrNull;
    if (morning != null) {
      final done = athkar.completedCountIn(morning);
      rows.add(_habitRow(
        icon: Icons.wb_twilight,
        title: 'أذكار الصباح',
        progress: '$done / ${morning.totalCount}',
        completed: done >= morning.totalCount,
        onTap: () => onAthkarTap(morning),
      ));
    }

    // Evening athkar
    final evening =
        athkar.categories.where((c) => c.id == 'evening').firstOrNull;
    if (evening != null) {
      final done = athkar.completedCountIn(evening);
      rows.add(_habitRow(
        icon: Icons.nights_stay,
        title: 'أذكار المساء',
        progress: '$done / ${evening.totalCount}',
        completed: done >= evening.totalCount,
        onTap: () => onAthkarTap(evening),
      ));
    }

    // Active habit streaks (top 2)
    for (final h in habits.active.take(2)) {
      rows.add(_habitRow(
        icon: Icons.local_fire_department,
        title: h.labelAr,
        progress: '${h.currentStreak} يوم',
        completed: true,
        accent: AppColors.streak,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return RibbonCard(
      accent: AppColors.emerald,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: AppColors.mint, size: 20),
              SizedBox(width: 8),
              Text(
                'عادات اليوم',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
    final color =
        completed ? AppColors.mint : (accent ?? AppColors.textSecondary);
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
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(completed ? Icons.check : icon,
                  color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              progress,
              style: AppText.caption.copyWith(
                fontSize: 12,
                color: completed ? AppColors.mint : AppColors.textSecondary,
              ),
            ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Next achievement
// ─────────────────────────────────────────────────────────────────────────────

class _NextAchievementCard extends StatelessWidget {
  const _NextAchievementCard({required this.badges});
  final BadgeProvider badges;

  @override
  Widget build(BuildContext context) {
    final locked = badges.allBadges
        .where((b) => !badges.isUnlocked(b.id) && b.targetValue != null)
        .toList();

    if (locked.isEmpty) {
      return RibbonCard(
        accent: AppColors.gold,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.emoji_events,
                color: AppColors.goldBright, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'فتحت كل الميداليات — ما شاء الله',
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    locked.sort((a, b) => (a.targetValue ?? 0).compareTo(b.targetValue ?? 0));
    final next = locked.first;
    final target = next.targetValue ?? 1;

    return RibbonCard(
      accent: next.tier.color,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events,
                  color: AppColors.goldBright, size: 18),
              SizedBox(width: 8),
              Text(
                'إنجازك القادم',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                  color: next.tier.color.withValues(alpha: .25),
                  border: Border.all(
                    color: next.tier.color.withValues(alpha: .65),
                    width: 2,
                  ),
                ),
                child: Icon(next.iconData,
                    color: next.tier.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next.nameAr,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      next.description,
                      style: AppText.caption.copyWith(fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: .12),
              valueColor: AlwaysStoppedAnimation(next.tier.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'الهدف: $target',
            style: AppText.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lesson
// ─────────────────────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.title,
    required this.duration,
    required this.onTap,
  });

  final String title;
  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RibbonCard(
      accent: AppColors.iman,
      padding: const EdgeInsets.all(15),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.iman.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.headphones_rounded,
                color: Color(0xFFC5B7FF), size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('درس اليوم',
                    style: TextStyle(color: AppColors.gold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(duration,
              style: AppText.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_left, color: AppColors.gold),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini balance
// ─────────────────────────────────────────────────────────────────────────────

class _MiniBalance extends StatelessWidget {
  const _MiniBalance({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RibbonCard(
      accent: color,
      radius: 18,
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}