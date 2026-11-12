import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/daily_lesson_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class DailyLessonPage extends StatelessWidget {
  const DailyLessonPage({super.key});

  Future<void> _openVideo(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط')),
      );
    }
  }

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
    final hasVideo = (lesson.videoUrl ?? '').isNotEmpty;

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
                      Icon(
                        hasVideo
                            ? Icons.play_circle_outline
                            : Icons.headphones,
                        color: AppColors.goldBright,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasVideo ? 'فيديو' : lesson.durationLabel,
                        style: AppText.caption,
                      ),
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

                  // 🎥 Video button
                  if (hasVideo) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openVideo(context, lesson.videoUrl!),
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text('شاهد الفيديو'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],

                  // 🎧 Audio button
                  if ((lesson.audioUrl ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openVideo(context, lesson.audioUrl!),
                        icon: const Icon(Icons.headphones),
                        label: const Text('استمع للصوت'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.mint,
                          side: BorderSide(
                              color: AppColors.emerald.withAlpha(120)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],

                  if (lesson.transcript != null &&
                      lesson.transcript!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      lesson.transcript!,
                      style: AppText.body.copyWith(height: 1.7),
                    ),
                  ],

                  const SizedBox(height: 20),
                  if (!p.listened)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => p.markListened(auth.user!.id),
                        icon: const Icon(Icons.check),
                        label: const Text('تم الاستماع'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
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