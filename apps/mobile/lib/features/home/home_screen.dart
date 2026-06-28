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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api_service.dart';
import '../../core/sync_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bento_card.dart';
import '../auth/presentation/auth_provider.dart';
import '../navigation/bottom_nav_shell.dart';
import '../quests/quests_screen.dart';
import 'widgets/iloo_tutorial_dialog.dart';

/// Data model untuk aktivitas harian.
class ActivityData {
  final int steps;
  final int stepsGoal;
  final int sleepMinutes;
  final int screenTimeMinutes;
  final int dailyCalories;
  final List<int> stepsHistory;
  final List<int> sleepHistory;
  final List<int> screenTimeHistory;

  const ActivityData({
    required this.steps,
    required this.stepsGoal,
    required this.sleepMinutes,
    required this.screenTimeMinutes,
    required this.dailyCalories,
    required this.stepsHistory,
    required this.sleepHistory,
    required this.screenTimeHistory,
  });
}

/// Provider state untuk data aktivitas harian (langkah, tidur, screen time, history).
class ActivityDataNotifier extends StateNotifier<ActivityData> {
  ActivityDataNotifier() : super(const ActivityData(
    steps: 0,
    stepsGoal: 5000,
    sleepMinutes: 0,
    screenTimeMinutes: 0,
    dailyCalories: 0,
    stepsHistory: [1500, 2400, 3100, 4200, 0, 2800],
    sleepHistory: [450, 360, 480, 330, 380, 420],
    screenTimeHistory: [270, 372, 300, 426, 0, 360],
  )) {
    loadDailyValues();
    _startTimer();
  }

  Timer? _timer;

  Future<void> loadDailyValues() async {
    final prefs = await SharedPreferences.getInstance();
    final steps = prefs.getInt('glico_daily_steps') ?? 0;
    final screenTime = prefs.getInt('glico_daily_screen_time') ?? 0;
    final sleepMinutes = prefs.getInt('glico_daily_sleep_minutes') ?? 0;
    final dailyCalories = prefs.getInt('glico_daily_calories') ?? 0;

    final stepsHistory = List<int>.from(state.stepsHistory);
    if (stepsHistory.length > 4) stepsHistory[4] = steps;

    final screenTimeHistory = List<int>.from(state.screenTimeHistory);
    if (screenTimeHistory.length > 4) screenTimeHistory[4] = screenTime;

    state = ActivityData(
      steps: steps,
      stepsGoal: state.stepsGoal,
      sleepMinutes: sleepMinutes,
      screenTimeMinutes: screenTime,
      dailyCalories: dailyCalories,
      stepsHistory: stepsHistory,
      sleepHistory: state.sleepHistory,
      screenTimeHistory: screenTimeHistory,
    );
  }

