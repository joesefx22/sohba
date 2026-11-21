import 'dart:async';
import 'package:flutter/foundation.dart';

import 'adhan_audio_service.dart';
import 'adhan_service.dart';
import 'notification_service.dart';

/// يشغّل صوت الأذان في وقته بالظبط (ما دام التطبيق شغّال).
///
/// - بيتنادى مرة عند بدء التطبيق.
/// - بيعيد الجدولة كل يوم بعد أذان الفجر تلقائيًا.
/// - لو المستخدم قفل الأذان من الإعدادات → مايشغّلش.
class AdhanScheduler {
  AdhanScheduler._();

  static final List<Timer> _timers = [];
  static bool _initialized = false;

  /// هل تم التهيئة؟
  static bool get isInitialized => _initialized;

  /// يبدأ الجدولة لكل أذان النهاردة + يعيد لليوم الجديد.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await AdhanAudioService.init();
    await _scheduleToday();

    // إعادة الجدولة كل يوم الساعة 00:01
    _scheduleDailyRefresh();
  }

  static void _scheduleDailyRefresh() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    final diff = tomorrow.difference(now) + const Duration(minutes: 1);

    Timer(diff, () async {
      await _scheduleToday();
      _scheduleDailyRefresh();
    });
  }

  static Future<void> _scheduleToday() async {
    // إلغاء أي تايمرات قديمة
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();

    final enabled = await NotificationService.isAdhanEnabled();
    if (!enabled) {
      debugPrint('AdhanScheduler: adhan disabled by user');
      return;
    }

    final now = DateTime.now();
    final times = AdhanService.allTimes(onDate: now);

    for (final entry in times.entries) {
      final adhanTime = entry.value;
      if (adhanTime.isBefore(now)) continue;

      final diff = adhanTime.difference(now);
      // لو الوقت قريب جدًا (أقل من 3 ثواني) — تجاهل
      if (diff.inSeconds < 3) continue;

      final timer = Timer(diff, () async {
        debugPrint('AdhanScheduler: playing adhan for ${entry.key.name}');
        await AdhanAudioService.playIfEnabled();
      });
      _timers.add(timer);

      debugPrint(
        'AdhanScheduler: scheduled ${entry.key.name} in '
        '${diff.inMinutes} min',
      );
    }
  }

  /// يعيد الجدولة يدويًا (بعد تغيير الإعدادات أو الموقع).
  static Future<void> reschedule() async {
    await AdhanAudioService.init();
    await _scheduleToday();
  }

  static Future<void> stop() async {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    await AdhanAudioService.stop();
  }
}