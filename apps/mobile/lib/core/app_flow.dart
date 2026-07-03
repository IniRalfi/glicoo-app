// app_flow.dart
//
// Purpose:
// → Orchestrate navigation flow: Splash → Onboarding → Legal → Auth → FINDRISC → Home.
//   Dipindah dari main.dart agar entry point tetap minimal.
//
// Used By:
// → main.dart (GlicoApp)
//
// Depends On:
// → supabase_flutter, hooks_riverpod, shared_preferences
// → features/auth, features/findrisc, features/navigation
//
// Impact:
// → Seluruh alur navigasi awal aplikasi

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'sensor_service.dart';
import 'theme/app_colors.dart';
import 'widgets/glico_loading.dart';
import 'widgets/loading_provider.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/findrisc/domain/findrisc_data.dart';
import '../features/findrisc/findrisc_complete_screen.dart';
import '../features/findrisc/findrisc_focus_screen.dart';
import '../features/findrisc/findrisc_intro_screen.dart';
import '../features/findrisc/findrisc_result_screen.dart';
import '../features/findrisc/findrisc_step1_screen.dart';
import '../features/findrisc/findrisc_step2_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/navigation/bottom_nav_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';

/// Flow state untuk navigasi awal aplikasi.
enum AppFlowState {
  splash,
  onboarding,
  legal,
  auth,
  findriscIntro,
  findriscStep1,
  findriscStep2,
  findriscComplete,
  findriscResult,
  findriscFocus,
  home,
}

enum _AuthFlow { login, register, forgotPassword }

/// Entry point yang handle flow: Splash → Onboarding → Legal → Auth → Home.
class AppEntryPoint extends ConsumerStatefulWidget {
  const AppEntryPoint({super.key});

