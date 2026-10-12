import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Result of a signup attempt.
///
/// - [success]: session created, user is logged in.
/// - [needsEmailConfirmation]: user created but must confirm email first.
/// - [error]: something failed, check [AuthProvider.error].
enum SignUpResult { success, needsEmailConfirmation, error }

class AuthProvider extends ChangeNotifier {
  late final AuthRepository _repo;
  AuthStatus _status = AuthStatus.unknown;
  Map<String, dynamic>? _profile;
  String? _error;
  String? _pendingEmail;

  AuthProvider() {
    _repo = AuthRepository(Supabase.instance.client);
  }

  AuthStatus get status => _status;
  User? get user => _repo.currentUser;
  Map<String, dynamic>? get profile => _profile;
  String? get error => _error;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  /// Email waiting for confirmation (set after signup).
  String? get pendingEmail => _pendingEmail;

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

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _error = null;
    _pendingEmail = null;
    try {
      final res = await _repo.signUp(
        email: email,
        password: password,
        name: name,
      );

      // If Supabase returned a session → user is logged in immediately
      // (email confirmation is disabled).
      if (res.session != null) {
        await _loadProfile();
        return SignUpResult.success;
      }

      // User created but no session → confirmation email sent.
      _pendingEmail = email.trim();
      notifyListeners();
      return SignUpResult.needsEmailConfirmation;
    } on AuthException catch (e) {
      _error = _translateAuthError(e.message);
      notifyListeners();
      return SignUpResult.error;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return SignUpResult.error;
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

  /// Resend the confirmation email for the pending signup.
  Future<bool> resendConfirmationEmail() async {
    final email = _pendingEmail;
    if (email == null || email.isEmpty) return false;
    try {
      await _repo.resendConfirmationEmail(email);
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

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repo.resetPassword(email);
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
    _pendingEmail = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() => _loadProfile();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearPendingEmail() {
    _pendingEmail = null;
    notifyListeners();
  }

  // ============================================
  // ERROR TRANSLATION
  // ============================================
  //
  // Order matters: check specific patterns before generic ones.
  String _translateAuthError(String raw) {
    final lower = raw.toLowerCase();

    // Auth flow errors
    if (lower.contains('email not confirmed') ||
        lower.contains('not confirmed')) {
      return 'لم يتم تأكيد البريد الإلكتروني — راجع صندوق الوارد';
    }
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'البريد أو كلمة المرور غير صحيحة';
    }
    if (lower.contains('already registered') ||
        lower.contains('user already exists')) {
      return 'البريد مسجل بالفعل — جرّب تسجيل الدخول';
    }
    if (lower.contains('password should be') ||
        lower.contains('password is too short')) {
      return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
    }
    if (lower.contains('unable to validate email') ||
        lower.contains('invalid email') ||
        lower.contains('email address') && lower.contains('invalid')) {
      return 'البريد الإلكتروني غير صالح';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'محاولات كثيرة — انتظر قليلًا ثم أعد المحاولة';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'تحقق من اتصالك بالإنترنت';
    }

    // Fallback
    return raw;
  }
}