import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ledger_entry.dart';
import '../repositories/ledger_repository.dart';

class LedgerProvider extends ChangeNotifier {
  late final LedgerRepository _repo;
  List<LedgerEntry> _entries = [];
  Map<String, dynamic>? _summary;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 100;

  LedgerProvider() {
    _repo = LedgerRepository(Supabase.instance.client);
  }

  List<LedgerEntry> get entries => List.unmodifiable(_entries);
  Map<String, dynamic>? get summary => _summary;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;

  Future<void> loadForUser(String userId) async {
    _loading = true;
    _hasMore = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getEntries(userId: userId, limit: _pageSize, offset: 0),
        _repo.getSummary(userId),
      ]);
      _entries = results[0] as List<LedgerEntry>;
      _summary = results[1] as Map<String, dynamic>;
      _hasMore = _entries.length >= _pageSize;
    } catch (e) {
      debugPrint('LedgerProvider.loadForUser: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore(String userId) async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final more = await _repo.getEntries(
        userId: userId,
        limit: _pageSize,
        offset: _entries.length,
      );
      _entries = [..._entries, ...more];
      _hasMore = more.length >= _pageSize;
    } catch (e) {
      debugPrint('LedgerProvider.loadMore: $e');
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void clear() {
    _entries = [];
    _summary = null;
    _hasMore = true;
    notifyListeners();
  }
}