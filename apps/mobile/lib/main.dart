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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/glico_loading.dart';
import 'core/widgets/loading_provider.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/legal/legal_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/navigation/bottom_nav_shell.dart';
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
      title: 'Glicoo',
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  /// Setelah splash selesai, cek apakah user sudah pernah onboarding.
  Future<void> _onSplashComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    setState(() {
      _state = onboardingDone ? _FlowState.auth : _FlowState.onboarding;
    });
  }

  Future<void> _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    setState(() => _state = _FlowState.legal);
  }

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
          _FlowState.home => const BottomNavShell(),
        },
        // Loading overlay — auto-show dari authProvider (loading) + manual loadingProvider
        Consumer(
          builder: (context, ref, _) {
            final authState = ref.watch(authProvider);
            final authLoading = authState.maybeWhen(
              loading: () => true,
              orElse: () => false,
            );
            final loadingState = ref.watch(loadingProvider);

            final showLoading = authLoading || loadingState.isLoading;

            if (!showLoading) {
              return const SizedBox.shrink();
            }

            return GlicoLoadingOverlay(
              title: loadingState.title,
              subtitle: loadingState.subtitle,
            );
          },
        ),
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
