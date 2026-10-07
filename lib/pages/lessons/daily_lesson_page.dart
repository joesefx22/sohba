import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/daily_lesson_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class DailyLessonPage extends StatelessWidget {
  const DailyLessonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DailyLessonProvider>();
    final auth = context.watch<AuthProvider>();

    if (p.loading) {
      return const GlassScaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.mint),
        ),
      );
    }
    if (p.lesson == null) {
      return const GlassScaffold(
        body: Center(
          child: Text(
            'لا يوجد درس اليوم',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final lesson = p.lesson!;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('درس اليوم'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.headphones,
                          color: AppColors.goldBright, size: 24),
                      const SizedBox(width: 8),
                      Text(lesson.durationLabel, style: AppText.caption),
                      const Spacer(),
                      if (p.listened)
                        const Row(children: [
                          Icon(Icons.check_circle,
                              color: AppColors.mint, size: 18),
                          SizedBox(width: 4),
                          Text('تم',
                              style: TextStyle(color: AppColors.mint)),
                        ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lesson.title,
                    style: AppText.section.copyWith(fontSize: 22),
                  ),
                  if (lesson.transcript != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      lesson.transcript!,
                      style: AppText.body.copyWith(height: 1.7),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {}, // TODO: audio player
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('استمع'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (!p.listened) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => p.markListened(auth.user!.id),
                            icon: const Icon(Icons.check),
                            label: const Text('تم'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}