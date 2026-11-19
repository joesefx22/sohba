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
    _TabSpec(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    _TabSpec(
      icon: Icons.mosque_outlined,
      activeIcon: Icons.mosque_rounded,
      label: 'العبادات',
    ),
    _TabSpec(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events_rounded,
      label: 'إنجازاتي',
    ),
    _TabSpec(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'المحتوى',
    ),
    _TabSpec(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'حسابي',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<LockProvider>();
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
        color: AppColors.background.withValues(alpha: .96),
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: .18)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88030716),
            blurRadius: 22,
            offset: Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, _navItem),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index) {
    final tab = _tabs[index];
    final selected = _tab == index;
    final color = selected ? AppColors.goldBright : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.gold.withValues(alpha: .22),
                      AppColors.gold.withValues(alpha: .045),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: .72)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: .18),
                      blurRadius: 17,
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected ? tab.activeIcon : tab.icon,
                  key: ValueKey('$index-$selected'),
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                style: AppText.caption.copyWith(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}