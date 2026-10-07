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

  PrayerProvider() {
    _repo = PrayerRepository(Supabase.instance.client);
  }

  Map<PrayerName, PrayerLog> get todayLogs => Map.unmodifiable(_today);
  bool get loading => _loading;
  String? get error => _error;
  DateTime get todayDate => _todayDate;

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
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
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
  // RECORD via RPC
  // ============================================

  Future<PrayerRecordResult> recordPrayer({
    required String userId,
    required PrayerName prayer,
    required PrayerStatus status,
    double bonusMultiplier = 1.0,
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
        bonusMultiplier: bonusMultiplier,
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
  // TAWBAH
  // ============================================

  Future<PrayerRecordResult> markRepented({
    required String userId,
    required PrayerName prayer,
  }) async {
    final current = _today[prayer];
    if (current == null) {
      return const PrayerRecordResult(
          success: false, error: 'لا يوجد سجل للصلاة');
    }
    if (!current.hasUnrepentedSayyiat) {
      return const PrayerRecordResult(
          success: false, error: 'لا توجد سيئات للتوبة');
    }

    try {
      await _repo.markRepented(
        userId: userId,
        date: _todayDate,
        prayer: prayer,
      );

      _today[prayer] = current.copyWith(
        sayyiatRepented: true,
        repentedAt: DateTime.now(),
      );
      notifyListeners();

      return PrayerRecordResult(success: true, log: _today[prayer]);
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