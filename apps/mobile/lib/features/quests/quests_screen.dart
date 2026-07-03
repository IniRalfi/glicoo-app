// quests_screen.dart
//
// Quests screen — menampilkan daftar tantangan gamifikasi kesehatan.
//
// Purpose:
// Halaman daftar misi kesehatan harian beserta pencapaian skor kesehatan.
//
// Used By:
// bottom_nav_shell.dart
//
// Depends On:
// flutter/material, hooks_riverpod, app_colors, bento_card,
// flutter_svg, google_fonts
//
// Impact:
// Tab Quests di bottom navigation

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/bento_card.dart';

import '../home/providers/activity_provider.dart';

/// Filter status untuk Misi.
enum QuestFilter { semua, belumSelesai, sudahSelesai }

/// Provider state untuk menyimpan filter aktif saat ini.
final questFilterProvider = StateProvider<QuestFilter>(
  (ref) => QuestFilter.semua,
);

/// Model data untuk Misi/Quest.
class QuestItem {
  final String title;
  final String description;
  final String points;
  final String statusText;
  final bool isCompleted;
  final double? progress;
  final String iconPath;
  final Color themeColor;

  const QuestItem({
    required this.title,
    required this.description,
    required this.points,
    required this.statusText,
    required this.isCompleted,
    this.progress,
    required this.iconPath,
    required this.themeColor,
  });
}

/// Provider daftar misi harian terhubung ke sensor asli.
final questListProvider = Provider<List<QuestItem>>((ref) {
  final activityData = ref.watch(activityDataProvider);

  final steps = activityData.steps;
  final stepsGoal = activityData.stepsGoal;
  final stepsCompleted = steps >= stepsGoal;
  final stepsProgress = (steps / stepsGoal).clamp(0.0, 1.0);

  // Tidur Tepat Waktu: target 7 jam (420 menit) tidur berkualitas
  final sleepMinutes = activityData.sleepMinutes;
  final sleepCompleted = sleepMinutes >= 420;
  final sleepProgress = (sleepMinutes / 420).clamp(0.0, 1.0);

  // Kurangi Waktu Layar: target di bawah 6 jam (360 menit)
  final screenTime = activityData.screenTimeMinutes;
  final currentHour = DateTime.now().hour;
  // Dianggap tuntas sepenuhnya jika pemakaian <= 360 menit DAN sudah masuk malam hari (>= 21:00)
  final isNightTime = currentHour >= 21 || currentHour < 4;
  // [FIX] Hapus guard screenTime > 0 — screenTime=0 juga <= 360 (memenuhi target)
  final screenCompleted = screenTime <= 360 && isNightTime;
  final screenProgress = (screenTime / 360.0).clamp(0.0, 1.0);

  // Makan Lebih Bijak: target mencatat makanan hari ini (target 2000 kkal limit)
  final dailyCalories = activityData.dailyCalories;
  final foodCompleted = dailyCalories > 0;
  final foodProgress = (dailyCalories / 2000.0).clamp(0.0, 1.0);

  return [
    QuestItem(
      title: 'Bergerak Lebih Banyak',
      description: 'Capai 5.000 langkah hari ini',
      points: '+35 Point',
      statusText: stepsCompleted ? 'Selesai' : 'Progress $steps / $stepsGoal',
      isCompleted: stepsCompleted,
      progress: stepsProgress,
      iconPath: 'assets/images/home/footstep.svg',
      themeColor: const Color(0xFF24B35F),
    ),
    QuestItem(
      title: 'Tidur Tepat Waktu',
      description: 'Target tidur berkualitas 7 jam hari ini',
      points: '+25 Point',
      statusText: sleepCompleted
          ? 'Selesai'
          : 'Progress ${sleepMinutes ~/ 60}j ${sleepMinutes % 60}m / 7j',
      isCompleted: sleepCompleted,
      progress: sleepProgress,
      iconPath: 'assets/images/home/sleep.svg',
      themeColor: const Color(0xFF007AFF),
    ),
    QuestItem(
      title: 'Kurangi Waktu Layar',
      description: 'Batasi screen time di bawah 6 jam hari ini',
      points: '+20 Point',
      statusText: screenTime > 360
          ? 'Batas Terlampaui (${screenTime ~/ 60}j ${screenTime % 60}m)'
          : (screenCompleted
                ? 'Selesai (${screenTime ~/ 60}j ${screenTime % 60}m / 6j)'
                : 'Progress ${screenTime ~/ 60}j ${screenTime % 60}m / 6j'),
      isCompleted: screenCompleted,
      progress: screenProgress,
      iconPath: 'assets/images/home/smartphone-device.svg',
      themeColor: const Color(0xFFFF3B30),
    ),
    QuestItem(
      title: 'Makan Lebih Bijak',
      description: 'Catat menu makanan yang kamu konsumsi hari ini',
      points: '+20 Point',
      statusText: foodCompleted
          ? 'Selesai (Progress $dailyCalories / 2000 kkal)'
          : 'Progress $dailyCalories / 2000 kkal',
      isCompleted: foodCompleted,
      progress: foodProgress,
      iconPath: 'assets/images/misi/food.svg',
      themeColor: const Color(0xFFCB30E0),
    ),
  ];
});

