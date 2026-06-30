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

import 'package:workmanager/workmanager.dart';
import 'core/api_service.dart';
import 'core/env_config.dart';
import 'core/sensor_service.dart';
import 'core/notification_service.dart';
import 'core/theme/app_colors.dart';
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
import 'features/findrisc/findrisc_complete_screen.dart';
import 'features/findrisc/findrisc_intro_screen.dart';
import 'features/findrisc/findrisc_result_screen.dart';
import 'features/findrisc/findrisc_focus_screen.dart';
import 'features/findrisc/findrisc_step1_screen.dart';
import 'features/findrisc/findrisc_step2_screen.dart';
import 'features/findrisc/domain/findrisc_data.dart';
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

  // 3. Init Workmanager background callback & task
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    '1',
    kBackgroundSyncTaskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // 4. Build AuthRepository after Supabase is ready
  final authRepository = SupabaseAuthRepository(
    supabase: Supabase.instance.client,
    serverClientId: EnvConfig.googleWebClientId,
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
enum _FlowState {
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
      // Cek apakah user sudah authenticated (session aktif)
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );

      if (isAuthenticated) {
        // Sudah login, cek findrisc langsung (ambil secara async dari backend jika local false)
        final findriscDone = await _checkFindriscDone();
        _authHandled = true;
        if (!mounted) return;
        setState(() {
          _state = findriscDone ? _FlowState.home : _FlowState.findriscIntro;
        });
      } else {
        setState(() => _state = _FlowState.auth);
      }
    } else {
      setState(() => _state = _FlowState.onboarding);
    }
  }

  Future<void> _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    setState(() => _state = _FlowState.legal);
  }

  void _onLegalAccepted() => setState(() => _state = _FlowState.auth);

  /// Cek apakah user sudah pernah mengisi FINDRISC questionnaire (baik lokal maupun di server).
  Future<bool> _checkFindriscDone() async {
    final prefs = await SharedPreferences.getInstance();
    final localDone = prefs.getBool('findrisc_done') ?? false;
    if (localDone) return true;

    try {
      // Cek ke backend apakah data profil user sudah lengkap
      final profile = await ref.read(apiServiceProvider).getUserProfile();
      final age = profile['age'];
      final height = profile['height'];
      final weight = profile['weight'];

      if (age != null && height != null && weight != null) {
        // Tandai sudah selesai secara lokal agar tidak perlu request ke server lagi
        await prefs.setBool('findrisc_done', true);

        final riskScore = profile['risk_score'] ?? 0.0;
        await prefs.setInt('findrisc_score', (riskScore as num).toInt());

        // Simpan default data agar UI profile tidak kosong
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

  /// Setelah user menekan tombol "Yuk, mulai sekarang!" di intro FINDRISC,
  /// lanjut ke step 1 (questionnaire data fisik).
  void _onFindriscIntroComplete() {
    if (!mounted) return;
    setState(() => _state = _FlowState.findriscStep1);
  }

  /// Setelah user menyelesaikan FINDRISC step 1 (data fisik),
  /// simpan data fisik dan lanjut ke step 2.
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
      _state = _FlowState.findriscStep2;
    });
  }

  /// Setelah user menyelesaikan FINDRISC step 2 (gaya hidup & riwayat),
  /// simpan data lengkap dan lanjut ke halaman "Penilaian Selesai!".
  void _onFindriscStep2Complete(FindriscData data) {
    if (!mounted) return;
    setState(() {
      _findriscData = data;
      _state = _FlowState.findriscComplete;
    });
  }

  /// Setelah user tap "Lanjutkan" di halaman Penilaian Selesai,
  /// lanjut ke halaman hasil risiko.
  void _onFindriscComplete() {
    if (!mounted) return;
    setState(() => _state = _FlowState.findriscResult);
  }

  /// Setelah user melihat hasil dan tap "Lanjutkan",
  /// lanjut ke halaman fokus.
  void _onFindriscResultComplete() {
    if (!mounted) return;
    setState(() => _state = _FlowState.findriscFocus);
  }

  /// Setelah user tap "Lanjut ke Beranda" di halaman fokus,
  /// simpan flag findrisc_done, lalu lanjut ke home.
  Future<void> _onFindriscFocusComplete() async {
    final prefs = await SharedPreferences.getInstance();

    if (_findriscData != null) {
      // [ID] Pake umur asli dari input user, bukan mapping ageGroup
      final age = _findriscData!.age;

      final hasFamilyHistory = _findriscData!.riwayatKeluargaDM != 'Tidak';

      // Tampilkan animated loading overlay
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

        // Simpan flag findrisc_done secara lokal hanya jika sinkronisasi berhasil
        await prefs.setBool('findrisc_done', true);
        await prefs.setInt('findrisc_score', _findriscData!.totalSkor);
        await prefs.setString('findrisc_category', _findriscData!.kategori);
        await prefs.setDouble(
          'lingkar_pinggang_cm',
          _findriscData!.lingkarPinggangCm,
        );

        // Sembunyikan loading
        ref.read(loadingProvider.notifier).hide();

        if (!mounted) return;
        setState(() => _state = _FlowState.home);
      } catch (e) {
        // Sembunyikan loading
        ref.read(loadingProvider.notifier).hide();

        if (!mounted) return;
        // Tampilkan dialog error agar user bisa screenshot / melihat penyebabnya
        _showErrorDialog(context, e.toString());
      }
    } else {
      await prefs.setBool('findrisc_done', true);
      if (!mounted) return;
      setState(() => _state = _FlowState.home);
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
                setState(() => _state = _FlowState.home);
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
          _FlowState.findriscIntro => FindriscIntroScreen(
            onComplete: _onFindriscIntroComplete,
          ),
          _FlowState.findriscStep1 => FindriscStep1Screen(
            onComplete: _onFindriscStep1Complete,
          ),
          _FlowState.findriscStep2 => FindriscStep2Screen(
            age: _age!,
            ageGroup: _ageGroup!,
            tinggiCm: _tinggiCm!,
            beratKg: _beratKg!,
            lingkarPinggangCm: _lingkarPinggangCm!,
            onComplete: _onFindriscStep2Complete,
          ),
          _FlowState.findriscComplete => FindriscCompleteScreen(
            onComplete: _onFindriscComplete,
          ),
          _FlowState.findriscResult => FindriscResultScreen(
            data: _findriscData!,
            onComplete: _onFindriscResultComplete,
          ),
          _FlowState.findriscFocus => FindriscFocusScreen(
            onComplete: _onFindriscFocusComplete,
          ),
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
              // Handle login success: dari auth screen ATAU dari splash (race condition)
              if (isAuthenticated &&
                  !_authHandled &&
                  (_state == _FlowState.auth || _state == _FlowState.splash)) {
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
                            ? _FlowState.home
                            : _FlowState.findriscIntro;
                      });
                    }
                  });
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
