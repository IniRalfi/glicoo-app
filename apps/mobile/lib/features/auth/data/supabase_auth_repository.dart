// supabase_auth_repository.dart
//
// Purpose:
// Concrete implementation of AuthRepository using Supabase Auth.
// Handles email/password login, Google OAuth, password reset, and sign out.
//
// Used By:
// auth_provider.dart (injected via ProviderScope)
//
// Depends On:
// supabase_flutter, AuthRepository, AuthState
//
// Impact:
// main.dart — initialization order

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

/// Implementasi AuthRepository menggunakan Supabase Auth.
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required this.supabase});

  final SupabaseClient supabase;

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
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.glicoo.glicoo_mobile://callback',
    );
  }

  @override
  Future<void> signOut() async {
    await supabase.auth.signOut();
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
