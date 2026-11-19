import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/title.dart';
import '../repositories/title_repository.dart';

class TitleProvider extends ChangeNotifier {
  late final TitleRepository _repo;

  List<Title> _all = [];
  final Set<String> _unlocked = {};
  String? _activeTitleId;
  bool _loading = false;

  TitleProvider() {
    _repo = TitleRepository(Supabase.instance.client);
  }

  List<Title> get all => List.unmodifiable(_all);
  Set<String> get unlockedIds => Set.unmodifiable(_unlocked);
  bool get loading => _loading;
  String? get activeTitleId => _activeTitleId;

  Title? get activeTitle {
    if (_activeTitleId == null) return null;
    for (final t in _all) {
      if (t.id == _activeTitleId) return t;
    }
    return null;
  }

  List<Title> get unlockedTitles =>
      _all.where((t) => _unlocked.contains(t.id)).toList();

  List<Title> get lockedTitles =>
      _all.where((t) => !_unlocked.contains(t.id)).toList();

  Future<void> loadForUser(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getAllTitles(),
        _repo.getUserTitles(userId),
      ]);
      _all = results[0] as List<Title>;
      final userTitles = results[1] as List<UserTitle>;
      _unlocked
        ..clear()
        ..addAll(userTitles.map((u) => u.titleId));
      _activeTitleId = userTitles
          .where((u) => u.isActive)
          .map((u) => u.titleId)
          .firstOrNull;
    } catch (e) {
      debugPrint('TitleProvider.loadForUser: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Unlock any titles whose source badge is already unlocked.
  Future<List<Title>> syncFromBadges(
    String userId,
    Set<String> unlockedBadgeIds,
  ) async {
    final newlyUnlocked = <Title>[];
    for (final title in _all) {
      if (_unlocked.contains(title.id)) continue;
      final badgeId = title.sourceBadgeId;
      if (badgeId == null) continue;
      if (!unlockedBadgeIds.contains(badgeId)) continue;

      try {
        await _repo.unlockTitle(userId: userId, titleId: title.id);
        _unlocked.add(title.id);
        newlyUnlocked.add(title);
      } catch (e) {
        debugPrint('TitleProvider.syncFromBadges(${title.id}): $e');
      }
    }
    if (newlyUnlocked.isNotEmpty) notifyListeners();
    return newlyUnlocked;
  }

  Future<bool> setActive(String userId, String titleId) async {
    if (!_unlocked.contains(titleId)) return false;
    try {
      await _repo.setActiveTitle(userId: userId, titleId: titleId);
      _activeTitleId = titleId;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('TitleProvider.setActive: $e');
      return false;
    }
  }

  void clear() {
    _all = [];
    _unlocked.clear();
    _activeTitleId = null;
    notifyListeners();
  }
}