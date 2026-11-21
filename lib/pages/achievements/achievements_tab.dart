import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/habit_streak_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../badges/badges_page.dart';
import '../titles/titles_page.dart';

class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('إنجازاتي', style: AppText.heading),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'الميداليات'),
              Tab(text: 'الألقاب'),
              Tab(text: 'السلاسل'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              BadgesPage(),
              TitlesPage(),
              _StreaksListView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreaksListView extends StatelessWidget {
  const _StreaksListView();

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitStreakProvider>();

    if (habits.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.mint));
    }
    if (habits.all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'ابدأ عادة جديدة وستظهر سلسلتك هنا',
            style: AppText.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('السلاسل المتصلة',
            style: AppText.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ...habits.all.map(_streakCard),
      ],
    );
  }

  Widget _streakCard(HabitStreak h) {
    final color =
        h.currentStreak > 0 ? AppColors.streak : AppColors.textSecondary;
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_fire_department,
                color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.labelAr,
                    style: AppText.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('الأطول: ${h.longestStreak} يوم',
                    style: AppText.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${h.currentStreak}',
                  style: AppText.numberSmall.copyWith(
                      fontSize: 22, color: color)),
              Text('يوم', style: AppText.caption.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}