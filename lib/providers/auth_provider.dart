import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  late final AuthRepository _repo;
  AuthStatus _status = AuthStatus.unknown;
  Map<String, dynamic>? _profile;
  String? _error;

  AuthProvider() {
    _repo = AuthRepository(Supabase.instance.client);
  }

  AuthStatus get status => _status;
  User? get user => _repo.currentUser;
  Map<String, dynamic>? get profile => _profile;
  String? get error => _error;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  String get displayName => (_profile?['name'] as String?) ?? 'طالب';
  String? get currentGroupId => _profile?['current_group_id'] as String?;

  /// Called from main.dart — sets up listener + initial state.
  void init() {
    _repo.authStateChanges.listen((state) {
      if (state.session != null) {
        _status = AuthStatus.authenticated;
        _loadProfile();
      } else {
        _status = AuthStatus.unauthenticated;
        _profile = null;
        notifyListeners();
      }
    });

    if (_repo.isAuthenticated) {
      _status = AuthStatus.authenticated;
      _loadProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    final u = _repo.currentUser;
    if (u == null) return;
    try {
      _profile = await _repo.getProfile(u.id);
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider._loadProfile error: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _error = null;
    try {
      await _repo.signUp(email: email, password: password, name: name);
      await _loadProfile();
      return true;
    } on AuthException catch (e) {
      _error = _translateAuthError(e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _error = null;
    try {
      await _repo.signIn(email: email, password: password);
      await _loadProfile();
      return true;
    } on AuthException catch (e) {
      _error = _translateAuthError(e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _profile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() => _loadProfile();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _translateAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login')) return 'البريد أو كلمة المرور غير صحيحة';
    if (lower.contains('already registered')) return 'البريد مسجل بالفعل';
    if (lower.contains('password')) return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
    if (lower.contains('email')) return 'البريد الإلكتروني غير صالح';
    return raw;
  }
}