import 'package:flutter/foundation.dart';

import '../models/lock_state.dart';
import '../services/lock_service.dart';

class LockProvider extends ChangeNotifier {
  LockState _state = const LockState();

  LockState get state => _state;
  bool get isLocked => _state.isLocked;

  void syncFromProfile(Map<String, dynamic>? profile) {
    _state = LockService.readFrom(profile);
    notifyListeners();
  }

  Future<void> unlock(String userId) async {
    await LockService.unlock(userId);
    _state = const LockState();
    notifyListeners();
  }

  /// Called when a prayer is recorded outside its windows.
  Future<void> handleMissed({
    required String userId,
    required String prayer,
    required DateTime date,
  }) async {
    await LockService.lockForMissedPrayer(
      userId: userId,
      prayer: prayer,
      date: date,
    );
    _state = LockState(
      isLocked: true,
      lockedAt: DateTime.now(),
      reason: 'missed_prayer',
      prayer: prayer,
    );
    notifyListeners();
  }
}