import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/lock_provider.dart';
import '../../providers/daily_lesson_provider.dart';
import '../../providers/badge_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/iman_progress_bar.dart';
import '../../widgets/prayer_card.dart';
import '../prayer/prayer_page.dart';
import '../athkar/athkar_page.dart';
import '../badges/badges_page.dart';
import '../group/group_leaderboard_page.dart';
import '../lock/lock_screen.dart';
import '../lessons/daily_lesson_page.dart';
import '../challenges/challenges_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          _DashboardTab(),
          PrayerPage(),
          AthkarPage(),
          BadgesPage(),
          GroupLeaderboardPage(),
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withAlpha(240),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(13))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, Icons.home, 'الرئيسية'),
              _navItem(1, Icons.mosque_outlined, Icons.mosque, 'الصلاة'),
              _navItem(2, Icons.menu_book_outlined, Icons.menu_book, 'الأذكار'),
              _navItem(3, Icons.emoji_events_outlined, Icons.emoji_events,
                  'الميداليات'),
              _navItem(4, Icons.groups_outlined, Icons.groups, 'المجموعة'),
            ],
          ),
        ),
      ),
    );
  }

  /// inactive -> muted; active -> mint icon in a soft emerald pill + glow.
  Widget _navItem(int idx, IconData outline, IconData filled, String label) {
    final selected = _tab == idx;
    final color = selected ? AppColors.mint : AppColors.textSecondary;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.emerald.withAlpha(36)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: AppColors.emerald.withAlpha(50),
                            blurRadius: 14)
                      ]
                    : const [],
              ),
              child: Icon(selected ? filled : outline, size: 22, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppText.caption.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lock = context.watch<LockProvider>();
    final prayer = context.watch<PrayerProvider>();
    final streak = context.watch<StreakProvider>();
    final notifications = context.watch<NotificationProvider>();
    final lesson = context.watch<DailyLessonProvider>();
    final badges = context.watch<BadgeProvider>();
    final group = context.watch<GroupProvider>().group;
    final profile = auth.profile;

    // ── Lock gate (unchanged) ────────────────────────────────────
    if (lock.isLocked) return const LockScreen();
    // ─────────────────────────────────────────────────────────────

    final iman = ((profile?['iman'] ?? 0) as num).toDouble();
    final himmah = (profile?['himmah'] ?? 0) as int;
    final totalHasanat = (profile?['total_hasanat'] ?? 0) as int;
    final focus = prayer.currentFocusPrayer;

    // level 1 starts at 0 iman, level 2 at 100, etc. (unchanged math)
    final level = (iman / 100).floor() + 1;
    final progressInLevel = (iman % 100) / 100.0;
    final remaining = 100 - (iman % 100);

    PrayerLog logFor(PrayerName p) =>
        prayer.todayLogs[p] ??
        PrayerLog.empty(
          userId: auth.user!.id,
          date: prayer.todayDate,
          prayer: p,
        );

    final sections = <Widget>[
      // 1. Greeting + streak + bell
      _pad(Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('السلام عليكم،', style: AppText.caption.copyWith(fontSize: 13)),
                Text(auth.displayName,
                    style: AppText.heading.copyWith(fontSize: 24)),
                if (group != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('مجموعة: ${group['name']}',
                        style: AppText.caption),
                  ),
              ],
            ),
          ),
          if (streak.currentStreak > 0) _streakChip(context, streak.currentStreak),
          _bell(context, notifications),
        ],
      )),

      // 2. Iman hero
      _pad(GlassContainer(
        level: GlassLevel.featured,
        accent: AppColors.iman,
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.iman, size: 20),
                const SizedBox(width: 8),
                Text('رصيد الإيمان', style: AppText.body.copyWith(color: AppColors.textSecondary)),
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
            Text('${remaining.toStringAsFixed(1)} حتى المستوى التالي',
                style: AppText.caption.copyWith(fontSize: 13)),
          ],
        ),
      )),

      // 3. Current prayer (hero)
      if (focus != null) ...[
        _title('الصلاة القادمة'),
        PrayerCard(
          prayer: focus,
          log: logFor(focus),
          timeline: prayer.timelineFor(focus),
          isCurrent: true,
          onTap: () => _openPrayer(context, focus),
        ),
      ],

      // 4. Today's prayers — compact strip, not 5 big cards
      _title('صلوات اليوم', trailing: '${prayer.todayCompletedCount}/5'),
      _pad(GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: PrayerName.values
              .map((p) => _prayerDot(context, p, logFor(p)))
              .toList(),
        ),
      )),

      // 5. Daily lesson + challenges (secondary)
      if (lesson.lesson != null)
        _pad(_linkRow(
          icon: Icons.headphones,
          label: 'درس اليوم',
          title: lesson.lesson!.title,
          trailing: lesson.lesson!.durationLabel,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DailyLessonPage()),
          ),
        )),
      if (group != null)
        _pad(_linkRow(
          icon: Icons.flag_outlined,
          title: 'التحديات الجماعية',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChallengesPage()),
          ),
        )),

      // 6. Stats strip (one compact card instead of 4 tiles)
      _pad(GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _stat(Icons.stars, '$totalHasanat', 'حسنة', AppColors.gold),
            _divider(),
            _stat(Icons.diamond_outlined, '$himmah', 'الهمّة', AppColors.textSecondary),
            _divider(),
            _stat(Icons.emoji_events_outlined, '${badges.unlockedCount}',
                'ميداليات', AppColors.textSecondary),
          ],
        ),
      )),
    ];

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.emerald,
        onRefresh: () async {
          final uid = auth.user!.id;
          await Future.wait([
            prayer.loadToday(uid),
            streak.loadForUser(uid),
            lesson.loadForUser(uid),
            auth.refreshProfile(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
          children: [
            for (var i = 0; i < sections.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: AppMotion.entrance(context, sections[i], index: i),
              ),
          ],
        ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────
  Widget _pad(Widget c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: c,
      );

  Widget _title(String text, {String? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          children: [
            Text(text, style: AppText.section),
            const Spacer(),
            if (trailing != null) Text(trailing, style: AppText.numberSmall.copyWith(fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _streakChip(BuildContext context, int days) {
    return AppMotion.pulse(
      context,
      Container(
        margin: const EdgeInsetsDirectional.only(end: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.streak.withAlpha(30),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppColors.streak.withAlpha(40), blurRadius: 10)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department,
                color: AppColors.streak, size: 16),
            const SizedBox(width: 4),
            Text('$days يوم متواصل',
                style: AppText.caption.copyWith(
                    color: AppColors.streak, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      trigger: days,
    );
  }

  Widget _prayerDot(BuildContext context, PrayerName p, PrayerLog log) {
    final done = log.isRecorded;
    final color = done ? log.status.color : AppColors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openPrayer(context, p),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? color.withAlpha(40) : Colors.transparent,
                border: Border.all(color: color.withAlpha(done ? 160 : 70)),
              ),
              child: Icon(done ? Icons.check : p.icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(p.arabicName, style: AppText.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _linkRow({
    required IconData icon,
    required String title,
    String? label,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.mint, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null) Text(label, style: AppText.caption),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) Text(trailing, style: AppText.caption),
          if (trailing == null)
            const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: AppText.numberSmall.copyWith(color: color == AppColors.gold ? color : AppColors.text)),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: Colors.white.withAlpha(13));

  Widget _bell(BuildContext context, NotificationProvider n) {
    final unread = n.unreadCount();
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.text, size: 26),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _NotificationsSheet()),
            );
          },
        ),
        if (unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.error, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text('$unread',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  void _openPrayer(BuildContext context, PrayerName prayer) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrayerDetailPage(prayer: prayer)),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final n = context.watch<NotificationProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (n.unreadCount() > 0)
            TextButton(
              onPressed: () => n.markAllRead(auth.user!.id),
              child: const Text('قرأتها كلها',
                  style: TextStyle(color: AppColors.emerald)),
            ),
        ],
      ),
      body: n.items.isEmpty
          ? const Center(
              child: Text('لا توجد إشعارات',
                  style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: n.items.length,
              itemBuilder: (_, i) {
                final item = n.items[i];
                final read = item['is_read'] == true;
                return Card(
                  color: read
                      ? AppColors.surface.withAlpha(120)
                      : AppColors.emerald.withAlpha(36),
                  child: ListTile(
                    leading: Icon(Icons.notifications,
                        color: read
                            ? AppColors.textSecondary
                            : AppColors.emerald),
                    title: Text(item['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    subtitle: Text(item['message'] ?? '',
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                    onTap: () => n.markRead(item['id']),
                  ),
                );
              },
            ),
    );
  }
}