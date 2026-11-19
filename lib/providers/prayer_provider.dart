import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sohba/data/local/local_prefs.dart';
import 'package:sohba/models/prayer_log.dart';
import 'package:sohba/repositories/prayer_repository.dart';
import 'package:sohba/services/prayer_engine.dart';

class PrayerProvider extends ChangeNotifier {
  final _repo = PrayerRepository();
  final _prefs = LocalPrefs.instance;

  DateTime _selectedDate = DateTime.now();
  Map<PrayerName, PrayerStatus> _statuses = {};
  bool _loading = false;
  Timer? _refreshTimer;

  DateTime get selectedDate => _selectedDate;
  Map<PrayerName, PrayerStatus> get statuses => _statuses;
  bool get loading => _loading;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    await _sweepMissed();
    final day = PrayerEngine.currentPrayerDay(DateTime.now());
    _selectedDate = day;

    final logs = await _repo.fetchForDate(day);
    final logged = {for (final l in logs) l.prayer: l.status};

    _statuses = PrayerEngine.computeStatuses(
      date: day, logged: logged, now: DateTime.now(),
    );

    _loading = false;
    notifyListeners();
    _startAutoRefresh();
  }

  Future<bool> record(PrayerName prayer, {required bool congregation}) async {
    final userId = _userId;
    if (userId == null) return false;

    final now = DateTime.now();
    if (now.isAfter(PrayerEngine.deadlineForDay(_selectedDate))) {
      await load();
      return false;
    }

    if (_statuses[prayer] != PrayerStatus.pending) return false;

    final newStatus = congregation
        ? PrayerStatus.congregation
        : PrayerStatus.individual;

    final (hasanat, sayyiat) = PrayerEngine.rewardsFor(newStatus);
    final log = PrayerLog(
      id: PrayerLog.makeId(userId, _selectedDate, prayer),
      userId: userId, date: _selectedDate, prayer: prayer,
      status: newStatus, hasanat: hasanat, sayyiat: sayyiat,
      recordedAt: now,
    );

    await _repo.save(log);
    _statuses = {..._statuses, prayer: newStatus};
    notifyListeners();
    return true;
  }

  Future<void> _sweepMissed() async {
    final userId = _userId;
    if (userId == null) return;

    final now = DateTime.now();
    final currentDay = PrayerEngine.currentPrayerDay(now);
    final lastSweepStr = await _prefs.getString('last_sweep_date');
    final lastSweep = lastSweepStr != null
        ? DateTime.parse(lastSweepStr)
        : currentDay;

    var d = lastSweep;
    while (d.isBefore(currentDay)) {
      final logs = await _repo.fetchForDate(d);
      final logged = {for (final l in logs) l.prayer: l.status};

      for (final prayer in PrayerName.values) {
        final s = logged[prayer];
        if (s == PrayerStatus.congregation ||
            s == PrayerStatus.individual ||
            s == PrayerStatus.missed) continue;

        await _repo.save(PrayerLog(
          id: PrayerLog.makeId(userId, d, prayer),
          userId: userId, date: d, prayer: prayer,
          status: PrayerStatus.missed, sayyiat: 200,
        ));
      }
      d = d.add(const Duration(days: 1));
    }
    await _prefs.setString('last_sweep_date', currentDay.toIso8601String());
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final day = PrayerEngine.currentPrayerDay(DateTime.now());
      if (day != _selectedDate) {
        await load();
      } else {
        final logs = await _repo.fetchForDate(day);
        final logged = {for (final l in logs) l.prayer: l.status};
        _statuses = PrayerEngine.computeStatuses(
          date: day, logged: logged, now: DateTime.now(),
        );
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}