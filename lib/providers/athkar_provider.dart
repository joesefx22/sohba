import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/athkar.dart';
import '../repositories/athkar_repository.dart';
import '../services/athkar_service.dart';

/// UI state of the athkar loading lifecycle.
enum AthkarState { loading, ready, error, empty }

class AthkarProvider extends ChangeNotifier {
  late final AthkarRepository _repo;

  List<AthkarCategory> _categories = [];
  final Map<String, UserAthkarProgress> _progress = {};
  Map<String, int> _unlockLevels = {};
  bool _loading = false;
  String? _error;
  DateTime _todayDate = DateTime.now();

  AthkarProvider() {
    _repo = AthkarRepository(Supabase.instance.client);
  }

  // ============================================
  // STATE (for UI switch)
  // ============================================

  AthkarState get state {
    if (_loading) return AthkarState.loading;
    if (_error != null) return AthkarState.error;
    if (_categories.isEmpty) return AthkarState.empty;
    return AthkarState.ready;
  }

  String? get errorMessage => _error;

  Future<void> retry(String userId) async {
    _error = null;
    await loadAll(userId);
  }

  // ============================================
  // GETTERS
  // ============================================

  List<AthkarCategory> get categories => List.unmodifiable(_categories);
  bool get loading => _loading;
  DateTime get todayDate => _todayDate;

  List<AthkarCategory> get mandatoryCategories =>
      _categories.where((c) => c.isMandatory).toList();

  List<AthkarItem> get allMandatoryItems =>
      mandatoryCategories.expand((c) => c.items).toList();

  Map<String, bool> progressMapFor(List<AthkarItem> items) {
    final m = <String, bool>{};
    for (final item in items) {
      m[item.id] = _progress[item.id]?.completed == true;
    }
    return m;
  }

  // ============================================
  // PROGRESSIVE UNLOCK
  // ============================================

  int levelFor(String categoryId) => _unlockLevels[categoryId] ?? 5;

  bool isCategoryFullyUnlocked(String categoryId) {
    return true; // TODO: implement full-unlock logic
  }

  List<AthkarItem> visibleItemsFor(AthkarCategory cat) {
    if (!cat.isMandatory) return cat.items;
    final level = levelFor(cat.id);
    return cat.items.take(level).toList();
  }

  // ============================================
  // LOAD
  // ============================================

  Future<void> loadAll(String userId) async {
    _loading = true;
    _error = null;
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

      // Load progressive unlock state (non-fatal if RPC missing)
      try {
        final unlockState = await Supabase.instance.client.rpc(
          'get_athkar_unlock_state',
          params: {'p_user_id': userId},
        );
        _unlockLevels = {};
        for (final row in (unlockState as List)) {
          final r = row as Map<String, dynamic>;
          _unlockLevels[r['category_id'] as String] =
              (r['current_level'] as int?) ?? 5;
        }
      } catch (e) {
        debugPrint('AthkarProvider: unlock state load failed ($e)');
      }
    } catch (e) {
      _error = e.toString();
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