// home_screen.dart
//
// Purpose:
// → Halaman utama setelah login. Merakit semua widget beranda.
//
// Used By:
// → bottom_nav_shell.dart
//
// Depends On:
// → activity_provider, app_colors, auth_provider, widget/* (cards, chart)
//
// Impact:
// → Tab Home di bottom navigation

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../navigation/bottom_nav_shell.dart';
import '../profile/profile_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/findrisc_provider.dart';
import 'providers/tutorial_provider.dart';
import 'widgets/activity_cards.dart';
import 'widgets/challenge_card.dart';
import 'widgets/food_log_card.dart';
import 'widgets/iloo_tutorial_dialog.dart';
import '../../core/sensor_service.dart';

/// Home dashboard screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Mencegah double schedule dari 2 listener yg fire di frame yg sama.
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    // [ID] Init tutorialDoneProvider dari SharedPreferences biar sinkron
    // [EN] Init tutorialDoneProvider from SharedPreferences for sync check
    // [WHY] Hindari race condition FutureProvider setelah invalidate()
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('tutorial_iloo_done') ?? false;
      ref.read(tutorialDoneProvider.notifier).state = done;
      _checkAndShowTutorial();
    });
  }

  void _checkAndShowTutorial() {
    // [ID] Pake tutorialDoneProvider sync — zero race condition
    // [EN] Use sync tutorialDoneProvider — no race condition
    if (!ref.read(tutorialDoneProvider) &&
        ref.read(bottomNavIndexProvider) == 0) {
      _tryScheduleTutorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener tab switch: kalo pindah ke tab 0, cek apakah tutorial perlu muncul
    ref.listen<int>(bottomNavIndexProvider, (prev, next) {
      if (next != 0) return;
      _checkAndShowTutorial();
    });

    // Listen permission usage
    ref.listen<bool>(usagePermissionNeededProvider, (prev, next) {
      if (next == true) {
        _showUsagePermissionDialog();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh profile data (termasuk risk score & category)
            await ref.read(profileNotifierProvider.notifier).loadProfile();
            // Refresh activity data
            ref.invalidate(activityDataProvider);
            ref.invalidate(findriscDataProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(),
                const SizedBox(height: 24),
                _RiskCard(),
                const SizedBox(height: 12),
                _ScoreCard(),
                const SizedBox(height: 16),
                const FoodLogCard(),
                const SizedBox(height: 24),
                Text(
                  'Aktivitas Harian',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const ActivityCards(),
                const SizedBox(height: 24),
                Text(
                  'Tantangan Hari Ini',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const ChallengeCard(),
                const SizedBox(height: 24),
                const MoreQuestsButton(),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _tryScheduleTutorial() {
    if (_tutorialScheduled) return;
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tutorialScheduled = false;
      _showTutorialDialog();
    });
  }

  /// [ID] Mark tutorial sebagai dismissed (X button tanpa complete)
  /// [EN] Mark tutorial as dismissed (X button without complete)
  /// [WHY] Cegah tutorial muncul lagi setelah di-dismiss tanpa complete
  Future<void> _markTutorialDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_iloo_done', true);
    ref.read(tutorialDoneProvider.notifier).state = true;
  }

  void _showTutorialDialog() {
    if (!mounted) return;
    final guard1 = ref.read(tutorialDialogShowingProvider);
    final guard2 = IlooTutorialDialog.isShowing;
    if (guard1 || guard2) return;

    ref.read(tutorialDialogShowingProvider.notifier).state = true;
    IlooTutorialDialog.isShowing = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const IlooTutorialDialog();
      },
    ).then((_) {
      ref.read(tutorialDialogShowingProvider.notifier).state = false;
      IlooTutorialDialog.isShowing = false;
      // [FIX] X button dismiss tanpa _completeTutorial — tetap mark done
      // [EN] X button dismiss without _completeTutorial — still mark done
      if (!ref.read(tutorialDoneProvider)) {
        _markTutorialDismissed();
      }
    });
  }

  void _showUsagePermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Izin Waktu Layar',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Glicoo butuh izin "Usage Data Access" (Akses Data Penggunaan) untuk melacak Screen Time kamu secara akurat.\n\nSetelah klik Lanjut, kamu akan diarahkan ke Pengaturan. Tolong cari aplikasi Glicoo dan aktifkan izinnya ya!',
            style: GoogleFonts.inter(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Abaikan, tp state masih true (akan ditanya lagi pas reload klo blm diizinin)
                Navigator.of(context).pop();
                ref.read(usagePermissionNeededProvider.notifier).state = false;
              },
              child: Text(
                'Nanti Saja',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(sensorServiceProvider).openUsageSettings();
              },
              child: Text(
                'Lanjut',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Private inline widgets ───────────────────────────────────────────────────
// Dibuat private karena hanya dipakai di file ini.

class _HomeHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final name = profileState.name.isNotEmpty ? profileState.name : 'Pemanasan';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $name!',
          style: GoogleFonts.rammettoOne(fontSize: 24, color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          'Selamat datang!',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RiskCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final findriscData = ref.watch(findriscDataProvider);
    return findriscData.when(
      data: (data) {
        final category = data['category'] as String;

        // Dynamic Risk styling helper (same as profile_screen.dart)
        Color riskColor = const Color(0xFFFFB700); // Default Yellow
        String riskTitle = category;
        final catLower = category.toLowerCase();

        if (catLower.contains('sangat tinggi')) {
          riskColor = const Color(0xFFFF3B30); // Red
          riskTitle = 'Sangat Tinggi';
        } else if (catLower.contains('tinggi')) {
          riskColor = const Color(0xFFFF8800); // Orange
          riskTitle = 'Tinggi';
        } else if (catLower.contains('sedikit')) {
          riskColor = const Color(0xFF007AFF); // Blue
          riskTitle = 'Sedikit Meningkat';
        } else if (catLower.contains('rendah')) {
          riskColor = const Color(0xFF24B35F); // Green
          riskTitle = 'Rendah';
        } else if (catLower.contains('sedang')) {
          riskColor = const Color(0xFFFFB700); // Yellow
          riskTitle = 'Sedang';
        } else if (catLower.contains('belum')) {
          riskColor = const Color(0xFF8E8E93); // Gray
          riskTitle = 'Belum Tes';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Risiko Saat Ini',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/home/kategori.svg',
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(riskColor, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      riskTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 56),
      error: (e, _) => const SizedBox(height: 56),
    );
  }
}

class _ScoreCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final findriscData = ref.watch(findriscDataProvider);
    return findriscData.when(
      data: (data) {
        final score = data['score'] as int;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skor FINDRISC',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFB700),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.remove,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stabil',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFB700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 80),
      error: (e, _) => const SizedBox(height: 80),
    );
  }
}
