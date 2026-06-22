// main.dart
//
// Entry point Glico — initialize Supabase, then orchestrate navigation flow:
//   Splash → Onboarding (first-time) → Legal → Auth → Home
//
// Purpose:
// App bootstrap: load .env, init Supabase, wrap with ProviderScope.
//
// Used By:
// —
//
// Depends On:
// supabase_flutter, flutter_dotenv, hooks_riverpod
//
// Impact:
// Every screen in the app

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/env_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/legal/legal_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load .env
  await EnvConfig.load();

  // 2. Init Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    publishableKey: EnvConfig.supabaseAnonKey,
  );

  // 3. Build AuthRepository after Supabase is ready
  final authRepository = SupabaseAuthRepository(
    supabase: Supabase.instance.client,
  );

  runApp(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      child: const GlicoApp(),
    ),
  );
}

class GlicoApp extends ConsumerWidget {
  const GlicoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Glico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppEntryPoint(),
    );
  }
}

/// Flow state untuk navigasi awal aplikasi.
enum _FlowState { splash, onboarding, legal, auth, home }

/// Entry point yang handle flow: Splash → Onboarding → Legal → Auth → Home.
class _AppEntryPoint extends ConsumerStatefulWidget {
  const _AppEntryPoint();

  @override
  ConsumerState<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends ConsumerState<_AppEntryPoint> {
  _FlowState _state = _FlowState.splash;

  // Sub-flow dalam auth: login / register / forgot-password
  _AuthFlow _authFlow = _AuthFlow.login;

  /// Flag to prevent multiple navigations from same auth event
  bool _authHandled = false;

  @override
  void initState() {
    super.initState();
    // Check auth status after first frame (ref.listen only valid in build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  void _onSplashComplete() => setState(() => _state = _FlowState.onboarding);
  void _onOnboardingComplete() => setState(() => _state = _FlowState.legal);
  void _onLegalAccepted() => setState(() => _state = _FlowState.auth);

  @override
  Widget build(BuildContext context) {
    // Gunakan Stack + Consumer untuk ref.listen — lebih aman dari lifecycle issue
    return Stack(
      children: [
        switch (_state) {
          _FlowState.splash => SplashScreen(
            onInitializationComplete: _onSplashComplete,
          ),
          _FlowState.onboarding => OnboardingScreen(
            onComplete: _onOnboardingComplete,
          ),
          _FlowState.legal => LegalScreen(onAccepted: _onLegalAccepted),
          _FlowState.auth => _buildAuthScreen(),
          _FlowState.home => const _HomePlaceholder(),
        },
        // Consumer terpisah untuk listen auth state — ref.listen selalu valid di sini
        Consumer(
          builder: (context, ref, _) {
            ref.listen<AuthState>(authProvider, (prev, next) {
              final isAuthenticated = next.maybeWhen(
                authenticated: (_) => true,
                orElse: () => false,
              );
              if (isAuthenticated &&
                  _state == _FlowState.auth &&
                  !_authHandled) {
                _authHandled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _state = _FlowState.home);
                });
              }
              // Pas logout, balik ke login screen
              if (!isAuthenticated && _state == _FlowState.home) {
                _authHandled = false;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _state = _FlowState.auth;
                      _authFlow = _AuthFlow.login;
                    });
                  }
                });
              }
            });
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildAuthScreen() {
    switch (_authFlow) {
      case _AuthFlow.login:
        return LoginScreen(
          onNavigateToRegister: () =>
              setState(() => _authFlow = _AuthFlow.register),
          onNavigateToForgotPassword: () =>
              setState(() => _authFlow = _AuthFlow.forgotPassword),
        );
      case _AuthFlow.register:
        return RegisterScreen(
          onNavigateToLogin: () => setState(() => _authFlow = _AuthFlow.login),
        );
      case _AuthFlow.forgotPassword:
        return ForgotPasswordScreen(
          onBack: () => setState(() => _authFlow = _AuthFlow.login),
        );
    }
  }
}

enum _AuthFlow { login, register, forgotPassword }

/// Placeholder for home screen — with logout button.
class _HomePlaceholder extends ConsumerWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'Berhasil Masuk!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar / Ganti Akun'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
