import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/athkar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/athkar_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import 'athkar_detail_page.dart';

class AthkarPage extends StatefulWidget {
  const AthkarPage({super.key});

  @override
  State<AthkarPage> createState() => _AthkarPageState();
}

class _AthkarPageState extends State<AthkarPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AthkarProvider>().loadAll(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AthkarProvider>();

    if (provider.loading || provider.categories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.mint),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('الأذكار', style: AppText.heading),
            const SizedBox(height: 4),
            Text('حصن المسلم — أذكار الصباح والمساء', style: AppText.caption),
            const SizedBox(height: 20),
            ...provider.categories
                .map((c) => _categoryCard(context, provider, c)),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(
    BuildContext context,
    AthkarProvider provider,
    AthkarCategory cat,
  ) {
    final done = provider.completedCountIn(cat);
    final total = cat.totalCount;
    final progress = total > 0 ? done / total : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AthkarDetailPage(category: cat),
          ),
        );
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.mint.withAlpha(45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconFor(cat.icon),
                color: AppColors.mint,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        cat.nameAr,
                        style: AppText.subtitle,
                      ),
                      const SizedBox(width: 6),
                      if (cat.isMandatory)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withAlpha(50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'يومي',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withAlpha(26),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.mint),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$done / $total',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    const map = {
      'wb_twilight': Icons.wb_twilight,
      'nights_stay': Icons.nights_stay,
      'mosque': Icons.mosque,
      'bedtime': Icons.bedtime,
      'wb_sunny': Icons.wb_sunny,
    };
    return map[key] ?? Icons.menu_book;
  }
}