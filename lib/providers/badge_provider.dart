import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/athkar.dart';
import '../models/badge.dart';
import '../models/prayer_log.dart';
import '../repositories/badge_repository.dart';
import '../services/badge_engine.dart';
import '../services/compound_badge_engine.dart';

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

  // ============================================
  // LOAD
  // ============================================

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

  // ============================================
  // EVALUATE — simple + compound
  // ============================================

  Future<List<Badge>> evaluateAndUnlock({
    required String userId,
    required List<PrayerLog> recentLogs,
    required List<AthkarItem> athkarItemsToday,
    required Map<String, bool> athkarCompletedToday,
  }) async {
    final unlocked = <Badge>[];

    // 1. Simple conditions (streaks, totals)
    final ctx = BadgeEngine.compute(
      prayerLogs: recentLogs,
      athkarItemsToday: athkarItemsToday,
      athkarProgressToday: athkarCompletedToday,
    );
    unlocked.addAll(await checkConditions(userId: userId, context: ctx));

    // 2. Compound conditions (all_of, min_sunnah_rakat, ...)
    unlocked.addAll(await _evaluateCompound(
      userId: userId,
      recentLogs: recentLogs,
    ));

    if (unlocked.isNotEmpty) {
      _justUnlocked = unlocked.first;
      notifyListeners();
    }

    return unlocked;
  }

  Future<List<Badge>> checkConditions({
    required String userId,
    required BadgeContext context,
  }) async {
    final unlocked = <Badge>[];

    for (final badge in _allBadges) {
      if (_unlockedIds.contains(badge.id)) continue;
      if (badge.isCompound) continue; // handled by _evaluateCompound

      final current = context.valueFor(badge.condition);
      final target = badge.targetValue ?? 1;

      if (current >= target) {
        await _repo.unlockBadge(userId: userId, badgeId: badge.id);
        _unlockedIds.add(badge.id);
        unlocked.add(badge);
      }
    }

    return unlocked;
  }

  Future<List<Badge>> _evaluateCompound({
    required String userId,
    required List<PrayerLog> recentLogs,
  }) async {
    final unlocked = <Badge>[];

    for (final badge in _allBadges) {
      if (_unlockedIds.contains(badge.id)) continue;
      if (!badge.isCompound) continue;

      final ok = CompoundBadgeEngine.evaluate(
        requirements: badge.requirements!,
        recentLogs: recentLogs,
      );

      if (ok) {
        await _repo.unlockBadge(userId: userId, badgeId: badge.id);
        _unlockedIds.add(badge.id);
        unlocked.add(badge);
      }
    }

    return unlocked;
  }

  void clearJustUnlocked() {
    _justUnlocked = null;
    notifyListeners();
  }
}