import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/athkar.dart';
import '../../providers/athkar_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import 'athkar_detail_page.dart';

class AthkarGardensPage extends StatefulWidget {
  const AthkarGardensPage({super.key});

  @override
  State<AthkarGardensPage> createState() => _AthkarGardensPageState();
}

class _AthkarGardensPageState extends State<AthkarGardensPage> {
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

    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mint),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('جنان الأذكار', style: AppText.heading),
        const SizedBox(height: 4),
        Text('حصن المسلم — اختر جنتك',
            style: AppText.caption),
        const SizedBox(height: 20),

        _gardenCard(
          context,
          provider,
          icon: '🌅',
          title: 'جنة أذكار الصباح',
          categoryId: 'morning',
          color: AppColors.gold,
        ),
        const SizedBox(height: 12),
        _gardenCard(
          context,
          provider,
          icon: '🌙',
          title: 'جنة أذكار المساء',
          categoryId: 'evening',
          color: AppColors.rarityEpic,
        ),
        const SizedBox(height: 12),
        _gardenCard(
          context,
          provider,
          icon: '🛏️',
          title: 'جنة أذكار النوم',
          categoryId: 'sleep',
          color: AppColors.iman,
        ),
        const SizedBox(height: 12),
        _prayerAthkarGarden(context, provider),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _gardenCard(
    BuildContext context,
    AthkarProvider provider, {
    required String icon,
    required String title,
    required String categoryId,
    required Color color,
  }) {
    final cat = provider.categories
        .where((c) => c.id == categoryId)
        .firstOrNull;
    final done = cat != null ? provider.completedCountIn(cat) : 0;
    final total = cat?.totalCount ?? 0;
    final progress = total > 0 ? done / total : 0.0;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      onTap: cat == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AthkarDetailPage(category: cat),
                ),
              ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(100)),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.subtitle.copyWith(color: color)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$done / $total',
                    style: AppText.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _prayerAthkarGarden(
      BuildContext context, AthkarProvider provider) {
    final cat = provider.categories
        .where((c) => c.id == 'after_prayer')
        .firstOrNull;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🕌', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('جنة أذكار الصلاة',
                        style: AppText.subtitle
                            .copyWith(color: AppColors.mint)),
                    Text('كل صلاة ليها أذكارها',
                        style: AppText.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (cat == null)
            Text('مش متاح حاليًا', style: AppText.caption)
          else
            ...['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'].map((p) {
              final labels = {
                'fajr': 'الفجر',
                'dhuhr': 'الظهر',
                'asr': 'العصر',
                'maghrib': 'المغرب',
                'isha': 'العشاء',
              };
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AthkarDetailPage(category: cat),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Text('أذكار بعد ${labels[p]}',
                            style: AppText.body.copyWith(fontSize: 14)),
                        const Spacer(),
                        const Icon(Icons.chevron_left,
                            size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}