import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/daily_lesson_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/ribbon_card.dart';

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
          child: CircularProgressIndicator(color: AppColors.goldBright),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            RibbonCard(
              accent: AppColors.iman,
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.iman.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          hasVideo
                              ? Icons.play_circle_outline
                              : Icons.headphones,
                          color: AppColors.iman,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        hasVideo ? 'فيديو' : lesson.durationLabel,
                        style: AppText.caption.copyWith(fontSize: 12),
                      ),
                      const Spacer(),
                      if (p.listened)
                        const Row(children: [
                          Icon(Icons.check_circle,
                              color: AppColors.mint, size: 18),
                          SizedBox(width: 4),
                          Text('تم',
                              style: TextStyle(
                                color: AppColors.mint,
                                fontWeight: FontWeight.w600,
                              )),
                        ]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),

                  if (hasVideo) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openVideo(context, lesson.videoUrl!),
                        icon: const Icon(Icons.play_arrow, size: 26),
                        label: const Text('شاهد الفيديو'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],

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
                          foregroundColor: AppColors.goldBright,
                          side: BorderSide(
                            color: AppColors.gold.withValues(alpha: .6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (lesson.transcript != null &&
                      lesson.transcript!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lesson.transcript!,
                        style: AppText.body.copyWith(
                          fontSize: 14,
                          height: 1.8,
                        ),
                      ),
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
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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