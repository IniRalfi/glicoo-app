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

/// Provider daftar misi harian (mock/siap dihubungkan ke data asli).
final questListProvider = Provider<List<QuestItem>>((ref) {
  return const [
    QuestItem(
      title: 'Bergerak Lebih Banyak',
      description: 'Capai 5.000 langkah hari ini',
      points: '+10 Point',
      statusText: 'Progress 3250 / 5000',
      isCompleted: false,
      progress: 3250 / 5000,
      iconPath: 'assets/images/home/footstep.svg',
      themeColor: Color(0xFF24B35F),
    ),
    QuestItem(
      title: 'Tidur Tepat Waktu',
      description: 'Tidur sebelum pukul 23.00 malam ini',
      points: '+10 Point',
      statusText: 'Belum Dimulai',
      isCompleted: false,
      progress: null,
      iconPath: 'assets/images/home/sleep.svg',
      themeColor: Color(0xFF007AFF),
    ),
    QuestItem(
      title: 'Kurangi Waktu Layar',
      description: 'Batasi screen time di bawah 6 jam hari ini',
      points: '+10 Point',
      statusText: 'Belum Dimulai',
      isCompleted: false,
      progress: null,
      iconPath: 'assets/images/home/smartphone-device.svg',
      themeColor: Color(0xFFFF3B30),
    ),
  ];
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAchievementBanner(),
              const SizedBox(height: 24),
              _buildFilterTabs(ref, activeFilter),
              const SizedBox(height: 20),
              _buildQuestList(filteredQuests),
              const SizedBox(height: 90), // Jarak untuk floating bottom bar
            ],
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

  Widget _buildAchievementBanner() {
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
              // Overlay Teks
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pencapaian',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '78/100',
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

  Widget _buildQuestList(List<QuestItem> quests) {
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
}
