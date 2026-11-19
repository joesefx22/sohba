import 'package:adhan/adhan.dart';

import '../config/app_config.dart';
import '../models/prayer_log.dart';

class AdhanService {
  AdhanService._();

  static Coordinates _coordinates = Coordinates(
    AppConfig.defaultLatitude,
    AppConfig.defaultLongitude,
  );

  static CalculationParameters? _params;

  static void setLocation(double latitude, double longitude) {
    _coordinates = Coordinates(latitude, longitude);
  }

  static CalculationParameters get _parameters {
    if (_params != null) return _params!;
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    _params = params;
    return params;
  }

  static PrayerTimes getTodayTimes() =>
      PrayerTimes.today(_coordinates, _parameters);

  static PrayerTimes getTimesFor(DateTime date) {
    final components = DateComponents(date.year, date.month, date.day);
    return PrayerTimes(_coordinates, components, _parameters);
  }

  static DateTime timeFor(PrayerName prayer, {DateTime? onDate}) {
    final date = onDate ?? DateTime.now();
    final times = getTimesFor(date);
    switch (prayer) {
      case PrayerName.fajr:
        return times.fajr;
      case PrayerName.dhuhr:
        return times.dhuhr;
      case PrayerName.asr:
        return times.asr;
      case PrayerName.maghrib:
        return times.maghrib;
      case PrayerName.isha:
        return times.isha;
    }
  }

  static DateTime sunrise({DateTime? onDate}) {
    final date = onDate ?? DateTime.now();
    return getTimesFor(date).sunrise;
  }

  static Map<PrayerName, DateTime> allTimes({DateTime? onDate}) {
    final date = onDate ?? DateTime.now();
    final times = getTimesFor(date);
    return {
      PrayerName.fajr: times.fajr,
      PrayerName.dhuhr: times.dhuhr,
      PrayerName.asr: times.asr,
      PrayerName.maghrib: times.maghrib,
      PrayerName.isha: times.isha,
    };
  }

  static PrayerName? getCurrentPrayer({DateTime? now}) {
    final times = getTodayTimes();
    final current = times.currentPrayer();
    switch (current) {
      case Prayer.fajr:
        return PrayerName.fajr;
      case Prayer.dhuhr:
        return PrayerName.dhuhr;
      case Prayer.asr:
        return PrayerName.asr;
      case Prayer.maghrib:
        return PrayerName.maghrib;
      case Prayer.isha:
        return PrayerName.isha;
      case Prayer.none:
      case Prayer.sunrise:
        return null;
    }
  }

  static PrayerName? getNextPrayer({DateTime? now}) {
    final times = getTodayTimes();
    final next = times.nextPrayer();
    switch (next) {
      case Prayer.fajr:
        return PrayerName.fajr;
      case Prayer.dhuhr:
        return PrayerName.dhuhr;
      case Prayer.asr:
        return PrayerName.asr;
      case Prayer.maghrib:
        return PrayerName.maghrib;
      case Prayer.isha:
        return PrayerName.isha;
      case Prayer.none:
      case Prayer.sunrise:
        return null;
    }
  }

  static Duration timeUntilNextPrayer({DateTime? now}) {
    final current = now ?? DateTime.now();
    final next = getNextPrayer(now: current);
    if (next == null) return Duration.zero;

    var nextTime = timeFor(next, onDate: current);
    if (nextTime.isBefore(current)) {
      nextTime = timeFor(next, onDate: current.add(const Duration(days: 1)));
    }
    return nextTime.difference(current);
  }

  static Duration timeSinceCurrentPrayer({DateTime? now}) {
    final current = now ?? DateTime.now();
    final currentPrayer = getCurrentPrayer(now: current);
    if (currentPrayer == null) return Duration.zero;
    final prayerTime = timeFor(currentPrayer, onDate: current);
    return current.difference(prayerTime);
  }

  static String formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}