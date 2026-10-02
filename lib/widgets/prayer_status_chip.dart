import 'package:flutter/material.dart';
import '../models/prayer_log.dart';

class PrayerStatusChip extends StatelessWidget {
  final PrayerStatus status;
  const PrayerStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withAlpha(150)),
      ),
      child: Text(
        status.arabicLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}