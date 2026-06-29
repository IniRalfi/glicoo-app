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

import 'dart:developer' as dev;
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

  /// [ID] Logout — clear SEMUA data local storage agar user baru/ganti akun
  /// tidak melihat data user sebelumnya (findrisc, activities, tutorial).
  /// [EN] Logout — clear ALL local storage so new/switched user doesn't see
  /// previous user's data (findrisc, activities, tutorial).
  Future<void> signOut() async {
    state = const AuthState.loading();
    try {
      await _repository.signOut();

      // [ID] Clear SEMUA local storage saat logout/switch account
      // [WHY] Bug: data findrisc_score, activities, tutorial tertinggal saat ganti akun
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear ALL keys — most reliable way

      // Alternative: Manual key removal (jika prefs.clear() terlalu agresif)
      // await prefs.remove('findrisc_done');
      // await prefs.remove('findrisc_score');
      // await prefs.remove('findrisc_category');
      // await prefs.remove('tutorial_iloo_done');
      // await prefs.remove('glico_daily_steps');
      // await prefs.remove('glico_daily_screen_minutes');
      // await prefs.remove('glico_daily_sleep_minutes');
      // await prefs.remove('glico_daily_calories');
      // await prefs.remove('glico_last_sync_date');

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
    // [WHY] Gunakan dev.log agar error tetap tercetak di release mode
    // tanpa trigger lint avoid_print.
    dev.log('[AUTH_ERROR] $msg', name: 'auth_provider');

    if (msg.contains('GAGAL_GOOGLE')) {
      if (msg.contains('Token otentikasi kosong') ||
          msg.contains('idToken null')) {
        return 'Login Google gagal: idToken null — Web Client ID salah. ($_googleErrorDetail(msg))';
      }
      if (msg.contains('10') || msg.contains('DEVELOPER_ERROR')) {
        return 'Login Google gagal: DEVELOPER_ERROR 10 — SHA-1 belum terdaftar.';
      }
      if (msg.contains('membatalkan')) {
        return 'Login Google dibatalkan.';
      }
      if (msg.contains('network') ||
          msg.contains('Network') ||
          msg.contains('INTERNET')) {
        return 'Koneksi internet bermasalah. Coba lagi.';
      }
      // Tampilkan raw error saat tidak dikenali agar bisa di-debug
      return 'Login Google gagal: $msg';
    }

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
    return 'Terjadi kesalahan: $msg';
  }

  String _googleErrorDetail(String msg) {
    final start = msg.indexOf('GAGAL_GOOGLE:');
    if (start == -1) return msg;
    return msg.substring(start + 13).trim();
  }
} // end AuthNotifier

/// Provider state autentikasi.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
