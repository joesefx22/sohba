import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/athkar_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/prayer_engine.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/iman_progress_bar.dart';
import '../../widgets/prayer_card.dart';
import '../prayer/prayer_page.dart';
import '../athkar/athkar_page.dart';
import '../badges/badges_page.dart';
import '../group/group_leaderboard_page.dart';
import '../profile/profile_page.dart';

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
        color: AppColors.surface.withAlpha(220),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(26))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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

  Widget _navItem(int idx, IconData outline, IconData filled, String label) {
    final selected = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected ? AppColors.primaryLinearGradient : null,
              ),
              child: Icon(
                selected ? filled : outline,
                size: 22,
                color:
                    selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color:
                    selected ? AppColors.primaryStart : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ═══════════════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prayer = context.watch<PrayerProvider>();
    final streak = context.watch<StreakProvider>();
    final notifications = context.watch<NotificationProvider>();

    final group = context.watch<GroupProvider>().group;
    final profile = auth.profile;
    final iman = ((profile?['iman'] ?? 0) as num).toDouble();
    final totalHasanat = (profile?['total_hasanat'] ?? 0) as int;

    // Find current focus prayer
    final focus = prayer.currentFocusPrayer;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async {
          final uid = auth.user!.id;
          await Future.wait([
            prayer.loadToday(uid),
            streak.loadForUser(uid),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'السلام عليكم،',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          auth.displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        if (group != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'مجموعة: ${group['name']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _bell(context, notifications),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hero stats card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.gold, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'رصيد الإيمان',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (streak.currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange.withAlpha(120)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.orange,
                                    size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${streak.currentStreak}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      iman.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ImanProgressBar(
                      currentIman: iman - (iman.floorToDouble()),
                      nextTierAt: 100,
                      level: (iman ~/ 100) + 1,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statTile(
                            Icons.stars,
                            '$totalHasanat',
                            'حسنة',
                            AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statTile(
                            Icons.check_circle,
                            '${prayer.todayCompletedCount}/5',
                            'صلوات',
                            AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Current focus
            if (focus != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _focusCard(context, focus),
              ),

            // Prayers section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'صلوات اليوم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            ...PrayerName.values.map((p) {
              final log = prayer.todayLogs[p] ??
                  PrayerLog.empty(
                    userId: auth.user!.id,
                    date: prayer.todayDate,
                    prayer: p,
                  );
              return PrayerCard(
                prayer: p,
                log: log,
                timeline: prayer.timelineFor(p),
                onTap: () => _openPrayer(context, p),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _bell(BuildContext context, NotificationProvider n) {
    final unread = n.unreadCount();
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.text, size: 26),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const _NotificationsSheet(),
              ),
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
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$unread',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _focusCard(BuildContext context, PrayerName focus) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      tintColor: AppColors.teal.withAlpha(60),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.teal.withAlpha(50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(focus.icon, color: AppColors.teal, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الآن',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  focus.arabicName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _openPrayer(context, focus),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('سجّل'),
          ),
        ],
      ),
    );
  }

  void _openPrayer(BuildContext context, PrayerName prayer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrayerDetailPage(prayer: prayer),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
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
                  style: TextStyle(color: AppColors.teal)),
            ),
        ],
      ),
      body: n.items.isEmpty
          ? const Center(
              child: Text(
                'لا توجد إشعارات',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: n.items.length,
              itemBuilder: (_, i) {
                final item = n.items[i];
                final read = item['is_read'] == true;
                return Card(
                  color: read
                      ? AppColors.surface.withAlpha(120)
                      : AppColors.teal.withAlpha(40),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: read ? AppColors.textSecondary : AppColors.teal,
                    ),
                    title: Text(
                      item['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    subtitle: Text(
                      item['message'] ?? '',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    onTap: () => n.markRead(item['id']),
                  ),
                );
              },
            ),
    );
  }
}