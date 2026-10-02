import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/athkar.dart';
import '../repositories/athkar_repository.dart';
import '../services/athkar_service.dart';

class AthkarProvider extends ChangeNotifier {
  late final AthkarRepository _repo;

  List<AthkarCategory> _categories = [];
  final Map<String, UserAthkarProgress> _progress = {};
  bool _loading = false;
  DateTime _todayDate = DateTime.now();

  AthkarProvider() {
    _repo = AthkarRepository(Supabase.instance.client);
  }

  List<AthkarCategory> get categories => List.unmodifiable(_categories);
  bool get loading => _loading;
  DateTime get todayDate => _todayDate;

  List<AthkarCategory> get mandatoryCategories =>
      _categories.where((c) => c.isMandatory).toList();

  /// All items across mandatory categories (used by BadgeEngine).
  List<AthkarItem> get allMandatoryItems =>
      mandatoryCategories.expand((c) => c.items).toList();

  /// Map itemId → completed for the given list.
  Map<String, bool> progressMapFor(List<AthkarItem> items) {
    final m = <String, bool>{};
    for (final item in items) {
      m[item.id] = _progress[item.id]?.completed == true;
    }
    return m;
  }

  Future<void> loadAll(String userId) async {
    _loading = true;
    notifyListeners();

    try {
      _todayDate = DateTime.now();
      _categories = await AthkarService.loadAll();

      final progress = await _repo.getProgress(
        userId: userId,
        date: _todayDate,
      );
      _progress.clear();
      for (final p in progress) {
        _progress[p.athkarItemId] = p;
      }
    } catch (e) {
      debugPrint('AthkarProvider.loadAll: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  UserAthkarProgress? progressFor(String itemId) => _progress[itemId];

  int completedCountIn(AthkarCategory category) {
    return category.items
        .where((i) => _progress[i.id]?.completed == true)
        .length;
  }

  double completionFor(AthkarCategory category) {
    if (category.items.isEmpty) return 0;
    return completedCountIn(category) / category.items.length;
  }

  Future<bool> incrementItem({
    required String userId,
    required AthkarItem item,
  }) async {
    final current = _progress[item.id];
    final newCount = (current?.count ?? 0) + 1;
    final completed = newCount >= item.repeatCount;

    try {
      await _repo.upsertProgress(
        userId: userId,
        athkarItemId: item.id,
        date: _todayDate,
        count: newCount,
        completed: completed,
      );

      _progress[item.id] = UserAthkarProgress(
        athkarItemId: item.id,
        date: _todayDate,
        count: newCount,
        completed: completed,
        completedAt: completed ? DateTime.now() : null,
      );

      notifyListeners();
      return completed && (current?.completed != true);
    } catch (e) {
      debugPrint('AthkarProvider.incrementItem: $e');
      return false;
    }
  }

  Future<void> completeItem({
    required String userId,
    required AthkarItem item,
  }) async {
    await _repo.upsertProgress(
      userId: userId,
      athkarItemId: item.id,
      date: _todayDate,
      count: item.repeatCount,
      completed: true,
    );
    _progress[item.id] = UserAthkarProgress(
      athkarItemId: item.id,
      date: _todayDate,
      count: item.repeatCount,
      completed: true,
      completedAt: DateTime.now(),
    );
    notifyListeners();
  }

  bool get allMandatoryCompleted {
    for (final cat in mandatoryCategories) {
      if (completionFor(cat) < 1.0) return false;
    }
    return true;
  }
}