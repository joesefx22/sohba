import 'package:flutter/material.dart';
import '../models/prayer_log.dart';
import '../theme/app_theme.dart';

class PrayerStatusChip extends StatelessWidget {
  final PrayerStatus status;
  const PrayerStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withAlpha(120)),
      ),
      child: Text(
        status.arabicLabel,
        style: AppText.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}