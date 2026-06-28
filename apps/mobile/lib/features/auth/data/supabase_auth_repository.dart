// supabase_auth_repository.dart
//
// Purpose:
// Concrete implementation of AuthRepository using Supabase Auth.
// Google OAuth uses native google_sign_in plugin (opens account picker, not browser)
// + Supabase signInWithIdToken for the server-side session.
//
// Used By:
// auth_provider.dart (injected via ProviderScope)
//
// Depends On:
// supabase_flutter, google_sign_in, AuthRepository, AuthState
//
// Impact:
// main.dart — initialization order

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

/// Implementasi AuthRepository menggunakan Supabase Auth.
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required this.supabase, String? serverClientId})
    : _googleSignIn = GoogleSignIn(
        serverClientId: serverClientId,
        scopes: <String>['email', 'profile', 'openid'],
      );

  final SupabaseClient supabase;
  final GoogleSignIn _googleSignIn;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Gagal masuk — pengguna tidak ditemukan');
    }
  }

  @override
  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    if (response.user == null) {
      throw Exception('Gagal mendaftar — coba lagi');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> signInWithGoogle() async {
    // [ID] Login Google: native account picker → exchange idToken ke Supabase.
    // [WHY logging] Error Google Sign-In sering swallow jadi pesan generik.
    // debugPrint disini membantu diagnosis SHA-1/audience (DEVELOPER_ERROR) lewat logcat.
    try {
      // Trigger native Google Account picker — no browser redirect
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Pengguna membatalkan login Google');
      }

      // Get authentication tokens
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        // [WARNING] idToken null hampir selalu = SHA-1 fingerprint belum didaftarkan
        // ke OAuth Client ID di Google Cloud Console (DEVELOPER_ERROR 10).
        debugPrint('[GOOGLE_SIGN_IN] idToken null — kemungkinan SHA-1 belum terdaftar '
            'atau Web Client ID tidak cocok.');
        throw Exception('GAGAL_GOOGLE: Token otentikasi kosong. '
            'Periksa SHA-1 fingerprint & Web Client ID.');
      }

      // Exchange Google ID token for Supabase session
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );
    } on Exception {
      rethrow; // Sudah berformat, lempar apa adanya ke handler UI
    } catch (e) {
      // [ID] Tangkap error native (PlatformException/ApiException dari plugin)
      // dan bungkus agar _humanReadableError bisa mengenali pola kodenya.
      final raw = e.toString();
      debugPrint('[GOOGLE_SIGN_IN] Native error: $raw');
      throw Exception('GAGAL_GOOGLE: $raw');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([supabase.auth.signOut(), _googleSignIn.signOut()]);
  }

  @override
  Stream<AuthState> authStateChanges() {
    return supabase.auth.onAuthStateChange.map((event) {
      final session = event.session;
      if (session?.user != null) {
        return AuthState.authenticated(userId: session!.user.id);
      }
      return const AuthState.unauthenticated();
    });
  }

  @override
  Future<bool> isSignedIn() async {
    return supabase.auth.currentUser != null;
  }
}
