import 'package:sohba/data/local/local_prefs.dart';

enum SyncOp { upsert, delete }

class SyncItem {
  final String id;
  final String table;
  final SyncOp op;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retries;

  SyncItem({
    required this.id,
    required this.table,
    required this.op,
    required this.payload,
    required this.createdAt,
    this.retries = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'table': table, 'op': op.name,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'retries': retries,
      };

  factory SyncItem.fromJson(Map<String, dynamic> j) => SyncItem(
        id: j['id'] as String,
        table: j['table'] as String,
        op: SyncOp.values.byName(j['op'] as String),
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        createdAt: DateTime.parse(j['created_at'] as String),
        retries: j['retries'] as int? ?? 0,
      );
}

class SyncQueue {
  SyncQueue._();
  static final SyncQueue instance = SyncQueue._();
  static const _k = 'sync_queue_v1';
  final _prefs = LocalPrefs.instance;

  Future<List<SyncItem>> _readAll() async =>
      (await _prefs.getJsonList(_k)).map(SyncItem.fromJson).toList();

  Future<void> _writeAll(List<SyncItem> items) async =>
      _prefs.setJsonList(_k, items.map((e) => e.toJson()).toList());

  Future<void> enqueue(SyncItem item) async {
    final all = await _readAll();
    all.removeWhere((e) =>
        e.table == item.table && e.payload['id'] == item.payload['id']);
    await _writeAll([...all, item]);
  }

  Future<List<SyncItem>> peek({int limit = 50}) async {
    final all = await _readAll()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return all.take(limit).toList();
  }

  Future<void> markDone(String id) async {
    final all = await _readAll()..removeWhere((e) => e.id == id);
    await _writeAll(all);
  }

  Future<void> markFailed(String id, String error) async {
    final all = await _readAll();
    for (final e in all) { if (e.id == id) e.retries++; }
    await _writeAll(all);
  }
}