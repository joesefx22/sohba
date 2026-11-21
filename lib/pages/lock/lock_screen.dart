import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lock_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<LockProvider>();
    final auth = context.watch<AuthProvider>();

    final prayerName = lock.state.prayer ?? '';
    final prayerEnum = PrayerName.values.firstWhere(
      (p) => p.name == prayerName,
      orElse: () => PrayerName.fajr,
    );

    return GlassScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassContainer(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pause_circle_outline,
                      color: AppColors.warning, size: 72),
                  const SizedBox(height: 16),
                  const Text(
                    'توقفت رحلتك مؤقتًا',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لم تُسجَّل صلاة ${prayerEnum.arabicName} في وقتها',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'استغفر الله وارجع لرحلتك',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'النظام الجديد لا يعتمد على القضاء. '
                          'اعترف بتقصيرك واستغفر، ثم أكمل رحلتك.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _unlock(context),
                      icon: const Icon(Icons.lock_open),
                      label: const Text('استغفرت — افتح رحلتي'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => auth.signOut(),
                    child: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _unlock(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final lock = context.read<LockProvider>();

    final userId = auth.user!.id;

    // النظام الجديد: مفيش قضاء، مفيش توبة برمجية.
    // الصلاة الفائتة تفضل missed بـ 200 سيئة في السجل.
    await lock.unlock(userId);
    await auth.refreshProfile();
  }
}