  /// [ID] Menyimpan durasi tidur ke SharedPreferences dan memperbarui state
  /// [EN] Saves sleep duration to SharedPreferences and updates state
  Future<void> setSleepMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('glico_daily_sleep_minutes', minutes);
    await loadDailyValues();
  }

  /// [ID] Menambahkan kalori harian ke SharedPreferences dan memperbarui state
  /// [EN] Adds daily calories to SharedPreferences and updates state
  Future<void> addCalories(int calories) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('glico_daily_calories') ?? 0;
    await prefs.setInt('glico_daily_calories', current + calories);
    await loadDailyValues();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => loadDailyValues());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activityDataProvider = StateNotifierProvider<ActivityDataNotifier, ActivityData>((ref) {
  return ActivityDataNotifier();
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
    // Menampilkan tutorial Iloo jika user belum pernah menyelesaikannya (saat inisialisasi / reset)
    ref.listen<AsyncValue<bool>>(tutorialSeenProvider, (prev, next) {
      next.whenData((seen) {
        debugPrint('DEBUG: tutorialSeenProvider listener triggered. seen = $seen');
        if (!seen) {
          final currentTab = ref.read(bottomNavIndexProvider);
          if (currentTab == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showTutorialDialog(context, ref);
            });
          }
        }
      });
    });

    // Juga tampilkan jika user berpindah kembali ke tab Beranda (index 0) dan belum melihat tutorial
    ref.listen<int>(bottomNavIndexProvider, (prev, next) {
      if (next == 0) {
        final seen = ref.read(tutorialSeenProvider).value ?? true;
        if (!seen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showTutorialDialog(context, ref);
          });
        }
      }
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
              const SizedBox(height: 16),
              _buildFoodLogCard(context, ref),
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
              _buildActivityCards(context, ref),
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
              _buildChallengeCard(context, ref),
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

  Widget _buildActivityCards(BuildContext context, WidgetRef ref) {
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
          onTap: () => _showSleepLogBottomSheet(context, ref),
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: BentoCard(
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
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questListProvider);

    return Column(
      children: List.generate(quests.length, (index) {
        final quest = quests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: BentoCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.white,
            borderColor: Colors.white,
            onTap: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Detail Misi',
                barrierColor: Colors.black.withValues(alpha: 0.5),
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) {
                  return QuestDetailDialog(quest: quest);
                },
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: quest.themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    quest.iconPath,
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(
                      quest.themeColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              quest.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: quest.themeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            quest.points,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quest.statusText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (quest.progress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: quest.progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE5E5EA),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              quest.themeColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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

  void _showSleepLogBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int hours = 7;
        int minutes = 0;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.nights_stay_rounded, color: Color(0xFF007AFF), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Catat Durasi Tidur',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan estimasi lama tidur berkualitas Anda tadi malam atau hari ini.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$hours',
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF007AFF),
                            ),
                          ),
                          Text(
                            'Jam',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                color: Colors.grey,
                                onPressed: hours > 0 ? () => setModalState(() => hours--) : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                color: const Color(0xFF007AFF),
                                onPressed: hours < 24 ? () => setModalState(() => hours++) : null,
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(width: 48),
                      Column(
                        children: [
                          Text(
                            minutes.toString().padLeft(2, '0'),
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF007AFF),
                            ),
                          ),
                          Text(
                            'Menit',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                color: Colors.grey,
                                onPressed: minutes > 0 ? () => setModalState(() => minutes -= 5) : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                color: const Color(0xFF007AFF),
                                onPressed: minutes < 55 ? () => setModalState(() => minutes += 5) : null,
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final totalMinutes = (hours * 60) + minutes;
                            await ref.read(activityDataProvider.notifier).setSleepMinutes(totalMinutes);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Durasi tidur berhasil disimpan.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Simpan',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTutorialDialog(BuildContext context, WidgetRef ref) {
    debugPrint('DEBUG: _showTutorialDialog called. isShowing: ${IlooTutorialDialog.isShowing}, provider: ${ref.read(tutorialDialogShowingProvider)}');
    if (ref.read(tutorialDialogShowingProvider) || IlooTutorialDialog.isShowing) {
      debugPrint('DEBUG: _showTutorialDialog aborted (already showing)');
      return;
    }

    ref.read(tutorialDialogShowingProvider.notifier).state = true;
    IlooTutorialDialog.isShowing = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5), // Scrim gelap transparan
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const IlooTutorialDialog();
      },
    ).then((_) {
      ref.read(tutorialDialogShowingProvider.notifier).state = false;
      IlooTutorialDialog.isShowing = false;
      debugPrint('DEBUG: _showTutorialDialog dismissed');
    });
  }

  Widget _buildFoodLogCard(BuildContext context, WidgetRef ref) {
    return BentoCard(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      borderColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SvgPicture.asset(
              'assets/images/home/food_banner.svg',
              fit: BoxFit.cover,
              height: 140,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catat Makanan Hari Ini',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ceritakan menu makanmu, lalu biarkan Iloo membantu menghitung kalori dan memberikan rekomendasi yang lebih sehat.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showFoodLogBottomSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9500),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Catat Makanan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  void _showFoodLogBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FoodLogBottomSheet(),
    );
  }
}

class FoodLogBottomSheet extends ConsumerStatefulWidget {
  const FoodLogBottomSheet({super.key});

  @override
  ConsumerState<FoodLogBottomSheet> createState() => _FoodLogBottomSheetState();
}

