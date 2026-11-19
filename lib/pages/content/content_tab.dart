import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../lessons/daily_lesson_page.dart';
import '../ledger/ledger_page.dart';

class ContentTab extends StatelessWidget {
  const ContentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('المحتوى', style: AppText.heading),
            const SizedBox(height: 4),
            Text('دروس ومصادر', style: AppText.caption),
            const SizedBox(height: 20),

            _card(
              context,
              icon: Icons.headphones,
              title: 'دروس اليوم',
              subtitle: 'دروس قصيرة أقل من 5 دقائق',
              onTap: () => _push(context, const DailyLessonPage()),
            ),
            const SizedBox(height: 10),
            _card(
              context,
              icon: Icons.receipt_long,
              title: 'سجل رصيدي',
              subtitle: 'كل ما كسبته أو خسرته',
              onTap: () => _push(context, const LedgerPage()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.mint.withAlpha(36),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.mint, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}