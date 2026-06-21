import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

/// Provider untuk AuthRepository (akan di-override di main.dart dengan implementasi Supabase).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('AuthRepository belum diimplementasikan');
});

/// Notifier untuk state autentikasi.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState.unauthenticated()) {
    _listenToAuthChanges();
  }

  final AuthRepository _repository;

  void _listenToAuthChanges() {
    _repository.authStateChanges().listen((state) {
      if (mounted) state = state;
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      await _repository.signInWithGoogle();
      // State akan update via stream
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> signOut() async {
    state = const AuthState.loading();
    try {
      await _repository.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> checkAuthStatus() async {
    final isSignedIn = await _repository.isSignedIn();
    if (isSignedIn) {
      // State akan update via stream, tapi fallback:
      state = const AuthState.authenticated(userId: 'unknown');
    } else {
      state = const AuthState.unauthenticated();
    }
  }
}

/// Provider state autentikasi.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
