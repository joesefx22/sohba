import 'package:flutter/material.dart' hide Title;
import 'package:provider/provider.dart';

import '../../models/title.dart';
import '../../providers/auth_provider.dart';
import '../../providers/title_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/ribbon_card.dart';

class TitlesPage extends StatefulWidget {
  const TitlesPage({super.key});

  @override
  State<TitlesPage> createState() => _TitlesPageState();
}

class _TitlesPageState extends State<TitlesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.id;
      if (uid != null) context.read<TitleProvider>().loadForUser(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TitleProvider>();

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('الألقاب'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: p.loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.goldBright),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (p.activeTitle != null) ...[
                    _section('لقبك الحالي'),
                    _activeTitleCard(p.activeTitle!),
                    const SizedBox(height: 20),
                  ],
                  if (p.unlockedTitles.isNotEmpty) ...[
                    _section('الألقاب المكتسبة'),
                    ...p.unlockedTitles.map((t) => _titleCard(t, true)),
                    const SizedBox(height: 20),
                  ],
                  if (p.lockedTitles.isNotEmpty) ...[
                    _section('الألقاب المقفلة'),
                    ...p.lockedTitles.map((t) => _titleCard(t, false)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4, top: 10),
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
            title,
            style: const TextStyle(
              color: AppColors.goldBright,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeTitleCard(Title title) {
    return RibbonCard(
      accent: AppColors.gold,
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: .2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: .5),
                width: 2,
              ),
            ),
            child: Icon(title.iconData,
                color: AppColors.goldBright, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.nameAr,
                  style: const TextStyle(
                    color: AppColors.goldBright,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title.description, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleCard(Title title, bool unlocked) {
    final accent = unlocked ? AppColors.gold : AppColors.textSecondary;
    return RibbonCard(
      accent: accent,
      radius: 18,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      onTap: unlocked ? () => _setActive(title) : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.gold.withValues(alpha: .18)
                  : Colors.grey.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked
                    ? AppColors.gold.withValues(alpha: .45)
                    : Colors.grey.withValues(alpha: .25),
              ),
            ),
            child: Icon(
              unlocked ? title.iconData : Icons.help_outline,
              color: unlocked ? AppColors.goldBright : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unlocked ? title.nameAr : 'لقب مقفل',
                  style: TextStyle(
                    color: unlocked ? AppColors.text : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(title.description, style: AppText.caption),
              ],
            ),
          ),
          if (unlocked)
            IconButton(
              icon: const Icon(Icons.check_circle_outline,
                  color: AppColors.mint, size: 22),
              onPressed: () => _setActive(title),
            ),
        ],
      ),
    );
  }

  Future<void> _setActive(Title title) async {
    final auth = context.read<AuthProvider>();
    final p = context.read<TitleProvider>();
    final ok = await p.setActive(auth.user!.id, title.id);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'تم تفعيل اللقب: ${title.nameAr}');
    } else {
      AppSnackbar.error(context, 'فشل');
    }
  }
}