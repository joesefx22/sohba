import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sohba/services/update_service.dart';
import 'package:sohba/theme/app_colors.dart';
import 'package:sohba/theme/app_text.dart';

Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo info, {
  bool dismissible = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: dismissible && !info.force,
    builder: (ctx) => PopScope(
      canPop: !info.force,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.system_update, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(info.force ? 'تحديث مطلوب' : 'تحديث متاح',
              style: AppText.heading.copyWith(fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار الجديد: ${info.version}',
                style: AppText.body.copyWith(color: AppColors.gold)),
            const SizedBox(height: 12),
            if (info.releaseNotes.isNotEmpty)
              Text(info.releaseNotes, style: AppText.caption),
          ],
        ),
        actions: [
          if (!info.force)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('لاحقًا'),
            ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(info.downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold, foregroundColor: Colors.black,
            ),
            child: const Text('تحميل الآن'),
          ),
        ],
      ),
    ),
  );
}