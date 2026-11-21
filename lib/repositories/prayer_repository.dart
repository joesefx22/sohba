import 'package:sohba/data/local/local_prayer_store.dart';
import 'package:sohba/data/sync/sync_queue.dart';
import 'package:sohba/data/sync/sync_service.dart';
import 'package:sohba/models/prayer_log.dart';

class PrayerRepository {
  final _local = LocalPrayerStore.instance;
  final _queue = SyncQueue.instance;

  // ignore: avoid_unused_constructor_parameters
  PrayerRepository([dynamic _]);

  Future<List<PrayerLog>> fetchForDate(DateTime date) => _local.forDate(date);

  Future<PrayerLog?> get(DateTime date, PrayerName prayer) =>
      _local.get(date, prayer);

  Future<void> save(PrayerLog log) async {
    await _local.save(log);
    await _queue.enqueue(SyncItem(
      id: 'prayer_logs_${log.id}_${DateTime.now().microsecondsSinceEpoch}',
      table: 'prayer_logs',
      op: SyncOp.upsert,
      payload: log.toJson(),
      createdAt: DateTime.now(),
    ));
    SyncService.instance.kick();
  }

  Future<List<PrayerLog>> getLogsInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final all = await _local.all();
    final f = _dateOnly(from);
    final t = _dateOnly(to);
    return all.where((l) {
      if (l.userId != userId) return false;
      final d = _dateOnly(l.date);
      return !d.isBefore(f) && !d.isAfter(t);
    }).toList();
  }

  /// ✅ يرجع عدد الصلوات اللي اتحوّلت (int) — يستخدمه scheduler_service.
  Future<int> sweepMissedPrayers({
    required String userId,
    DateTime? day,
  }) async {
    final targetDay =
        day ?? DateTime.now().subtract(const Duration(days: 1));
    final dayOnly = _dateOnly(targetDay);

    final existing = await _local.forDate(dayOnly);
    final logged = {for (final l in existing) l.prayer: l.status};

    int swept = 0;
    for (final p in PrayerName.values) {
      final s = logged[p];
      if (s == PrayerStatus.congregation ||
          s == PrayerStatus.individual ||
          s == PrayerStatus.missed) {
        continue;
      }
      await save(PrayerLog(
        id: PrayerLog.makeId(userId, dayOnly, p),
        userId: userId,
        date: dayOnly,
        prayer: p,
        status: PrayerStatus.missed,
        sayyiat: 200,
      ));
      swept++;
    }
    return swept;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}