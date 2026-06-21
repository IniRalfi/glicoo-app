// main.dart
//
// Entry point Glico — meng-orchestrate app-level navigation flow awal:
//   Splash → Onboarding (first-time) → Legal → Auth

import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/legal/legal_screen.dart';

void main() {
  runApp(const GlicoApp());
}

class GlicoApp extends StatelessWidget {
  const GlicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppEntryPoint(),
    );
  }
}

/// Flow state untuk navigasi awal aplikasi.
enum _FlowState { splash, onboarding, legal, auth }

/// Entry point yang handle flow: Splash → Onboarding → Legal → Auth.
class _AppEntryPoint extends StatefulWidget {
  const _AppEntryPoint();

  @override
  State<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<_AppEntryPoint> {
  _FlowState _state = _FlowState.splash;

  void _onSplashComplete() => setState(() => _state = _FlowState.onboarding);
  void _onOnboardingComplete() => setState(() => _state = _FlowState.legal);
  void _onLegalAccepted() => setState(() => _state = _FlowState.auth);

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _FlowState.splash:
        return SplashScreen(onInitializationComplete: _onSplashComplete);
      case _FlowState.onboarding:
        return OnboardingScreen(onComplete: _onOnboardingComplete);
      case _FlowState.legal:
        return LegalScreen(onAccepted: _onLegalAccepted);
      case _FlowState.auth:
        return const _AuthPlaceholder();
    }
  }
}

/// Placeholder untuk halaman auth (login/register) — akan diganti nanti.
class _AuthPlaceholder extends StatelessWidget {
  const _AuthPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Auth Screen',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Login / Register akan diimplementasikan di sini',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
