import 'auth_state.dart';

/// Interface repository untuk autentikasi.
///
/// Implementasi konkret akan menggunakan Supabase Auth (Google OAuth).
abstract interface class AuthRepository {
  /// Login dengan Google OAuth.
  Future<void> signInWithGoogle();

  /// Logout user saat ini.
  Future<void> signOut();

  /// Stream status autentikasi (real-time).
  Stream<AuthState> authStateChanges();

  /// Cek apakah user sudah login.
  Future<bool> isSignedIn();
}
