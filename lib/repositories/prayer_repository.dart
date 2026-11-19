import 'package:sohba/data/local/local_prayer_store.dart';
import 'package:sohba/data/sync/sync_queue.dart';
import 'package:sohba/data/sync/sync_service.dart';
import 'package:sohba/models/prayer_log.dart';

class PrayerRepository {
  final _local = LocalPrayerStore.instance;
  final _queue = SyncQueue.instance;

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
}