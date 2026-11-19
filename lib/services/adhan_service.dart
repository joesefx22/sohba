import 'package:adhan/adhan.dart';
import 'package:sohba/config/app_config.dart';
import 'package:sohba/models/prayer_log.dart';

class AdhanService {
  AdhanService._();

  static Coordinates get _coordinates =>
      Coordinates(AppConfig.defaultLatitude, AppConfig.defaultLongitude);

  static CalculationParameters get _params {
    final p = CalculationMethod.egyptian.getParameters();
    p.madhab = Madhab.shafi;
    return p;
  }

  static Map<PrayerName, DateTime> timesForDate(DateTime date) {
    final comps = DateComponents(date.year, date.month, date.day);
    final t = PrayerTimes(_coordinates, comps, _params);
    return {
      PrayerName.fajr: t.fajr,
      PrayerName.dhuhr: t.dhuhr,
      PrayerName.asr: t.asr,
      PrayerName.maghrib: t.maghrib,
      PrayerName.isha: t.isha,
    };
  }

  /// للـ debug
  static Map<PrayerName, DateTime> allTimes() => timesForDate(DateTime.now());

  static String formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}