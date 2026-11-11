import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/prayer_log.dart';
import '../repositories/prayer_repository.dart';
import '../services/prayer_engine.dart';

class PrayerRecordResult {
  final bool success;
  final int hasanat;
  final String? error;
  final PrayerLog? log;

  const PrayerRecordResult({
    required this.success,
    this.hasanat = 0,
    this.error,
    this.log,
  });
}

class PrayerProvider extends ChangeNotifier {
  late final PrayerRepository _repo;
  StreamSubscription? _sub;

  final Map<PrayerName, PrayerLog> _today = {};
  DateTime _todayDate = DateTime.now();
  bool _loading = false;
  String? _error;

  // history of missed + qada prayers (background-loaded)
  List<PrayerLog> _missedHistory = [];
  bool _missedLoading = false;

  PrayerProvider() {
    _repo = PrayerRepository(Supabase.instance.client);
  }

  Map<PrayerName, PrayerLog> get todayLogs => Map.unmodifiable(_today);
  bool get loading => _loading;
  String? get error => _error;
  DateTime get todayDate => _todayDate;

  List<PrayerLog> get missedHistory => List.unmodifiable(_missedHistory);
  bool get missedLoading => _missedLoading;

  PrayerTimeline timelineFor(PrayerName prayer) =>
      PrayerEngine.computeTimeline(prayer: prayer, date: _todayDate);

  PrayerPhase phaseFor(PrayerName prayer) {
    final t = timelineFor(prayer);
    return t.phaseAt(DateTime.now());
  }

  // ============================================
  // LOAD
  // ============================================

  Future<void> loadToday(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Sweep missed prayers from previous days (server-side)
      await _repo.sweepMissedPrayers(userId: userId);

      // 2. Load today's logs
      _todayDate = DateTime.now();
      final logs = await _repo.getLogsForDate(
        userId: userId,
        date: _todayDate,
      );

      _today.clear();
      for (final p in PrayerName.values) {
        _today[p] = PrayerLog.empty(
          userId: userId,
          date: _todayDate,
          prayer: p,
        );
      }
      for (final log in logs) {
        _today[log.prayer] = log;
      }

      _subscribe(userId);

      // 3. Load missed/qada history in the background
      unawaited(loadMissedHistory(userId));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// تحميل الصلوات الفائتة/القضاء من التاريخ.
  Future<void> loadMissedHistory(String userId) async {
    _missedLoading = true;
    notifyListeners();
    try {
      _missedHistory = await _repo.getMissedAndQadaHistory(userId: userId);
    } catch (e) {
      debugPrint('PrayerProvider.loadMissedHistory: $e');
    } finally {
      _missedLoading = false;
      notifyListeners();
    }
  }

  void _subscribe(String userId) {
    _sub?.cancel();
    _sub = _repo
        .streamLogsForDate(userId: userId, date: _todayDate)
        .listen((logs) {
      for (final log in logs) {
        _today[log.prayer] = log;
      }
      notifyListeners();
    });
  }

  // ============================================
  // RECORD via RPC (server computes bonus)
  // ============================================

  Future<PrayerRecordResult> recordPrayer({
    required String userId,
    required PrayerName prayer,
    required PrayerStatus status,
  }) async {
    // Fast client-side feedback (server re-validates).
    final timeline = timelineFor(prayer);
    final now = DateTime.now();
    final clientError = PrayerEngine.validateStatus(
      prayer: prayer,
      status: status,
      now: now,
      date: _todayDate,
    );
    if (clientError != null) {
      return PrayerRecordResult(success: false, error: clientError);
    }

    try {
      // Server-authoritative write.
      final rpc = await _repo.recordPrayerRpc(
        userId: userId,
        prayer: prayer,
        status: status,
        logicalDate: _todayDate,
        timeline: timeline,
      );

      final newLog = PrayerLog(
        id: rpc['id'] as String,
        userId: userId,
        date: _todayDate,
        prayer: prayer,
        status: status,
        hasanat: (rpc['hasanat'] as num).toInt(),
        recordedAt: DateTime.parse(rpc['recorded_at'] as String).toLocal(),
      );

      _today[prayer] = newLog;
      notifyListeners();

      return PrayerRecordResult(
        success: true,
        hasanat: newLog.hasanat,
        log: newLog,
      );
    } on PostgrestException catch (e) {
      // Server rejected (phase mismatch, unauthorized, etc.)
      return PrayerRecordResult(success: false, error: e.message);
    } catch (e) {
      return PrayerRecordResult(success: false, error: e.toString());
    }
  }

  // ============================================
  // TAWBAH (via RPC)
  // ============================================

  Future<PrayerRecordResult> markRepented({
    required String userId,
    required PrayerName prayer,
    DateTime? date,
  }) async {
    final targetDate = date ?? _todayDate;
    final current = _today[prayer];
    if (current == null && date == null) {
      return const PrayerRecordResult(
          success: false, error: 'لا يوجد سجل للصلاة');
    }
    if (current != null && !current.hasUnrepentedSayyiat && date == null) {
      return const PrayerRecordResult(
          success: false, error: 'لا توجد سيئات للتوبة');
    }

    try {
      final res = await _repo.markRepentedRpc(
        userId: userId,
        prayer: prayer,
        date: targetDate,
      );
      if (res['success'] != true) {
        return PrayerRecordResult(
          success: false,
          error: res['message'] as String? ?? 'فشلت التوبة',
        );
      }
      if (date == null) {
        _today[prayer] = current!.copyWith(
          sayyiatRepented: true,
          repentedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return const PrayerRecordResult(success: true);
    } catch (e) {
      return PrayerRecordResult(success: false, error: e.toString());
    }
  }

  // ============================================
  // QADA for OLD missed prayers (via RPC)
  // ============================================

  Future<PrayerRecordResult> recordQadaForDate({
    required String userId,
    required PrayerName prayer,
    required DateTime date,
  }) async {
    try {
      await _repo.recordHistoricalQadaRpc(
        userId: userId,
        prayer: prayer,
        date: date,
      );
      await loadMissedHistory(userId);
      return const PrayerRecordResult(success: true);
    } on PostgrestException catch (e) {
      return PrayerRecordResult(success: false, error: e.message);
    } catch (e) {
      return PrayerRecordResult(success: false, error: e.toString());
    }
  }

  // ============================================
  // AGGREGATES
  // ============================================

  int get todayHasanat =>
      _today.values.fold(0, (sum, log) => sum + log.hasanat);

  int get todayCompletedCount =>
      _today.values.where((l) => l.isRecorded && !l.isMissed).length;

  double get todayImanGain =>
      _today.values.fold(0.0, (sum, log) => sum + log.netImanEffect);

  PrayerName? get currentFocusPrayer {
    for (final p in PrayerName.values) {
      final phase = phaseFor(p);
      if (phase == PrayerPhase.congregationOpen ||
          phase == PrayerPhase.individualOpen) {
        final log = _today[p];
        if (log == null || !log.isRecorded) return p;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}