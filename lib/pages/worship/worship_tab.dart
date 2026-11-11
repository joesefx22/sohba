import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../athkar/athkar_page.dart';
import '../prayer/prayer_page.dart';
import '../qiyam/qiyam_page.dart';

class WorshipTab extends StatelessWidget {
  const WorshipTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('العبادات', style: AppText.heading),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: TabBar(
            indicatorColor: AppColors.emerald,
            labelColor: AppColors.mint,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'الصلاة'),
              Tab(text: 'الأذكار'),
              Tab(text: 'القيام والسنن'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              PrayerPage(),
              AthkarPage(),
              QiyamPage(),
            ],
          ),
        ),
      ),
    );
  }
}