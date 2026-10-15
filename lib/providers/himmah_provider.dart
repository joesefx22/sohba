import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/himmah_transaction.dart';
import '../services/himmah_service.dart';

class HimmahProvider extends ChangeNotifier {
  int _balance = 0;
  List<HimmahTransaction> _transactions = [];
  bool _loading = false;
  String? _error;

  int get balance => _balance;
  List<HimmahTransaction> get transactions => List.unmodifiable(_transactions);
  bool get loading => _loading;
  String? get error => _error;

  /// Total credit earned all-time (sum of positive amounts).
  int get totalEarned =>
      _transactions.where((t) => t.isCredit).fold(0, (s, t) => s + t.amount);

  /// Total spent all-time (absolute value of negative amounts).
  int get totalSpent => _transactions
      .where((t) => t.isDebit)
      .fold(0, (s, t) => s + t.amount.abs());

  // ============================================
  // LOAD
  // ============================================

  Future<void> loadForUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        HimmahService.currentBalance(userId),
        Supabase.instance.client
            .from('himmah_transactions')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(100),
      ]);

      _balance = results[0] as int;
      _transactions = (results[1] as List)
          .map((e) =>
              HimmahTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('HimmahProvider.loadForUser: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresh only the balance (cheap — used after earning/spending).
  Future<void> refreshBalance(String userId) async {
    try {
      _balance = await HimmahService.currentBalance(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('HimmahProvider.refreshBalance: $e');
    }
  }

  // ============================================
  // SPEND (guarded)
  // ============================================

  /// Attempt to spend [amount] himmah.
  ///
  /// Returns true if successful, false if insufficient balance or error.
  /// Reloads balance + transactions on success.
  Future<bool> spend({
    required String userId,
    required int amount,
    required String reason,
    String? referenceId,
  }) async {
    if (_balance < amount) {
      _error = 'رصيد الهمّة غير كافٍ';
      notifyListeners();
      return false;
    }

    _error = null;
    try {
      await HimmahService.spend(
        userId: userId,
        amount: amount,
        reason: reason,
        referenceId: referenceId,
      );
      await loadForUser(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('HimmahProvider.spend: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset when user signs out.
  void clear() {
    _balance = 0;
    _transactions = [];
    _error = null;
    notifyListeners();
  }
}