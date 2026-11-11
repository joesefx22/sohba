import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lock_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/glass_scaffold.dart';
import 'achievements/achievements_tab.dart';
import 'content/content_tab.dart';
import 'home/dashboard_v2.dart';
import 'lock/lock_screen.dart';
import 'profile/profile_page.dart';
import 'worship/worship_tab.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _tab = 0;

  static const _tabs = [
    _TabSpec(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'الرئيسية'),
    _TabSpec(icon: Icons.mosque_outlined, activeIcon: Icons.mosque, label: 'العبادات'),
    _TabSpec(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'إنجازاتي'),
    _TabSpec(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'المحتوى'),
    _TabSpec(icon: Icons.person_outline, activeIcon: Icons.person, label: 'حسابي'),
  ];

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<LockProvider>();

    // قفل الحساب يمنع أي تنقل
    if (lock.isLocked) return const LockScreen();

    return GlassScaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          DashboardV2(),
          WorshipTab(),
          AchievementsTab(),
          ContentTab(),
          ProfilePage(embedded: true),
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) => _navItem(i)),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx) {
    final spec = _tabs[idx];
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              child: Icon(selected ? spec.activeIcon : spec.icon,
                  size: 22, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              spec.label,
              style: AppText.caption.copyWith(
                fontSize: 10,
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

class _TabSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}