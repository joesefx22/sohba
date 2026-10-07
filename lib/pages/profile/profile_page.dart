import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/badge_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../admin/admin_dashboard_page.dart';
import '../admin/seed_athkar_page.dart';
import '../settings/settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final streak = context.watch<StreakProvider>();
    final badges = context.watch<BadgeProvider>();
    final group = context.watch<GroupProvider>();

    final profile = auth.profile ?? {};
    final iman = ((profile['iman'] ?? 0) as num).toDouble();
    final hasanat = (profile['total_hasanat'] ?? 0) as int;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.mint.withAlpha(80),
                    child: Text(
                      auth.displayName.characters.first,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.displayName,
                    style: AppText.section.copyWith(fontSize: 22),
                  ),
                  if (group.group != null)
                    Text(
                      group.group!['name'] ?? '',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'إيمان',
                    iman.toStringAsFixed(1),
                    AppColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard('حسنات', '$hasanat', AppColors.mint),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'مواصلة',
                    '${streak.currentStreak}',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'ميداليات',
                    '${badges.unlockedCount}/${badges.totalCount}',
                    AppColors.rarityEpic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _item(Icons.settings, 'الإعدادات', AppColors.mint, () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            }),
            _item(Icons.admin_panel_settings, 'لوحة الإدارة', AppColors.gold,
                () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AdminDashboardPage()),
              );
            }),
            _item(Icons.cloud_upload, 'رفع الأذكار (أدمن)',
                AppColors.rarityEpic, () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SeedAthkarPage()),
              );
            }),
            _item(Icons.logout, 'تسجيل الخروج', AppColors.error, () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
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
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.numberSmall.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, Color color, VoidCallback onTap) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
      ),
    );
  }
}