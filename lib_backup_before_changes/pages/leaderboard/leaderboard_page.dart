import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/ribbon_card.dart';

class LeaderboardPage extends StatefulWidget {
  final bool embedded;

  const LeaderboardPage({super.key, this.embedded = false});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool _showMe = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().load();
      _loadShowMe();
    });
  }

  Future<void> _loadShowMe() async {
    final auth = context.read<AuthProvider>();
    final v = auth.profile?['show_in_leaderboard'] as bool?;
    if (mounted) setState(() => _showMe = v ?? true);
  }

  Future<void> _toggleShowMe(bool v) async {
    final auth = context.read<AuthProvider>();
    setState(() => _showMe = v);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'show_in_leaderboard': v}).eq('id', auth.user!.id);
      await auth.refreshProfile();
      if (!mounted) return;
      context.read<LeaderboardProvider>().load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _showMe = !v);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LeaderboardProvider>();
    final auth = context.watch<AuthProvider>();
    final myId = auth.user?.id;

    final body = SafeArea(
      child: p.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.goldBright),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                RibbonCard(
                  accent: _showMe ? AppColors.emerald : AppColors.textSecondary,
                  radius: 20,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: SwitchListTile(
                    title: const Text(
                      'إظهار اسمي في الترتيب',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'سيبقى اسمك مخفياً "عبد من عباد الله" إن عطّلت',
                      style: AppText.caption.copyWith(fontSize: 11),
                    ),
                    value: _showMe,
                    activeThumbColor: AppColors.goldBright,
                    activeTrackColor: AppColors.gold.withValues(alpha: .35),
                    onChanged: _toggleShowMe,
                  ),
                ),
                const SizedBox(height: 16),
                if (p.entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'لا توجد بيانات هذا الأسبوع',
                        style: AppText.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...p.entries.map((e) {
                    final isMe = e.userId == myId;
                    return _entryCard(e, isMe);
                  }),
              ],
            ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('الترتيب الأسبوعي'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: body,
      );
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('الترتيب الأسبوعي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: body,
    );
  }

  Widget _entryCard(LeaderboardEntry e, bool isMe) {
    final rankColor = _rankColor(e.rank);
    final accent = isMe ? AppColors.emerald : rankColor;

    return RibbonCard(
      accent: accent,
      radius: 18,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      tintColor: isMe ? AppColors.emerald.withValues(alpha: .10) : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: .18),
              border: Border.all(color: rankColor.withValues(alpha: .7), width: 2),
            ),
            child: Center(
              child: e.rank <= 3
                  ? Icon(_rankIcon(e.rank), color: rankColor, size: 20)
                  : Text(
                      '${e.rank}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    isMe ? 'أنت' : e.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMe ? AppColors.mint : AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (e.currentStreak > 0) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.local_fire_department,
                      size: 13, color: AppColors.streak),
                  Text(
                    '${e.currentStreak}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.streak,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${e.weeklyPoints}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.goldBright,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text('حسنة',
              style: AppText.caption.copyWith(fontSize: 10)),
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
        return AppColors.gold;
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