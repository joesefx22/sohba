import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../../models/badge.dart';
import '../../providers/badge_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/ribbon_card.dart';

class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BadgeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ── Header card ──
            RibbonCard(
              accent: AppColors.gold,
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: .4),
                          ),
                        ),
                        child: const Icon(Icons.emoji_events_rounded,
                            color: AppColors.goldBright, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الميداليات',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${provider.unlockedCount} / ${provider.totalCount} مفتوحة',
                              style: AppText.caption.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: provider.completionPercent,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: .10),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.goldBright,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Categories ──
            ...BadgeCategory.values.map((cat) {
              final list = provider.byCategory(cat);
              if (list.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, right: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat.labelAr,
                          style: const TextStyle(
                            color: AppColors.goldBright,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
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
                  ? color.withValues(alpha: .22)
                  : Colors.black.withValues(alpha: .35),
              border: Border.all(
                color: unlocked ? color : Colors.grey.shade800,
                width: 2,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: .45),
                        blurRadius: 14,
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
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: badge.tier.color.withValues(alpha: .22),
                border: Border.all(color: badge.tier.color, width: 3),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: badge.tier.color.withValues(alpha: .5),
                          blurRadius: 22,
                        ),
                      ]
                    : null,
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
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: badge.tier.color.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: badge.tier.color.withValues(alpha: .5),
                ),
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