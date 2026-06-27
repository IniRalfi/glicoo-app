// auth_repository.dart
//
// Purpose:
// Interface repository for authentication — supports both Google OAuth and
// email/password flows. Concrete implementation uses Supabase Auth.
//
// Used By:
// auth_provider.dart, login_screen.dart, register_screen.dart
//
// Depends On:
// auth_state.dart
//
// Impact:
// auth_provider.dart, main.dart

import 'auth_state.dart';

/// Interface repository for authentication.
abstract interface class AuthRepository {
  /// Login with email + password.
  Future<void> signInWithEmail(String email, String password);

  /// Register a new account with email + password.
  Future<void> signUpWithEmail(String email, String password, String name);

  /// Send password reset email.
  Future<void> resetPassword(String email);

  /// Login with Google OAuth.
  Future<void> signInWithGoogle();

  /// Logout user saat ini.
  Future<void> signOut();

  /// Stream status autentikasi (real-time).
  Stream<AuthState> authStateChanges();

  /// Cek apakah user sudah login.
  Future<bool> isSignedIn();
}
