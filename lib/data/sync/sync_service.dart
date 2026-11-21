import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sohba/data/sync/sync_queue.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _queue = SyncQueue.instance;
  final _client = Supabase.instance.client;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _retryTimer;
  bool _busy = false;
  int _backoffSeconds = 30;

  void start() {
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection =
          results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) _flush();
    });
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) => _flush());
    _flush();
  }

  void stop() {
    _connSub?.cancel();
    _retryTimer?.cancel();
  }

  void kick() => _flush();

  Future<void> _flush() async {
    if (_busy) return;
    _busy = true;
    try {
      final pending = await _queue.peek(limit: 50);
      if (pending.isEmpty) {
        _backoffSeconds = 30;
        return;
      }
      for (final item in pending) {
        try {
          switch (item.op) {
            case SyncOp.upsert:
              await _client.from(item.table).upsert(item.payload);
              break;
            case SyncOp.delete:
              await _client
                  .from(item.table)
                  .delete()
                  .eq('id', item.payload['id']);
              break;
          }
          await _queue.markDone(item.id);
          _backoffSeconds = 30;
        } catch (e) {
          debugPrint('SyncService fail ${item.id}: $e');
          await _queue.markFailed(item.id, e.toString());
          break;
        }
      }
    } finally {
      _busy = false;
      _retryTimer?.cancel();
      final delay = _backoffSeconds.clamp(30, 300);
      _retryTimer = Timer(Duration(seconds: delay), _flush);
      _backoffSeconds = (delay * 2).clamp(30, 300);
    }
  }
}