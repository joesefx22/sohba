import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/athkar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/athkar_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/error_state.dart';

class AthkarDetailPage extends StatelessWidget {
  final AthkarCategory category;
  const AthkarDetailPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AthkarProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(category.nameAr),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: category.items.length,
        itemBuilder: (_, i) {
          final item = category.items[i];
          final progress = provider.progressFor(item.id);
          return _AthkarCard(item: item, progress: progress);
        },
      ),
    );
  }
}

class _AthkarCard extends StatelessWidget {
  final AthkarItem item;
  final UserAthkarProgress? progress;
  const _AthkarCard({required this.item, required this.progress});

  @override
  Widget build(BuildContext context) {
    final count = progress?.count ?? 0;
    final done = progress?.completed ?? false;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic text — Amiri line height for Quranic readability
          Text(
            item.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 18,
              height: 1.9,
              color: AppColors.text,
            ),
          ),
          if (item.translation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.translation!,
                style: AppText.caption.copyWith(height: 1.5),
              ),
            ),
          ],
          if (item.reference != null) ...[
            const SizedBox(height: 8),
            Text(
              item.reference!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.gold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  done
                      ? '✓ تم'
                      : 'التكرار: $count / ${item.repeatCount}',
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.mint : AppColors.textSecondary,
                  ),
                ),
              ),
              if (!done)
                FilledButton.icon(
                  onPressed: () => _increment(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('سبّح'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                const Icon(Icons.check_circle,
                    color: AppColors.mint, size: 32),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _increment(BuildContext context) async {
    final userId = context.read<AuthProvider>().user!.id;
    final provider = context.read<AthkarProvider>();
    final justCompleted =
        await provider.incrementItem(userId: userId, item: item);
    if (justCompleted && context.mounted) {
      AppSnackbar.success(context, 'تقبّل الله');
    }
  }
}