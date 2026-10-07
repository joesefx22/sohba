import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';

class GroupLeaderboardPage extends StatelessWidget {
  const GroupLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>();
    final auth = context.watch<AuthProvider>();

    if (group.group == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'لم تنضم إلى مجموعة بعد',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.mint,
          onRefresh: () async {
            await group.loadForUser(auth.user!.id);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المجموعة', style: AppText.heading),
                        Text(
                          group.group!['name'] ?? '',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _inviteChip(context, group.group!['invite_code'] ?? ''),
                ],
              ),
              const SizedBox(height: 20),

              // Members leaderboard
              if (group.members.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'لا يوجد أعضاء بعد',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...List.generate(
                  group.members.length,
                  (i) => _memberCard(
                    context,
                    i + 1,
                    group.members[i],
                    auth.user!.id,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inviteChip(BuildContext context, String code) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('كود الدعوة: $code'),
            backgroundColor: AppColors.surface,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gold.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withAlpha(120)),
        ),
        child: Row(
          children: [
            const Icon(Icons.vpn_key, color: AppColors.gold, size: 18),
            const SizedBox(width: 8),
            Text(
              code,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberCard(
    BuildContext context,
    int rank,
    Map<String, dynamic> member,
    String currentUserId,
  ) {
    final profile = member['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] ?? 'عضو';
    final iman = ((profile?['iman'] ?? 0) as num).toDouble();
    final streak = (profile?['current_streak'] ?? 0) as int;
    final userId = member['user_id'] as String?;
    final isMe = userId == currentUserId;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      tintColor: isMe ? AppColors.emerald.withAlpha(40) : null,
      child: Row(
        children: [
          // Rank medal
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rankColor(rank).withAlpha(50),
              border: Border.all(color: _rankColor(rank), width: 2),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(_rankIcon(rank), color: _rankColor(rank), size: 22)
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _rankColor(rank),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppText.subtitle.copyWith(
                          fontSize: 15,
                          color: isMe ? AppColors.mint : AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withAlpha(80),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'أنت',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (streak > 0) ...[
                      const Icon(Icons.local_fire_department,
                          size: 12, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Iman
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                iman.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              Text('إيمان', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _rankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.workspace_premium;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.emoji_events;
      default:
        return Icons.person;
    }
  }
}