/// Provider untuk menghitung Skor Kesehatan (0-100) secara dinamis.
final healthScoreProvider = Provider<int>((ref) {
  final activityData = ref.watch(activityDataProvider);

  // 1. Poin Langkah (Max 35 Poin)
  final steps = activityData.steps;
  final stepsGoal = activityData.stepsGoal;
  final double stepPoints = (stepsGoal > 0)
      ? ((steps / stepsGoal).clamp(0.0, 1.0) * 35.0)
      : 0.0;

  // 2. Poin Tidur (Max 25 Poin)
  // Target tidur 7 jam (420 menit)
  final sleepMinutes = activityData.sleepMinutes;
  final double sleepPoints = ((sleepMinutes / 420.0).clamp(0.0, 1.0) * 25.0);

  // 3. Poin Screen Time (Max 20 Poin)
  // Batas aman di bawah 6 jam (360 menit)
  final screenTime = activityData.screenTimeMinutes;
  double screenPoints = 20.0;
  if (screenTime > 360) {
    final overage = screenTime - 360;
    screenPoints = (1.0 - (overage / 360.0)).clamp(0.0, 1.0) * 20.0;
  } else if (screenTime == 0) {
    screenPoints = 0.0; // Base point
  }

  // 4. Poin Makan Lebih Bijak (Max 20 Poin)
  final dailyCalories = activityData.dailyCalories;
  final double foodPoints = dailyCalories > 0 ? 20.0 : 0.0;

  return (stepPoints + sleepPoints + screenPoints + foodPoints).round().clamp(
    0,
    100,
  );
});

