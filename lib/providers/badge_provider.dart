import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/badge.dart';
import '../repositories/badge_repository.dart';

class BadgeProvider extends ChangeNotifier {
  late final BadgeRepository _repo;

  List<Badge> _allBadges = [];
  final Set<String> _unlockedIds = {};
  Badge? _justUnlocked;

  BadgeProvider() {
    _repo = BadgeRepository(Supabase.instance.client);
  }

  List<Badge> get allBadges => List.unmodifiable(_allBadges);
  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);
  Badge? get justUnlocked => _justUnlocked;

  bool isUnlocked(String badgeId) => _unlockedIds.contains(badgeId);

  int get unlockedCount => _unlockedIds.length;
  int get totalCount => _allBadges.length;
  double get completionPercent =>
      totalCount == 0 ? 0 : unlockedCount / totalCount;

  List<Badge> byCategory(BadgeCategory category) =>
      _allBadges.where((b) => b.category == category).toList();

  // --- Loading ------------------------------------------------------------

  Future<void> loadForUser(String userId) async {
    try {
      final results = await Future.wait([
        _repo.getAllBadges(),
        _repo.getUserBadges(userId),
      ]);

      _allBadges = results[0] as List<Badge>;
      final userBadges = results[1] as List<UserBadge>;

      _unlockedIds
        ..clear()
        ..addAll(userBadges.map((b) => b.badgeId));

      notifyListeners();
    } catch (e) {
      debugPrint('BadgeProvider.loadForUser: $e');
    }
  }

  // --- Unlock check -------------------------------------------------------

  /// Evaluates all badge conditions against [context].
  /// Returns the list of badges unlocked by this call.
  Future<List<Badge>> checkConditions({
    required String userId,
    required BadgeContext context,
  }) async {
    final unlocked = <Badge>[];

    for (final badge in _allBadges) {
      if (_unlockedIds.contains(badge.id)) continue;

      final current = context.valueFor(badge.condition);
      final target = badge.targetValue ?? 1;

      if (current >= target) {
        await _repo.unlockBadge(userId: userId, badgeId: badge.id);
        _unlockedIds.add(badge.id);
        unlocked.add(badge);
      }
    }

    if (unlocked.isNotEmpty) {
      _justUnlocked = unlocked.first;
      notifyListeners();
    }

    return unlocked;
  }

  void clearJustUnlocked() {
    _justUnlocked = null;
    notifyListeners();
  }
}