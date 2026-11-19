import 'dart:convert';
import 'package:sohba/data/local/local_prefs.dart';
import 'package:sohba/models/prayer_log.dart';

/// Key format: `pl/{yyyy-mm-dd}/{prayer_name}`
class LocalPrayerStore {
  LocalPrayerStore._();
  static final LocalPrayerStore instance = LocalPrayerStore._();
  final _prefs = LocalPrefs.instance;

  String _key(DateTime d, PrayerName p) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return 'pl/$y-$m-$dd/${p.name}';
  }

  Future<void> save(PrayerLog log) async =>
      _prefs.setJson(_key(log.date, log.prayer), log.toJson());

  Future<void> saveAll(List<PrayerLog> logs) async {
    for (final l in logs) { await save(l); }
  }

  Future<PrayerLog?> get(DateTime d, PrayerName p) async {
    final j = await _prefs.getJson(_key(d, p));
    return j == null ? null : PrayerLog.fromJson(j);
  }

  Future<List<PrayerLog>> forDate(DateTime d) async {
    final out = <PrayerLog>[];
    for (final p in PrayerName.values) {
      final l = await get(d, p);
      if (l != null) out.add(l);
    }
    return out;
  }

  Future<List<PrayerLog>> all() async {
    final prefs = await _prefs.prefs;
    final keys = prefs.getKeys().where((k) => k.startsWith('pl/'));
    final out = <PrayerLog>[];
    for (final k in keys) {
      final raw = prefs.getString(k);
      if (raw == null) continue;
      try {
        out.add(PrayerLog.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    return out;
  }
}