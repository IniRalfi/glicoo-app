// home_screen.dart
//
// Home dashboard — menampilkan ringkasan kesehatan user.
//
// Purpose:
// Halaman utama setelah login, menampilkan informasi risiko FINDRISC,
// langkah, tidur, waktu layar, dan tantangan hari ini.
//
// Used By:
// bottom_nav_shell.dart
//
// Depends On:
// flutter/material, hooks_riverpod, app_colors, auth_provider, bento_card,
// flutter_svg, google_fonts, shared_preferences, supabase_flutter
//
// Impact:
// Tab Home di bottom navigation

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/bento_card.dart';
import '../auth/presentation/auth_provider.dart';
import '../navigation/bottom_nav_shell.dart';

/// Data model untuk aktivitas harian.
class ActivityData {
  final int steps;
  final int stepsGoal;
  final int sleepMinutes;
  final int screenTimeMinutes;
  final List<int> stepsHistory;
  final List<int> sleepHistory;
  final List<int> screenTimeHistory;

  const ActivityData({
    required this.steps,
    required this.stepsGoal,
    required this.sleepMinutes,
    required this.screenTimeMinutes,
    required this.stepsHistory,
    required this.sleepHistory,
    required this.screenTimeHistory,
  });
}

/// Provider state untuk data aktivitas harian (langkah, tidur, screen time, history).
final activityDataProvider = StateProvider<ActivityData>((ref) {
  return const ActivityData(
    steps: 3250,
    stepsGoal: 5000,
    sleepMinutes: 380, // 6 jam 20 menit = 380 menit
    screenTimeMinutes: 330, // 5 jam 30 menit = 330 menit
    stepsHistory: [1500, 2400, 3100, 4200, 3250, 2800],
    sleepHistory: [450, 360, 480, 330, 380, 420],
    screenTimeHistory: [270, 372, 300, 426, 330, 360],
  );
});

/// Provider untuk mengambil data FINDRISC terbaru dari SharedPreferences.
final findriscDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final score = prefs.getInt('findrisc_score') ?? 13;
  final category = prefs.getString('findrisc_category') ?? 'Sedang';
  return {'score': score, 'category': category};
});

/// Provider untuk mengambil nama user dari Supabase.
final userNameProvider = Provider<String>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  final name = user?.userMetadata?['name'] ?? user?.userMetadata?['full_name'];
  return name ?? 'Pemanasan';
});

/// Provider untuk mendeteksi apakah user sudah menyelesaikan tutorial Iloo.
final tutorialSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('tutorial_iloo_done') ?? false;
});

/// Provider untuk mendeteksi apakah dialog tutorial sedang terbuka.
final tutorialDialogShowingProvider = StateProvider<bool>((ref) => false);

