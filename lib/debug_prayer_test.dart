import 'package:flutter/material.dart';
import 'package:sohba/models/prayer_log.dart';
import 'package:sohba/services/adhan_service.dart';
import 'package:sohba/services/prayer_engine.dart';

class DebugPrayerPage extends StatelessWidget {
  const DebugPrayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final allTimes = AdhanService.allTimes();
    final allTimelines = PrayerEngine.computeAllTimelines();

    return Scaffold(
      appBar: AppBar(title: const Text('توقيتات اليوم — القاهرة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final prayer in PrayerName.values) ...[
            Text(
              '${prayer.arabicName} — ${AdhanService.formatTime(allTimes[prayer]!)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('  نافذة الجماعة: '
                '${AdhanService.formatTime(allTimelines[prayer]!.congregationOpen)}'
                ' → ${AdhanService.formatTime(allTimelines[prayer]!.congregationClose)}'),
            Text('  نافذة الانفراد حتى: '
                '${AdhanService.formatTime(allTimelines[prayer]!.individualClose)}'),
            Text('  نافذة القضاء حتى: '
                '${AdhanService.formatTime(allTimelines[prayer]!.qadaClose)}'),
            const Divider(),
          ],
        ],
      ),
    );
  }
}