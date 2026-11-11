import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/habit_streak.dart';
import '../repositories/habit_streak_repository.dart';

// ← يسمح لأي ملف يستورد الـ provider إنه يستخدم HabitStreak كمان
// (يزيل الحاجة لـ import منفصل لـ models/habit_streak.dart)
export '../models/habit_streak.dart';

class HabitStreakProvider extends ChangeNotifier {
  late final HabitStreakRepository _repo;
  Map<String, HabitStreak> _streaks = {};
  bool _loading = false;

  HabitStreakProvider() {
    _repo = HabitStreakRepository(Supabase.instance.client);
  }

  List<HabitStreak> get all => _streaks.values.toList()
    ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

  List<HabitStreak> get active =>
      all.where((s) => s.currentStreak > 0).toList();

  bool get loading => _loading;

  HabitStreak? byKey(String key) => _streaks[key];

  Future<void> loadForUser(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      await _repo.sweep(userId);
      final list = await _repo.getForUser(userId);
      _streaks = {for (final s in list) s.habitKey: s};
    } catch (e) {
      debugPrint('HabitStreakProvider.loadForUser: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> bump({
    required String userId,
    required String habitKey,
    DateTime? date,
  }) async {
    try {
      await _repo.bump(userId: userId, habitKey: habitKey, date: date);
      await loadForUser(userId);
    } catch (e) {
      debugPrint('HabitStreakProvider.bump: $e');
    }
  }

  void clear() {
    _streaks = {};
    notifyListeners();
  }
}