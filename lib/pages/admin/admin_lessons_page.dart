import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class AdminLessonsPage extends StatefulWidget {
  const AdminLessonsPage({super.key});

  @override
  State<AdminLessonsPage> createState() => _AdminLessonsPageState();
}

class _AdminLessonsPageState extends State<AdminLessonsPage> {
  List<Map<String, dynamic>> _lessons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('daily_lessons')
          .select()
          .order('publish_date', ascending: false);
      _lessons = (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdminLessons.load: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final titleCtrl = TextEditingController();
    final videoCtrl = TextEditingController();
    final audioCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '240');
    final transcriptCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('درس جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: videoCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط الفيديو (YouTube / Drive / mp4)',
                  prefixIcon: Icon(Icons.play_circle_outline),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: audioCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط الصوت (mp3) — اختياري',
                  prefixIcon: Icon(Icons.headphones),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المدة بالثواني',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: transcriptCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'النص'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نشر'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (videoCtrl.text.trim().isEmpty && audioCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      AppSnackbar.error(context, 'أضف رابط فيديو أو صوت على الأقل');
      return;
    }

    try {
      await Supabase.instance.client.from('daily_lessons').insert({
        'id': 'l_${DateTime.now().millisecondsSinceEpoch}',
        'title': titleCtrl.text.trim(),
        'video_url': videoCtrl.text.trim().isEmpty
            ? null
            : videoCtrl.text.trim(),
        'audio_url': audioCtrl.text.trim().isEmpty
            ? null
            : audioCtrl.text.trim(),
        'duration_seconds': int.tryParse(durationCtrl.text.trim()) ?? 240,
        'transcript': transcriptCtrl.text.trim().isEmpty
            ? null
            : transcriptCtrl.text.trim(),
        'publish_date': DateTime.now().toIso8601String().split('T').first,
      });
      await _load();
      if (!mounted) return;
      AppSnackbar.success(context, 'تم نشر الدرس');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'فشل النشر: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> lesson) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('حذف الدرس؟'),
        content: Text(lesson['title'] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await Supabase.instance.client
          .from('daily_lessons')
          .delete()
          .eq('id', lesson['id']);
      await _load();
      if (!mounted) return;
      AppSnackbar.success(context, 'تم الحذف');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'فشل: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('إدارة الدروس'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.mint))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppButton.primary(
                    label: 'درس جديد',
                    onPressed: _add,
                    icon: Icons.add,
                  ),
                  const SizedBox(height: 16),
                  if (_lessons.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'لا توجد دروس — ابدأ بإضافة درس جديد',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._lessons.map((l) => GlassContainer(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l['title'] ?? '',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${l['publish_date'] ?? ''}',
                                    style: const TextStyle(fontSize: 11)),
                                if (l['video_url'] != null)
                                  const Row(children: [
                                    Icon(Icons.play_circle,
                                        size: 12, color: AppColors.gold),
                                    SizedBox(width: 4),
                                    Text('فيديو',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gold)),
                                  ]),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () => _delete(l),
                            ),
                          ),
                        )),
                ],
              ),
      ),
    );
  }
}