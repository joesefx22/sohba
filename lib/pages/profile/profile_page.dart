import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/streak_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/ribbon_card.dart';
import '../admin/admin_dashboard_page.dart';
import '../admin/admin_lessons_page.dart';
import '../leaderboard/leaderboard_page.dart';
import '../ledger/ledger_page.dart';
import '../qiyam/qiyam_page.dart';
import '../settings/settings_page.dart';
import '../titles/titles_page.dart';

class ProfilePage extends StatelessWidget {
  final bool embedded;
  const ProfilePage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final streak = context.watch<StreakProvider>();
    final badges = context.watch<BadgeProvider>();
    final group = context.watch<GroupProvider>();

    final profile = auth.profile ?? {};
    final hasanat = (profile['total_hasanat'] ?? 0) as int;
    final sayyiat = (profile['total_sayyiat_unrepented'] ?? 0) as int;
    final avatarUrl = profile['avatar_url'] as String?;
    final initial = auth.displayName.isNotEmpty
        ? auth.displayName.characters.first
        : 'ص';

    final body = SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _ProfileHero(
            name: auth.displayName,
            groupName: group.group?['name'] as String?,
            avatarUrl: avatarUrl,
            initial: initial,
            hasanat: hasanat,
            sayyiat: sayyiat,
            streak: streak.currentStreak,
            unlockedBadges: badges.unlockedCount,
            totalBadges: badges.totalCount,
          ),
          const SizedBox(height: 24),

          _item(Icons.settings, 'الإعدادات', AppColors.mint, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          }),
          _item(Icons.leaderboard, 'الترتيب الأسبوعي', AppColors.gold, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardPage()),
            );
          }),
          _item(Icons.workspace_premium, 'الألقاب', AppColors.gold, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TitlesPage()),
            );
          }),
          _item(Icons.receipt_long, 'سجل رصيدي', AppColors.mint, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LedgerPage()),
            );
          }),
          _item(Icons.nights_stay, 'القيام', AppColors.iman, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QiyamPage()),
            );
          }),

          if (auth.isAdmin) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: AppColors.goldBright, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'أدوات الإدارة',
                    style: AppText.caption.copyWith(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _item(Icons.admin_panel_settings, 'لوحة الإدارة', AppColors.gold,
                () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AdminDashboardPage()),
              );
            }),
            _item(Icons.play_lesson, 'إدارة الدروس', AppColors.gold, () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AdminLessonsPage()),
              );
            }),
          ],

          const SizedBox(height: 8),
          _item(Icons.logout, 'تسجيل الخروج', AppColors.error, () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.surfaceElevated,
                title: const Text('تسجيل الخروج؟',
                    style: TextStyle(color: AppColors.text)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('خروج',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/splash',
                  (_) => false,
                );
              }
            }
          }),
        ],
      ),
    );

    if (embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
      );
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: body,
    );
  }

  Widget _item(IconData icon, String title, Color color, VoidCallback onTap) {
    return RibbonCard(
      accent: color,
      radius: 18,
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withValues(alpha: .4)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing:
            const Icon(Icons.chevron_left, color: AppColors.textSecondary),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.groupName,
    required this.avatarUrl,
    required this.initial,
    required this.hasanat,
    required this.sayyiat,
    required this.streak,
    required this.unlockedBadges,
    required this.totalBadges,
  });

  final String name;
  final String? groupName;
  final String? avatarUrl;
  final String initial;
  final int hasanat;
  final int sayyiat;
  final int streak;
  final int unlockedBadges;
  final int totalBadges;

  @override
  Widget build(BuildContext context) {
    return RibbonCard(
      accent: AppColors.gold,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: .45),
                  blurRadius: 22,
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
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (groupName != null && groupName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 20, height: 1, color: AppColors.gold),
                const SizedBox(width: 8),
                Text(
                  groupName!,
                  style: const TextStyle(
                    color: AppColors.goldBright,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 20, height: 1, color: AppColors.gold),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _stat(
                  Icons.eco_rounded,
                  '$hasanat',
                  'حسنات',
                  AppColors.emerald,
                ),
              ),
              _divider(),
              Expanded(
                child: _stat(
                  Icons.remove_circle_outline,
                  '$sayyiat',
                  'سيئات',
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _stat(
                  Icons.local_fire_department_rounded,
                  '$streak',
                  'مواصلة',
                  AppColors.streak,
                ),
              ),
              _divider(),
              Expanded(
                child: _stat(
                  Icons.emoji_events_rounded,
                  '$unlockedBadges/$totalBadges',
                  'ميداليات',
                  AppColors.iman,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppText.caption.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 48,
        color: AppColors.gold.withValues(alpha: .22),
      );
}