/// Home dashboard screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Menampilkan tutorial Iloo jika user belum pernah menyelesaikannya
    ref.listen<AsyncValue<bool>>(tutorialSeenProvider, (prev, next) {
      next.whenData((seen) {
        if (!seen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showTutorialDialog(context, ref);
          });
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(ref),
              const SizedBox(height: 24),
              _buildRiskCard(ref),
              const SizedBox(height: 12),
              _buildScoreCard(ref),
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
              _buildActivityCards(ref),
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
              _buildChallengeCard(ref),
              const SizedBox(height: 24),
              _buildMoreButton(ref),
              const SizedBox(height: 90), // Jarak untuk floating bottom bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    final name = ref.watch(userNameProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hallo, $name!',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.error),
              onPressed: () => ref.read(authProvider.notifier).signOut(),
            ),
          ],
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

  Widget _buildRiskCard(WidgetRef ref) {
    final findriscData = ref.watch(findriscDataProvider);
    return findriscData.when(
      data: (data) {
        final category = data['category'] as String;
        return BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          backgroundColor: Colors.white,
          borderColor: Colors.white,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/home/kategori.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 56),
      error: (err, stack) => const SizedBox(height: 56),
    );
  }

  Widget _buildScoreCard(WidgetRef ref) {
    final findriscData = ref.watch(findriscDataProvider);
    return findriscData.when(
      data: (data) {
        final score = data['score'] as int;
        return BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          backgroundColor: Colors.white,
          borderColor: Colors.white,
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
                          color: const Color(0xFFFFB700),
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
      error: (err, stack) => const SizedBox(height: 80),
    );
  }

  Widget _buildActivityCards(WidgetRef ref) {
    final activity = ref.watch(activityDataProvider);

    // Format tanggal hari ini (contoh: 22/06/2026)
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    String formatSteps(int val) {
      if (val >= 1000) {
        final thousands = val ~/ 1000;
        final remainder = val % 1000;
        return '$thousands.${remainder.toString().padLeft(3, '0')}';
      }
      return val.toString();
    }

    return Column(
      children: [
        // 1. LANGKAH CARD
        _buildBentoActivityCard(
          iconPath: 'assets/images/home/footstep.svg',
          iconColor: const Color(0xFF24B35F),
          title: 'Langkah',
          titleColor: const Color(0xFF24B35F),
          dateStr: dateStr,
          richText: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black, fontSize: 13),
              children: [
                TextSpan(
                  text: formatSteps(activity.steps),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' / ${formatSteps(activity.stepsGoal)} ',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const TextSpan(
                  text: 'Jalan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          historyValues:
              activity.stepsHistory.map((s) => s / activity.stepsGoal).toList(),
          activeColor: const Color(0xFF24B35F),
        ),
        const SizedBox(height: 12),

        // 2. TIDUR CARD
        _buildBentoActivityCard(
          iconPath: 'assets/images/home/sleep.svg',
          iconColor: const Color(0xFF007AFF),
          title: 'Tidur',
          titleColor: const Color(0xFF007AFF),
          dateStr: dateStr,
          richText: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black, fontSize: 13),
              children: [
                TextSpan(
                  text: '${activity.sleepMinutes ~/ 60}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(
                  text: 'j ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: '${activity.sleepMinutes % 60}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(
                  text: 'mnt',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Normalisasi berdasarkan target 8 jam tidur (480 menit)
          historyValues:
              activity.sleepHistory.map((m) => m / 480.0).toList(),
          activeColor: const Color(0xFF007AFF),
        ),
        const SizedBox(height: 12),

        // 3. SCREEN TIME CARD
        _buildBentoActivityCard(
          iconPath: 'assets/images/home/smartphone-device.svg',
          iconColor: const Color(0xFFFF3B30),
          title: 'Waktu Paparan Layar',
          titleColor: const Color(0xFFFF3B30),
          dateStr: dateStr,
          richText: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black, fontSize: 13),
              children: [
                TextSpan(
                  text: '${activity.screenTimeMinutes ~/ 60}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(
                  text: 'j ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: '${activity.screenTimeMinutes % 60}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(
                  text: 'mnt',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Normalisasi berdasarkan limit 8 jam (480 menit)
          historyValues:
              activity.screenTimeHistory.map((m) => m / 480.0).toList(),
          activeColor: const Color(0xFFFF3B30),
        ),
      ],
    );
  }

  Widget _buildBentoActivityCard({
    required String iconPath,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required String dateStr,
    required RichText richText,
    required List<double> historyValues,
    required Color activeColor,
  }) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      borderColor: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      iconPath,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                richText,
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.subtitleGray,
                ),
              ),
              const SizedBox(height: 8),
              MiniBarChart(
                values: historyValues,
                activeColor: activeColor,
                activeIndex: 4, // Kolom ke-5 adalah hari ini
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(WidgetRef ref) {
    final activity = ref.watch(activityDataProvider);
    final progress = (activity.steps / activity.stepsGoal).clamp(0.0, 1.0);

    return BentoCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      borderColor: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F9EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              'assets/images/home/footstep.svg',
              width: 32,
              height: 32,
              colorFilter: const ColorFilter.mode(
                Color(0xFF24B35F),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Berjalan 5.000 langkah',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF24B35F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Progress ${activity.steps} / ${activity.stepsGoal}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E5EA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          // Pindah ke tab Misi (index 1)
          ref.read(bottomNavIndexProvider.notifier).state = 1;
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cek selengkapnya',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showTutorialDialog(BuildContext context, WidgetRef ref) {
    if (ref.read(tutorialDialogShowingProvider)) return;

    ref.read(tutorialDialogShowingProvider.notifier).state = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8), // Scrim gelap transparan
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const IlooTutorialDialog();
      },
    ).then((_) {
      ref.read(tutorialDialogShowingProvider.notifier).state = false;
    });
  }
}

/// Dialog onboarding/tutorial karakter Iloo.
class IlooTutorialDialog extends ConsumerStatefulWidget {
  const IlooTutorialDialog({super.key});

  @override
  ConsumerState<IlooTutorialDialog> createState() => _IlooTutorialDialogState();
}

class _IlooTutorialDialogState extends ConsumerState<IlooTutorialDialog> {
  int _step = 1;

  Future<void> _completeTutorial(bool enableAi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_iloo_done', true);
    if (enableAi) {
      await prefs.setBool('ai_companion_active', true);
    }
    // Refresh provider agar dialog tidak dipanggil lagi
    ref.invalidate(tutorialSeenProvider);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    String assetPath;
    Widget content;

    if (_step == 1) {
      assetPath = 'assets/images/tutorial/iloo-greeting.svg';
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Halo, aku Iloo!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aku akan menjadi teman sehatmu selama menggunakan aplikasi ini.\n\n'
            'Aku akan membantu memantau kebiasaanmu dan memberikan saran yang sesuai dengan kondisi kesehatanmu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _step = 2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                'Lanjut',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_step == 2) {
      assetPath = 'assets/images/tutorial/iloo-kawai.svg';
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Agar aku bisa memberikan pengingat dan rekomendasi yang sesuai, aktifkan fitur Pendamping AI di pengaturan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _completeTutorial(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                'Aktifkan Sekarang',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _step = 3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                'Nanti Saja',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      assetPath = 'assets/images/tutorial/iloo-oke.svg';
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.6,
              ),
              children: [
                const TextSpan(text: 'Baik, mungkin lain waktu ya! Saat kamu siap, fitur Pendamping AI dapat diaktifkan kapan saja melalui '),
                TextSpan(
                  text: 'Pengaturan > Pendamping AI',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const TextSpan(text: ' untuk mendapatkan saran dan pengingat yang lebih personal.'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _completeTutorial(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                'Oke',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Iloo Character Image
                SvgPicture.asset(
                  assetPath,
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 16),
                // Text card
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget mini grafik batang (6 baris historis)
class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final Color activeColor;
  final int activeIndex;

  const MiniBarChart({
    super.key,
    required this.values,
    required this.activeColor,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (index) {
        final isHighlighted = index == activeIndex;
        // Tinggi bar grafis dinonormalisasi antara 12.0 s.d 60.0 px (lebih tinggi)
        final height = 12.0 + (values[index].clamp(0.0, 1.0) * 48.0);
        return Container(
          width: 6,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            color: isHighlighted ? activeColor : const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
