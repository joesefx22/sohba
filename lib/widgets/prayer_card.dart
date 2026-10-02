import 'package:flutter/material.dart';
import '../models/prayer_log.dart';
import '../services/prayer_engine.dart';
import '../services/adhan_service.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'prayer_status_chip.dart';

/// One row/card for a single prayer with live phase info.
class PrayerCard extends StatelessWidget {
  final PrayerName prayer;
  final PrayerLog log;
  final PrayerTimeline timeline;
  final VoidCallback onTap;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.log,
    required this.timeline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final phase = timeline.phaseAt(now);

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Prayer icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: log.status.color.withAlpha(45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                prayer.icon,
                size: 24,
                color: log.status == PrayerStatus.pending
                    ? AppColors.textSecondary
                    : log.status.color,
              ),
            ),
            const SizedBox(width: 12),

            // Prayer name + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer.arabicName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AdhanService.formatTime(timeline.adhan),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (phase == PrayerPhase.congregationOpen &&
                      !log.isRecorded) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'وقت الجماعة مفتوح',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status chip
            PrayerStatusChip(status: log.status),
          ],
        ),
      ),
    );
  }
}