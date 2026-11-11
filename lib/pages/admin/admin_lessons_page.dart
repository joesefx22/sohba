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
    final urlCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '240');
    final transcriptCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('درس جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                    labelText: 'رابط الصوت (mp3)'),
              ),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'المدة بالثواني'),
              ),
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
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نشر')),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await Supabase.instance.client.from('daily_lessons').insert({
        'id': 'l_${DateTime.now().millisecondsSinceEpoch}',
        'title': titleCtrl.text.trim(),
        'audio_url': urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
        'duration_seconds':
            int.tryParse(durationCtrl.text.trim()) ?? 240,
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
                  ..._lessons.map((l) => GlassContainer(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        child: ListTile(
                          title: Text(l['title'] ?? ''),
                          subtitle: Text(
                              '${l['publish_date'] ?? ''} — ${l['duration_seconds'] ?? 0}ث'),
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}