/// Halaman Quests/Misi.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(questFilterProvider);
    final allQuests = ref.watch(questListProvider);

    // Menyaring misi berdasarkan filter aktif
    final filteredQuests = allQuests.where((quest) {
      switch (activeFilter) {
        case QuestFilter.belumSelesai:
          return !quest.isCompleted;
        case QuestFilter.sudahSelesai:
          return quest.isCompleted;
        case QuestFilter.semua:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh activity data untuk update quest progress
            ref.invalidate(activityDataProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildAchievementBanner(ref),
                const SizedBox(height: 24),
                _buildFilterTabs(ref, activeFilter),
                const SizedBox(height: 20),
                _buildQuestList(context, filteredQuests),
                const SizedBox(height: 90), // Jarak untuk floating bottom bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Misi Hari Ini',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selesaikan misi berikut untuk membantu membangun kebiasaan hidup yang lebih sehat.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBanner(WidgetRef ref) {
    final healthScore = ref.watch(healthScoreProvider);

    return AspectRatio(
      aspectRatio: 372 / 152,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: const Color(0xFF007AFF), // Fallback warna biru
          child: Stack(
            children: [
              // Background Pattern SVG (misi-bg.svg)
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/images/misi/misi-bg.svg',
                  fit: BoxFit.cover,
                ),
              ),
              // Overlay Teks & Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pencapaian',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$healthScore/100',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Skor Kesehatan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress Bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: healthScore / 100.0,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(WidgetRef ref, QuestFilter activeFilter) {
    return Row(
      children: [
        _buildFilterPill(
          ref,
          title: 'Semua',
          filter: QuestFilter.semua,
          activeFilter: activeFilter,
        ),
        const SizedBox(width: 8),
        _buildFilterPill(
          ref,
          title: 'Belum Selesai',
          filter: QuestFilter.belumSelesai,
          activeFilter: activeFilter,
        ),
        const SizedBox(width: 8),
        _buildFilterPill(
          ref,
          title: 'Sudah Selesai',
          filter: QuestFilter.sudahSelesai,
          activeFilter: activeFilter,
        ),
      ],
    );
  }

  Widget _buildFilterPill(
    WidgetRef ref, {
    required String title,
    required QuestFilter filter,
    required QuestFilter activeFilter,
  }) {
    final isActive = filter == activeFilter;
    return GestureDetector(
      onTap: () {
        ref.read(questFilterProvider.notifier).state = filter;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : const Color(0xFFE5E5EA).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestList(BuildContext context, List<QuestItem> quests) {
    if (quests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Tidak ada misi pada kategori ini.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final quest = quests[index];
        return BentoCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.white,
          borderColor: Colors.white,
          onTap: () => _showQuestDetailDialog(context, quest),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: quest.themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      quest.iconPath,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        quest.themeColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      quest.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: quest.themeColor,
                      ),
                    ),
                  ),
                  // Points
                  Text(
                    quest.points,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Description
              Text(
                quest.description,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              // Subtext
              Text(
                quest.statusText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              if (quest.progress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: quest.progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E5EA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showQuestDetailDialog(BuildContext context, QuestItem quest) {
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
  }
}

class QuestDetailDialog extends StatelessWidget {
  final QuestItem quest;

  const QuestDetailDialog({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    Color bgIlooColor;
    String svgAssetPath;
    String contentText;
    EdgeInsetsGeometry containerPadding;
    AlignmentGeometry imageAlignment;
    double svgHeight;

    if (quest.title.contains('Bergerak')) {
      bgIlooColor = const Color(0xFF34C759);
      svgAssetPath = 'assets/images/misi/iloo_walk.svg';
      contentText =
          'Aktivitas fisik membantu tubuh mengontrol kadar gula darah dan mengurangi risiko Diabetes Melitus Tipe 2.';
      containerPadding = const EdgeInsets.only(top: 16, bottom: 12);
      imageAlignment = Alignment.bottomCenter;
      svgHeight = 120.0;
    } else if (quest.title.contains('Tidur')) {
      bgIlooColor = const Color(0xFF0088FF);
      svgAssetPath = 'assets/images/misi/iloo_sleep.svg';
      contentText =
          'Tidur yang cukup dan teratur membantu menjaga keseimbangan hormon serta sensitivitas insulin, sehingga dapat mengurangi risiko Diabetes Melitus Tipe 2.';
      containerPadding = const EdgeInsets.only(top: 16, bottom: 0);
      imageAlignment = Alignment.bottomCenter;
      svgHeight = 154.0;
    } else if (quest.title.contains('Makan')) {
      bgIlooColor = const Color(0xFFCB30E0);
      svgAssetPath = 'assets/images/misi/iloo_food.svg';
      contentText =
          'Mencatat makanan membantu Iloo memahami pola makanmu sehingga dapat memberikan rekomendasi yang lebih sesuai untuk mengurangi risiko Diabetes Melitus Tipe 2.';
      containerPadding = const EdgeInsets.only(top: 16, bottom: 0);
      imageAlignment = Alignment.bottomCenter;
      svgHeight = 154.0;
    } else {
      bgIlooColor = const Color(0xFFFF2D55);
      svgAssetPath = 'assets/images/misi/iloo_screen.svg';
      contentText =
          'Waktu paparan layar yang berlebihan sering kali berkaitan dengan perilaku sedentari dan kurangnya aktivitas fisik, yang dapat meningkatkan risiko Diabetes Melitus Tipe 2.';
      containerPadding = const EdgeInsets.only(top: 16, bottom: 0);
      imageAlignment = Alignment.bottomCenter;
      svgHeight = 154.0;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Image Container
            Container(
              width: 289,
              height: 170,
              decoration: BoxDecoration(
                color: bgIlooColor,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: containerPadding,
              child: Align(
                alignment: imageAlignment,
                child: SvgPicture.asset(
                  svgAssetPath,
                  height: svgHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Kenapa Penting?',
              textAlign: TextAlign.center,
              style: GoogleFonts.rammettoOne(fontSize: 22, color: Colors.black),
            ),
            const SizedBox(height: 12),
            // Description Content
            Text(
              contentText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Tutup Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
