import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> loadFromServer(String userId) async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      _state = LockService.readFrom(profile);
      notifyListeners();
    } catch (e) {
      debugPrint('LockProvider.loadFromServer: $e');
    }
  }

  Future<void> unlock(String userId) async {
    await LockService.unlock(userId);
    _state = const LockState();
    notifyListeners();
  }

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