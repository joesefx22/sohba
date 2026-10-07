import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/athkar_seeder.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/error_state.dart';

class SeedAthkarPage extends StatefulWidget {
  const SeedAthkarPage({super.key});

  @override
  State<SeedAthkarPage> createState() => _SeedAthkarPageState();
}

class _SeedAthkarPageState extends State<SeedAthkarPage> {
  bool _running = false;
  bool? _seeded;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final s = await AthkarSeeder.isSeeded(Supabase.instance.client);
    if (mounted) setState(() => _seeded = s);
  }

  Future<void> _run() async {
    setState(() => _running = true);
    final ok = await AthkarSeeder.seed(Supabase.instance.client);
    if (!mounted) return;
    setState(() {
      _running = false;
      _seeded = ok;
    });
    if (ok) {
      AppSnackbar.success(context, 'تم رفع الأذكار بنجاح');
    } else {
      AppSnackbar.error(context, 'فشل الرفع — راجع الـ console');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('رفع الأذكار'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _seeded == true
                      ? Icons.check_circle
                      : Icons.cloud_upload,
                  size: 56,
                  color: _seeded == true
                      ? AppColors.emerald
                      : AppColors.gold,
                ),
                const SizedBox(height: 16),
                Text(
                  _seeded == true
                      ? 'الأذكار موجودة في السيرفر'
                      : 'الأذكار غير مرفوعة بعد',
                  style: AppText.section,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'هذه العملية ترفع حصن المسلم بالكامل من الملف المحلي إلى Supabase. آمنة للتشغيل أكثر من مرة.',
                  style: AppText.caption.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _running ? null : _run,
                  icon: _running
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_running ? 'جارٍ الرفع...' : 'ابدأ الرفع'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}