  @override
  ConsumerState<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends ConsumerState<AppEntryPoint> {
  AppFlowState _state = AppFlowState.splash;
  _AuthFlow _authFlow = _AuthFlow.login;

  /// Flag to prevent multiple navigations from same auth event
  bool _authHandled = false;

  // ── Data passing antar screen FINDRISC ──
  int? _age;
  String? _ageGroup;
  double? _tinggiCm;
  double? _beratKg;
  double? _lingkarPinggangCm;
  FindriscData? _findriscData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthStatus();

      // Inisialisasi sensor tracking harian dan background sync
      final sensorService = ref.read(sensorServiceProvider);
      sensorService.initPedometer();
      sensorService.initScreenTimeTracking();

      // Inisialisasi notifikasi lokal & rutinitas harian
      final notifService = NotificationService();
      notifService.init().then((_) {
        notifService.requestPermissions().then((granted) {
          if (granted) {
            notifService.scheduleDefaultGlicooReminders();
          }
        });
      });
    });
  }

  /// Setelah splash selesai, cek apakah user sudah pernah onboarding.
  /// Jika sudah onboarding DAN sudah authenticated, langsung cek findrisc.
  Future<void> _onSplashComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;

    if (onboardingDone) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );

      if (isAuthenticated) {
        final findriscDone = await _checkFindriscDone();
        _authHandled = true;
        if (!mounted) return;
        setState(() {
          _state = findriscDone
              ? AppFlowState.home
              : AppFlowState.findriscIntro;
        });
      } else {
        setState(() => _state = AppFlowState.auth);
      }
    } else {
      setState(() => _state = AppFlowState.onboarding);
    }
  }

  Future<void> _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    setState(() => _state = AppFlowState.legal);
  }

  void _onLegalAccepted() => setState(() => _state = AppFlowState.auth);

  /// Cek apakah user sudah pernah mengisi FINDRISC questionnaire (lokal maupun server).
  Future<bool> _checkFindriscDone() async {
    final prefs = await SharedPreferences.getInstance();
    final localDone = prefs.getBool('findrisc_done') ?? false;
    if (localDone) return true;

    try {
      final profile = await ref.read(apiServiceProvider).getUserProfile();
      final age = profile['age'];
      final height = profile['height'];
      final weight = profile['weight'];

      if (age != null && height != null && weight != null) {
        await prefs.setBool('findrisc_done', true);

        final riskScore = profile['risk_score'] ?? 0.0;
        await prefs.setInt('findrisc_score', (riskScore as num).toInt());
        await prefs.setDouble(
          'lingkar_pinggang_cm',
          (height as num).toDouble(),
        );
        return true;
      }
    } catch (e) {
      debugPrint('[FINDRISC_CHECK] Gagal mengambil profil dari backend: $e');
    }

    return false;
  }

  void _onFindriscIntroComplete() {
    if (!mounted) return;
    setState(() => _state = AppFlowState.findriscStep1);
  }

  void _onFindriscStep1Complete(
    int age,
    String ageGroup,
    double tinggiCm,
    double beratKg,
    double lingkarPinggangCm,
  ) {
    if (!mounted) return;
    setState(() {
      _age = age;
      _ageGroup = ageGroup;
      _tinggiCm = tinggiCm;
      _beratKg = beratKg;
      _lingkarPinggangCm = lingkarPinggangCm;
      _state = AppFlowState.findriscStep2;
    });
  }

  void _onFindriscStep2Complete(FindriscData data) {
    if (!mounted) return;
    setState(() {
      _findriscData = data;
      _state = AppFlowState.findriscComplete;
    });
  }

  void _onFindriscComplete() {
    if (!mounted) return;
    setState(() => _state = AppFlowState.findriscResult);
  }

  void _onFindriscResultComplete() {
    if (!mounted) return;
    setState(() => _state = AppFlowState.findriscFocus);
  }

  /// Setelah user tap "Lanjut ke Beranda" di halaman fokus,
  /// simpan flag findrisc_done, lalu lanjut ke home.
  Future<void> _onFindriscFocusComplete() async {
    final prefs = await SharedPreferences.getInstance();

    if (_findriscData != null) {
      // [ID] Pake umur asli dari input user, bukan mapping ageGroup
      final age = _findriscData!.age;
      final hasFamilyHistory = _findriscData!.riwayatKeluargaDM != 'Tidak';

      ref
          .read(loadingProvider.notifier)
          .show(
            title: 'Menyimpan Hasil...',
            subtitle: 'Mengirim data ke server Glicoo',
          );

      try {
        await ref
            .read(apiServiceProvider)
            .updateUserProfile(
              age: age,
              height: _findriscData!.tinggiCm,
              weight: _findriscData!.beratKg,
              hasFamilyHistory: hasFamilyHistory,
              riskScore: _findriscData!.totalSkor,
              riskCategory: _findriscData!.kategori,
            );

        await prefs.setBool('findrisc_done', true);
        await prefs.setInt('findrisc_score', _findriscData!.totalSkor);
        await prefs.setString('findrisc_category', _findriscData!.kategori);
        await prefs.setDouble(
          'lingkar_pinggang_cm',
          _findriscData!.lingkarPinggangCm,
        );

        ref.read(loadingProvider.notifier).hide();

        if (!mounted) return;
        setState(() => _state = AppFlowState.home);
      } catch (e) {
        ref.read(loadingProvider.notifier).hide();

        if (!mounted) return;
        _showErrorDialog(context, e.toString());
      }
    } else {
      await prefs.setBool('findrisc_done', true);
      if (!mounted) return;
      setState(() => _state = AppFlowState.home);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gagal Menyimpan Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terjadi kesalahan saat mengirim hasil kuesioner Anda ke server Glicoo:',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Silakan ambil screenshot pesan ini untuk dilaporkan ke pengembang jika masalah berlanjut.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Bolehkan masuk ke beranda meskipun gagal sync
                setState(() => _state = AppFlowState.home);
              },
              child: const Text(
                'Lewati & Masuk',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _onFindriscFocusComplete();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        switch (_state) {
          AppFlowState.splash => SplashScreen(
            onInitializationComplete: _onSplashComplete,
          ),
          AppFlowState.onboarding => OnboardingScreen(
            onComplete: _onOnboardingComplete,
          ),
          AppFlowState.legal => LegalScreen(onAccepted: _onLegalAccepted),
          AppFlowState.auth => _buildAuthScreen(),
          AppFlowState.findriscIntro => FindriscIntroScreen(
            onComplete: _onFindriscIntroComplete,
          ),
          AppFlowState.findriscStep1 => FindriscStep1Screen(
            onComplete: _onFindriscStep1Complete,
          ),
          AppFlowState.findriscStep2 => FindriscStep2Screen(
            age: _age!,
            ageGroup: _ageGroup!,
            tinggiCm: _tinggiCm!,
            beratKg: _beratKg!,
            lingkarPinggangCm: _lingkarPinggangCm!,
            onComplete: _onFindriscStep2Complete,
          ),
          AppFlowState.findriscComplete => FindriscCompleteScreen(
            onComplete: _onFindriscComplete,
          ),
          AppFlowState.findriscResult => FindriscResultScreen(
            data: _findriscData!,
            onComplete: _onFindriscResultComplete,
          ),
          AppFlowState.findriscFocus => FindriscFocusScreen(
            onComplete: _onFindriscFocusComplete,
          ),
          AppFlowState.home => const BottomNavShell(),
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

            if (!showLoading) return const SizedBox.shrink();

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
                  !_authHandled &&
                  (_state == AppFlowState.auth ||
                      _state == AppFlowState.splash)) {
                _authHandled = true;
                // [WHY] Tampilkan loading segera agar user ga lihat freeze
                ref
                    .read(loadingProvider.notifier)
                    .show(
                      title: 'Memproses...',
                      subtitle: 'Mohon tunggu sebentar',
                    );
                _checkFindriscDone().then((done) {
                  ref.read(loadingProvider.notifier).hide();
                  if (!mounted) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _state = done
                            ? AppFlowState.home
                            : AppFlowState.findriscIntro;
                      });
                    }
                  });
                });
              }
              // Pas logout, balik ke login screen
              if (!isAuthenticated && _state == AppFlowState.home) {
                _authHandled = false;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _state = AppFlowState.auth;
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
