import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/himmah_provider.dart';
import '../providers/streak_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_button.dart';
import '../widgets/error_state.dart';

class StreakProtectionSheet extends StatelessWidget {
  const StreakProtectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const StreakProtectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ REMOVED: final streak = context.watch<StreakProvider>(); (unused)
    final himmah = context.watch<HimmahProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.local_fire_department,
              size: 56, color: AppColors.streak),
          const SizedBox(height: 12),
          Text('حافظ على سلسلتك',
              style: AppText.heading.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            'فاتك يوم أمس بدون نشاط. ادفع 1 همّة لحماية سلسلتك والاستمرار.',
            style: AppText.caption.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('رصيدك: ',
                  style: AppText.caption.copyWith(fontSize: 14)),
              Text('${himmah.balance} همّة',
                  style: AppText.numberSmall.copyWith(
                      fontSize: 18, color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            onPressed: himmah.balance < 1
                ? null
                : () => _protect(context),
            label: 'ادفع 1 همّة',
            icon: Icons.shield,
            expanded: true,
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.background,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ليس الآن',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _protect(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final streak = context.read<StreakProvider>();
    final himmah = context.read<HimmahProvider>();

    final ok = await streak.protectYesterday(auth.user!.id);
    if (!context.mounted) return;

    if (ok) {
      await himmah.refreshBalance(auth.user!.id);
      await auth.refreshProfile();
      if (!context.mounted) return;
      Navigator.pop(context);
      AppSnackbar.success(context, 'تم الحفاظ على سلسلتك');
    } else {
      AppSnackbar.error(context, 'فشل — تأكد من رصيدك');
    }
  }
}