class _FoodLogBottomSheetState extends ConsumerState<FoodLogBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  // Analysis result fields
  int? _calories;
  String? _carbohydrateLevel;
  String? _sugarLevel;
  String? _proteinLevel;
  String? _aiFeedback;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to update button disabled state
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _submitFoodLog() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final syncManager = ref.read(syncManagerProvider);
      final apiService = ref.read(apiServiceProvider);
      
      final isOnline = await syncManager.isOnline();
      if (isOnline) {
        final res = await apiService.logFood(text);
        
        final calories = res['estimated_calories'] as int? ?? 0;
        final carbohydrateLevel = res['carbohydrate_level'] as String? ?? 'Sedang';
        final sugarLevel = res['sugar_level'] as String? ?? 'Sedang';
        final proteinLevel = res['protein_level'] as String? ?? 'Cukup';
        final aiFeedback = res['ai_feedback'] as String? ?? 'Makanan berhasil dianalisis.';

        // Update the calories in SharedPreferences for the Makan Lebih Bijak quest
        await ref.read(activityDataProvider.notifier).addCalories(calories);

        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _calories = calories;
          _carbohydrateLevel = carbohydrateLevel;
          _sugarLevel = sugarLevel;
          _proteinLevel = proteinLevel;
          _aiFeedback = aiFeedback;
        });
      } else {
        await syncManager.queueFoodLog(text);
        
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _calories = 0;
          _carbohydrateLevel = 'Sedang';
          _sugarLevel = 'Sedang';
          _proteinLevel = 'Cukup';
          _aiFeedback = 'Tersimpan luring. Analisis gizi akan diproses otomatis saat online!';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Widget _buildLevelBadge(String label, String type) {
    Color bgColor;
    Color textColor;

    if (type == 'Karbohidrat' || type == 'Gula') {
      if (label == 'Tinggi') {
        bgColor = const Color(0xFFFFE5E5);
        textColor = const Color(0xFFFF3B30);
      } else if (label == 'Sedang') {
        bgColor = const Color(0xFFFFF9E5);
        textColor = const Color(0xFFFF9500);
      } else {
        bgColor = const Color(0xFFE5F9EC);
        textColor = const Color(0xFF24B35F);
      }
    } else {
      if (label == 'Baik') {
        bgColor = const Color(0xFFE5F9EC);
        textColor = const Color(0xFF24B35F);
      } else if (label == 'Cukup') {
        bgColor = const Color(0xFFE5F5FF);
        textColor = const Color(0xFF007AFF);
      } else {
        bgColor = const Color(0xFFFFE5E5);
        textColor = const Color(0xFFFF3B30);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: _isSuccess
            ? _buildSuccessView()
            : _buildInputView(),
      ),
    );
  }

  Widget _buildInputView() {
    final isTextEmpty = _controller.text.trim().isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Catat Menu Makan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tuliskan menu makanan yang kamu konsumsi hari ini. Iloo akan memperkirakan kalori dan nutrisi, lalu memperbarui progres kesehatanmu.',
          style: GoogleFonts.inter(
            fontSize: 13, 
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          maxLines: 4,
          autofocus: true,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: 'Contoh: Nasi putih, ayam goreng, tumis kangkung, dan es teh manis.',
            hintStyle: GoogleFonts.inter(color: AppColors.placeholderGray, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_isLoading || isTextEmpty) ? null : _submitFoodLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9500),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Analisis Menu',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    final activity = ref.watch(activityDataProvider);
    final progress = (activity.dailyCalories / 2000.0).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Catat Menu Makan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 1. Blue Card "Estimasi Menu Hari Ini"
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Dark blue slate
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimasi Menu Hari Ini',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              
              // Metric: Tanggal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tanggal',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                  ),
                  Text(
                    _getFormattedDate(),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              
              // Metric: Kalori
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kalori',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                  ),
                  Text(
                    '$_calories kkal',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              
              // Metric: Karbohidrat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Karbohidrat',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                  ),
                  _buildLevelBadge(_carbohydrateLevel ?? 'Sedang', 'Karbohidrat'),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              
              // Metric: Gula
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gula',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                  ),
                  _buildLevelBadge(_sugarLevel ?? 'Sedang', 'Gula'),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              
              // Metric: Protein
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Protein',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                  ),
                  _buildLevelBadge(_proteinLevel ?? 'Cukup', 'Protein'),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 2. Yellow-Bordered Feedback Box with kkal_iloo.svg and AI Advice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F0), // Cream/yellow soft background
            border: Border.all(color: const Color(0xFFFF9500), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/images/home/kkal_iloo.svg',
                width: 64,
                height: 64,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _aiFeedback ?? 'Analisis makanan selesai.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 3. Quest Widget "Makan Lebih Bijak"
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC73E8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/misi/food.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFC73E8A),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Makan Lebih Bijak',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFC73E8A),
                              ),
                            ),
                            Text(
                              '+10 Point',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Catat menu makanan yang kamu konsumsi hari ini',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress ${activity.dailyCalories} / 2000 kkal',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (_calories != null && _calories! > 0)
                    Text(
                      '+$_calories kkal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC73E8A),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E5EA),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFC73E8A),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9500),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              'Selesai',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
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
