import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class LocationService {
  LocationService._();

  static const _keyLat = 'loc_lat';
  static const _keyLng = 'loc_lng';
  static const _keyCity = 'loc_city';

  /// Returns the saved (lat, lng) or the Cairo default.
  static Future<({double lat, double lng, String city})> current() async {
    final p = await SharedPreferences.getInstance();
    return (
      lat: p.getDouble(_keyLat) ?? AppConfig.defaultLatitude,
      lng: p.getDouble(_keyLng) ?? AppConfig.defaultLongitude,
      city: p.getString(_keyCity) ?? 'القاهرة',
    );
  }

  static Future<void> set({
    required double lat,
    required double lng,
    required String city,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_keyLat, lat);
    await p.setDouble(_keyLng, lng);
    await p.setString(_keyCity, city);
  }

  static Future<void> resetToDefault() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyLat);
    await p.remove(_keyLng);
    await p.remove(_keyCity);
  }

  /// Preset list of major Egyptian cities.
  static const presetCities = <(String, double, double)>[
    ('القاهرة', 30.0444, 31.2357),
    ('الإسكندرية', 31.2001, 29.9187),
    ('الجيزة', 30.0131, 31.2089),
    ('المنصورة', 31.0409, 31.3785),
    ('أسيوط', 27.1809, 31.1837),
    ('أسوان', 24.0889, 32.8998),
    ('طنطا', 30.7865, 31.0004),
    ('بورسعيد', 31.2653, 32.3019),
    ('السويس', 29.9668, 32.5498),
    ('الأقصر', 25.6872, 32.6396),
  ];
}