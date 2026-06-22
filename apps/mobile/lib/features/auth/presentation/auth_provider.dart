// auth_provider.dart
//
// Purpose:
// Riverpod StateNotifier for auth state. Exposes signIn, signUp, signOut,
// resetPassword. Concrete AuthRepository is injected via ProviderScope.
//
// Used By:
// login_screen.dart, register_screen.dart, main.dart
//
// Depends On:
// AuthRepository, AuthState
//
// Impact:
// Any screen that reads auth state

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

/// Provider untuk AuthRepository (di-override di ProviderScope dengan SupabaseAuthRepository).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'AuthRepository belum di-inject — override di ProviderScope main.dart',
  );
});

/// Notifier untuk state autentikasi.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState.unauthenticated()) {
    _listenToAuthChanges();
  }

  final AuthRepository _repository;

  void _listenToAuthChanges() {
    _repository.authStateChanges().listen((newState) {
      if (!mounted) return;
      state = newState;
    });
  }

  /// Login dengan email + password.
  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState.loading();
    try {
      await _repository.signInWithEmail(email, password);
      // State akan update via stream listener
    } catch (e) {
      state = AuthState.error(message: _humanReadableError(e));
    }
  }

  /// Daftar dengan email + password + nama.
  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    state = const AuthState.loading();
    try {
      await _repository.signUpWithEmail(email, password, name);
      // State akan update via stream listener
    } catch (e) {
      state = AuthState.error(message: _humanReadableError(e));
    }
  }

  /// Kirim email reset password.
  Future<void> resetPassword(String email) async {
    state = const AuthState.loading();
    try {
      await _repository.resetPassword(email);
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(message: _humanReadableError(e));
    }
  }

  /// Login dengan Google OAuth.
  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      await _repository.signInWithGoogle();
      // State akan update via stream listener
    } catch (e) {
      state = AuthState.error(message: _humanReadableError(e));
    }
  }

  /// Logout — juga clear flag findrisc_done agar user baru/berikutnya
  /// tidak langsung skip FINDRISC questionnaire.
  Future<void> signOut() async {
    state = const AuthState.loading();
    try {
      await _repository.signOut();
      // Clear FINDRISC flag on logout so next login shows intro again
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('findrisc_done');
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(message: _humanReadableError(e));
    }
  }

  /// Cek status auth saat startup.
  Future<void> checkAuthStatus() async {
    final isSignedIn = await _repository.isSignedIn();
    if (isSignedIn) {
      state = const AuthState.authenticated(userId: '');
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  /// Clear error state → back to unauthenticated.
  void clearError() {
    state = const AuthState.unauthenticated();
  }

  /// Ubah error teknis jadi pesan user-friendly.
  String _humanReadableError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox Anda.';
    }
    if (msg.contains('User already registered')) {
      return 'Email sudah terdaftar. Gunakan email lain atau masuk.';
    }
    if (msg.contains('Password should be')) {
      return 'Kata sandi minimal 6 karakter.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}

/// Provider state autentikasi.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
