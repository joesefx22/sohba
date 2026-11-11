import 'package:flutter/material.dart' hide Title; // ← حل الـ ambiguity

import 'package:provider/provider.dart';

import '../../models/title.dart';
import '../../providers/auth_provider.dart';
import '../../providers/title_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

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
                child: CircularProgressIndicator(color: AppColors.mint))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (p.activeTitle != null) ...[
                    Text('لقبك الحالي', style: AppText.caption),
                    const SizedBox(height: 8),
                    _activeTitleCard(p.activeTitle!),
                    const SizedBox(height: 20),
                  ],
                  if (p.unlockedTitles.isNotEmpty) ...[
                    Text('الألقاب المكتسبة', style: AppText.section),
                    const SizedBox(height: 8),
                    ...p.unlockedTitles.map((t) => _titleCard(t, true)),
                    const SizedBox(height: 20),
                  ],
                  if (p.lockedTitles.isNotEmpty) ...[
                    Text('الألقاب المقفلة', style: AppText.section),
                    const SizedBox(height: 8),
                    ...p.lockedTitles.map((t) => _titleCard(t, false)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _activeTitleCard(Title title) {
    return GlassContainer(
      level: GlassLevel.featured,
      accent: AppColors.gold,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(title.iconData, color: AppColors.gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.nameAr,
                    style: AppText.section.copyWith(
                        color: AppColors.goldBright, fontSize: 20)),
                Text(title.description, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleCard(Title title, bool unlocked) {
    return GlassContainer(
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
                  ? AppColors.gold.withAlpha(40)
                  : Colors.grey.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? title.iconData : Icons.help_outline,
              color: unlocked ? AppColors.gold : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unlocked ? title.nameAr : 'لقب مقفل',
                    style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: unlocked
                            ? AppColors.text
                            : AppColors.textSecondary)),
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