// lib/pages/home/dashboard_v2.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/badge.dart';
import '../../models/prayer_log.dart';
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
import '../../widgets/ribbon_card.dart';
import '../../widgets/streak_protection_sheet.dart';
import '../achievements/achievements_tab.dart';
import '../content/content_tab.dart';
import '../leaderboard/leaderboard_page.dart';
import '../lessons/daily_lesson_page.dart';
import '../prayer/prayer_page.dart';
import '../qiyam/qiyam_page.dart';

class DashboardV2 extends StatelessWidget {
  const DashboardV2({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prayer = context.watch<PrayerProvider>();
    final streak = context.watch<StreakProvider>();
    final lesson = context.watch<DailyLessonProvider>();
    final badges = context.watch<BadgeProvider>();
    final habits = context.watch<HabitStreakProvider>();
    final titles = context.watch<TitleProvider>();

    final profile = auth.profile;
    final hasanat = ((profile?['total_hasanat'] ?? 0) as num).toInt();
    final sayyiat =
        ((profile?['total_sayyiat_unrepented'] ?? 0) as num).toInt();

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () async {
        final user = auth.user;
        if (user == null) return;
        await Future.wait([
          prayer.load(),
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
          _HeroProfile(
            name: auth.displayName,
            title: titles.activeTitle?.nameAr,
            avatarUrl: profile?['avatar_url'] as String?,
            hasanat: hasanat,
            sayyiat: sayyiat,
            streak: streak.currentStreak,
          ),
          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _SmartNowCard(
              prayer: prayer,
              onRecord: (p, cong) => _record(context, p, cong),
              onOpen: () => _push(context, const PrayerPage()),
            ),
          ),
          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _QuickActions(
              onPrayer: () => _push(context, const PrayerPage()),
              onQuran: () => _push(context, const ContentTab()),
              onQiyam: () => _push(context, const QiyamPage()),
              onDaily: () => _push(context, const DailyLessonPage()),
              onLeaderboard: () =>
                  _push(context, const LeaderboardPage()),
              onAchievements: () =>
                  _push(context, const AchievementsTab()),
            ),
          ),
          const SizedBox(height: 18),

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

          if (habits.active.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _HabitsCard(
                habits: habits,
                prayer: prayer,
                onPrayerTap: () => _push(context, const PrayerPage()),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _NextAchievementCard(badges: badges),
          ),

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
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  static Future<void> _record(
    BuildContext context,
    PrayerName prayer,
    bool congregation,
  ) async {
    final prov = context.read<PrayerProvider>();
    final ok = await prov.record(prayer, congregation: congregation);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهى وقت هذه الصلاة')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Hero profile (بدون إيمان/مستوى)
// ─────────────────────────────────────────────────────────────
class _HeroProfile extends StatelessWidget {
  const _HeroProfile({
    required this.name,
    required this.title,
    required this.avatarUrl,
    required this.hasanat,
    required this.sayyiat,
    required this.streak,
  });

  final String name;
  final String? title;
  final String? avatarUrl;
  final int hasanat;
  final int sayyiat;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : 'ص';

    return SizedBox(
      height: 370,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 245,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(34)),
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
                          icon: Icons.remove_circle_outline,
                          value: sayyiat.toString(),
                          label: 'سيئات',
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
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
  Widget build(BuildContext context) => Column(
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

class _MosqueFallback extends StatelessWidget {
  const _MosqueFallback();
  @override
  Widget build(BuildContext context) => Container(
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

// ─────────────────────────────────────────────────────────────
// Smart "الآن" card — الصلاة الحالية/القادمة
// ─────────────────────────────────────────────────────────────
class _SmartNowCard extends StatefulWidget {
  const _SmartNowCard({
    required this.prayer,
    required this.onRecord,
    required this.onOpen,
  });

  final PrayerProvider prayer;
  final Future<void> Function(PrayerName, bool) onRecord;
  final VoidCallback onOpen;

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
    final current = PrayerEngine.currentOrNext(
      date: widget.prayer.selectedDate,
      statuses: widget.prayer.statuses,
      now: now,
    );

    if (current.status == PrayerStatus.pending) {
      return _prayerCard(
        prayer: current.prayer,
        at: current.at,
        isCurrent: true,
        now: now,
      );
    }
    if (current.status == PrayerStatus.upcoming) {
      return _prayerCard(
        prayer: current.prayer,
        at: current.at,
        isCurrent: false,
        now: now,
      );
    }
    return _fallbackCard();
  }

  Widget _prayerCard({
    required PrayerName prayer,
    required DateTime at,
    required bool isCurrent,
    required DateTime now,
  }) {
    final label = isCurrent ? 'الصلاة الآن' : 'الصلاة القادمة';
    final timeLabel = isCurrent
        ? 'وقت الأداء — سجّلها الآن'
        : _formatRemaining(at.difference(now));

    return RibbonCard(
      accent: AppColors.gold,
      radius: 26,
      padding: EdgeInsets.zero,
      onTap: widget.onOpen,
      child: SizedBox(
        height: isCurrent ? 210 : 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: Transform.scale(
                scale: 1.06,
                child: Image.asset(
                  'assets/images/sohba/prayers/${prayer.name}.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _PrayerFallback(),
                ),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.goldBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.goldBright, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        prayer.arabicName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          _formatTime(at),
                          style: AppText.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeLabel,
                    style: AppText.caption.copyWith(
                      color: AppColors.text,
                      fontSize: 13,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            label: 'صليت جماعة',
                            color: AppColors.emerald,
                            onTap: () =>
                                widget.onRecord(prayer, true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionButton(
                            label: 'صليت فردي',
                            color: AppColors.mint,
                            onTap: () =>
                                widget.onRecord(prayer, false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: .22),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: .55)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackCard() => RibbonCard(
        accent: AppColors.emerald,
        padding: const EdgeInsets.all(18),
        onTap: widget.onOpen,
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
  Widget build(BuildContext context) => Container(
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

// ─────────────────────────────────────────────────────────────
// Quick actions (6 عناصر — بدون أذكار/سنن)
// ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPrayer,
    required this.onQuran,
    required this.onQiyam,
    required this.onDaily,
    required this.onLeaderboard,
    required this.onAchievements,
  });

  final VoidCallback onPrayer;
  final VoidCallback onQuran;
  final VoidCallback onQiyam;
  final VoidCallback onDaily;
  final VoidCallback onLeaderboard;
  final VoidCallback onAchievements;

  @override
  Widget build(BuildContext context) {
    final items = <_ActionData>[
      _ActionData('الصلاة', Icons.mosque_rounded, AppColors.gold, onPrayer),
      _ActionData('القرآن', Icons.menu_book_rounded,
          const Color(0xFF73C8EA), onQuran),
      _ActionData('القيام', Icons.nightlight_round,
          const Color(0xFFB18AE8), onQiyam),
      _ActionData('الدروس', Icons.event_note_rounded,
          const Color(0xFF8B83D7), onDaily),
      _ActionData('الترتيب', Icons.leaderboard_rounded,
          const Color(0xFF8EA8F2), onLeaderboard),
      _ActionData('الإنجازات', Icons.emoji_events_rounded,
          const Color(0xFFE2B66D), onAchievements),
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

// ─────────────────────────────────────────────────────────────
// Streak achievement (كما هو)
// ─────────────────────────────────────────────────────────────
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
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.goldBright),
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

// ─────────────────────────────────────────────────────────────
// Habits card (بدون أذكار)
// ─────────────────────────────────────────────────────────────
class _HabitsCard extends StatelessWidget {
  const _HabitsCard({
    required this.habits,
    required this.prayer,
    required this.onPrayerTap,
  });

  final HabitStreakProvider habits;
  final PrayerProvider prayer;
  final VoidCallback onPrayerTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    final remaining = PrayerName.values
        .where((p) => prayer.statuses[p] == PrayerStatus.pending)
        .length;
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

    for (final h in habits.active.take(3)) {
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

// ─────────────────────────────────────────────────────────────
// Next achievement (كما هو — badges تبقى)
// ─────────────────────────────────────────────────────────────
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
              Icon(Icons.emoji_events, color: AppColors.goldBright, size: 18),
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
                child: Icon(next.iconData, color: next.tier.color, size: 24),
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
          Text('الهدف: $target',
              style: AppText.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Lesson card (كما هو)
// ─────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) => RibbonCard(
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
                style:
                    AppText.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_left, color: AppColors.gold),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Mini balance (كما هو)
// ─────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) => RibbonCard(
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