import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../../models/badge.dart';
import '../../providers/badge_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BadgeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('الميداليات', style: AppText.heading),
            const SizedBox(height: 4),
            Text(
              '${provider.unlockedCount} / ${provider.totalCount} مفتوحة',
              style: AppText.caption,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.completionPercent,
                minHeight: 10,
                backgroundColor: Colors.white.withAlpha(26),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.goldBright),
              ),
            ),
            const SizedBox(height: 24),
            ...BadgeCategory.values.map((cat) {
              final list = provider.byCategory(cat);
              if (list.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      cat.labelAr,
                      style: AppText.section,
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _BadgeTile(
                      badge: list[i],
                      unlocked: provider.isUnlocked(list[i].id),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Badge badge;
  final bool unlocked;
  const _BadgeTile({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? badge.tier.color : Colors.grey.shade700;
    return GestureDetector(
      onTap: () => _show(context),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? color.withAlpha(50)
                  : Colors.black.withAlpha(60),
              border: Border.all(
                color: unlocked ? color : Colors.grey.shade800,
                width: 2,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: color.withAlpha(90),
                        blurRadius: 12,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              unlocked ? badge.iconData : Icons.help_outline,
              size: 32,
              color: unlocked ? color : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            unlocked ? badge.nameAr : '???',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: unlocked ? AppColors.text : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badge.tier.color.withAlpha(50),
                border: Border.all(color: badge.tier.color, width: 3),
              ),
              child: Icon(
                unlocked ? badge.iconData : Icons.help_outline,
                size: 48,
                color: badge.tier.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              unlocked ? badge.nameAr : 'ميدالية مقفلة',
              style: AppText.section.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badge.tier.color.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.tier.labelAr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badge.tier.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}