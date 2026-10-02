import 'package:flutter/foundation.dart';

import '../models/challenge.dart';
import '../services/challenge_service.dart';

class ChallengeProvider extends ChangeNotifier {
  List<Challenge> _challenges = [];
  final Map<String, List<ChallengeParticipant>> _participants = {};
  bool _loading = false;

  List<Challenge> get challenges => List.unmodifiable(_challenges);
  bool get loading => _loading;
  List<ChallengeParticipant> participantsOf(String id) =>
      _participants[id] ?? const [];

  Future<void> loadForGroup(String groupId) async {
    _loading = true;
    notifyListeners();
    try {
      _challenges = await ChallengeService.forGroup(groupId);
      for (final c in _challenges) {
        _participants[c.id] = await ChallengeService.participants(c.id);
      }
    } catch (e) {
      debugPrint('ChallengeProvider.loadForGroup: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create({
    required String groupId,
    required String userId,
    required String title,
    required String type,
    required int targetDays,
  }) async {
    final c = await ChallengeService.create(
      groupId: groupId,
      userId: userId,
      title: title,
      type: type,
      targetDays: targetDays,
    );
    _challenges = [..._challenges, c];
    await ChallengeService.join(challengeId: c.id, userId: userId);
    await loadForGroup(groupId);
  }

  Future<void> join({
    required String challengeId,
    required String userId,
    required String groupId,
  }) async {
    await ChallengeService.join(challengeId: challengeId, userId: userId);
    await loadForGroup(groupId);
  }
}