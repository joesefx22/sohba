import 'package:adhan/adhan.dart';
import 'package:sohba/config/app_config.dart';
import 'package:sohba/models/prayer_log.dart';

class AdhanService {
  AdhanService._();

  static double _lat = AppConfig.defaultLatitude;
  static double _lng = AppConfig.defaultLongitude;

  /// يستدعيها splash_page و settings_page بعد قراءة الموقع.
  static void setLocation(double lat, double lng) {
    _lat = lat;
    _lng = lng;
  }

  static Coordinates get _coordinates => Coordinates(_lat, _lng);

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

  /// وقت صلاة واحدة في يوم محدد (افتراضي = اليوم).
  static DateTime timeFor(PrayerName prayer, {DateTime? onDate}) {
    final date = onDate ?? DateTime.now();
    return timesForDate(date)[prayer]!;
  }

  /// كل أوقات اليوم (افتراضي = اليوم).
  /// ✅ تقبل `onDate` — يستخدمها adhan_scheduler.dart.
  static Map<PrayerName, DateTime> allTimes({DateTime? onDate}) =>
      timesForDate(onDate ?? DateTime.now());

  static String formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}