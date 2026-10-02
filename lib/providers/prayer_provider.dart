import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/prayer_log.dart';
import '../repositories/prayer_repository.dart';
import '../services/prayer_engine.dart';

/// Result of recording a prayer — the caller uses it to trigger animations.
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

  /// --- Timelines ---------------------------------------------------------

  PrayerTimeline timelineFor(PrayerName prayer) =>
      PrayerEngine.computeTimeline(prayer: prayer, date: _todayDate);

  PrayerPhase phaseFor(PrayerName prayer) {
    final t = timelineFor(prayer);
    return t.phaseAt(DateTime.now());
  }

  // --- Loading ------------------------------------------------------------

  Future<void> loadToday(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _todayDate = DateTime.now();
      final logs = await _repo.getLogsForDate(
        userId: userId,
        date: _todayDate,
      );

      _today.clear();
      // Fill with empty logs, then override with saved ones
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

  // --- Recording ----------------------------------------------------------

  /// Record a prayer. Returns a result the UI uses to trigger animations.
  Future<PrayerRecordResult> recordPrayer({
    required String userId,
    required PrayerName prayer,
    required PrayerStatus status,
  }) async {
    final now = DateTime.now();

    // Validate via engine
    final error = PrayerEngine.validateStatus(
      prayer: prayer,
      status: status,
      now: now,
      date: _todayDate,
    );
    if (error != null) {
      return PrayerRecordResult(success: false, error: error);
    }

    // Compute hasanat
    final hasanat = PrayerEngine.hasanatFor(
      prayer: prayer,
      status: status,
      now: now,
      date: _todayDate,
    );

    final newLog = (_today[prayer] ?? PrayerLog.empty(
      userId: userId,
      date: _todayDate,
      prayer: prayer,
    ))
        .copyWith(
      status: status,
      hasanat: hasanat,
      recordedAt: now,
      sayyiat: 0,
      sayyiatRepented: false,
    );

    try {
      await _repo.upsertLog(newLog);
      _today[prayer] = newLog;
      notifyListeners();

      return PrayerRecordResult(
        success: true,
        hasanat: hasanat,
        log: newLog,
      );
    } catch (e) {
      return PrayerRecordResult(success: false, error: e.toString());
    }
  }

  /// Mark a missed prayer as repented.
  Future<PrayerRecordResult> markRepented({
    required String userId,
    required PrayerName prayer,
  }) async {
    final current = _today[prayer];
    if (current == null) {
      return const PrayerRecordResult(
        success: false,
        error: 'لا يوجد سجل للصلاة',
      );
    }
    if (!current.hasUnrepentedSayyiat) {
      return const PrayerRecordResult(
        success: false,
        error: 'لا توجد سيئات للتوبة',
      );
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

  // --- Stats helpers ------------------------------------------------------

  int get todayHasanat =>
      _today.values.fold(0, (sum, log) => sum + log.hasanat);

  int get todayCompletedCount =>
      _today.values.where((l) => l.isRecorded && !l.isMissed).length;

  double get todayImanGain =>
      _today.values.fold(0.0, (sum, log) => sum + log.netImanEffect);

  /// The prayer the user should act on right now.
  PrayerName? get currentFocusPrayer {
    final now = DateTime.now();
    for (final p in PrayerName.values) {
      final phase = phaseFor(p);
      if (phase == PrayerPhase.congregationOpen ||
          phase == PrayerPhase.individualOpen) {
        if (!_today[p]!.isRecorded) return p;
      }
    }
    // Fall back to next upcoming
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}