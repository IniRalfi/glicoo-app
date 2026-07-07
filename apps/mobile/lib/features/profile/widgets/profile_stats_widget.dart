// profile_stats_widget.dart
//
// Purpose:
// Widget untuk menampilkan data statistik kesehatan user:
// BMI, FINDRISC score, data dasar (usia, tinggi, berat, lingkar pinggang),
// dan status koneksi bot platform (WhatsApp/Telegram).
//
// Used By:
// profile_screen.dart
//
// Depends On:
// profile_provider, flutter_svg
//
// Impact:
// Health stats display, bot integration status

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../profile_provider.dart';
import 'bot_connection_widget.dart';

class ProfileStatsWidget extends ConsumerWidget {
  final int findriscScore;
  final String findriscCategory;
  final double waistCircumference;
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarEdit;

  const ProfileStatsWidget({
    super.key,
    required this.findriscScore,
    required this.findriscCategory,
    required this.waistCircumference,
    required this.onEditProfile,
    required this.onAvatarEdit,
  });

  double calculateBMI(double weight, double height) {
    if (height <= 0) return 0.0;
    final heightM = height / 100.0;
    return weight / (heightM * heightM);
  }

  Color _getRiskColor(String category) {
    final catLower = category.toLowerCase();
    if (catLower.contains('sangat tinggi')) return const Color(0xFFCC0000);
    if (catLower.contains('tinggi')) return const Color(0xFFFF3B30);
    if (catLower.contains('sedang')) return const Color(0xFFFF8800);
    if (catLower.contains('sedikit')) return const Color(0xFFFFB700);
    if (catLower.contains('rendah')) return const Color(0xFF24B35F);
    return const Color(0xFFFFB700);
  }

  String _getRiskTitle(String category) {
    final catLower = category.toLowerCase();
    if (catLower.contains('sangat tinggi')) return 'Sangat Tinggi';
    if (catLower.contains('tinggi')) return 'Tinggi';
    if (catLower.contains('sedikit')) return 'Sedikit Meningkat';
    if (catLower.contains('rendah')) return 'Rendah';
    if (catLower.contains('sedang')) return 'Sedang';
    return category;
  }

  Widget _buildBentoStatCard({
    required String title,
    required String value,
    required String unit,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final riskColor = _getRiskColor(findriscCategory);
    final riskTitle = _getRiskTitle(findriscCategory);
    final double bmi = calculateBMI(profileState.weight, profileState.height);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- RISIKO SAAT INI CARD ---
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Risiko Saat Ini',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
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
        ),

        // --- SKOR FINDRISC CARD ---
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skor FINDRISC',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$findriscScore',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // --- DATA DASAR SECTION ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data Dasar',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onEditProfile,
              child: Text(
                'Ubah',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0088FF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Bento Grid: 2x2 cards for Usia, Tinggi, Berat, Lingkar Pinggang
        Row(
          children: [
            Expanded(
              child: _buildBentoStatCard(
                title: 'Usia',
                value: '${profileState.age}',
                unit: 'Tahun',
                onTap: onEditProfile,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoStatCard(
                title: 'Tinggi Badan',
                value: '${profileState.height.toInt()}',
                unit: 'cm',
                onTap: onEditProfile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBentoStatCard(
                title: 'Berat Badan',
                value: '${profileState.weight.toInt()}',
                unit: 'kg',
                onTap: onEditProfile,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoStatCard(
                title: 'Lingkar Pinggang',
                value: '${waistCircumference.toInt()}',
                unit: 'cm',
                onTap: onEditProfile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Indeks Massa Tubuh (BMI) full-width blue card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0088FF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0088FF).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Indeks Massa Tubuh (BMI)',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                bmi > 0 ? bmi.toStringAsFixed(1) : '0.0',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        // --- PENDAMPING AI SECTION ---
        Text(
          'Pendamping AI',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hubungkan WhatsApp atau Telegram untuk menerima pengingat dan rekomendasi kesehatan dari Iloo.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        // Integrations Card (WhatsApp & Telegram statuses)
        _buildBotPlatformStatus(profileState),
        const SizedBox(height: 12),

        // Langkah Tautkan Akun & Dapatkan Kode OTP Card
        const BotConnectionWidget(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBotPlatformStatus(ProfileState profileState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // WhatsApp Row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Color(0xFF25D366),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'WhatsApp',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                profileState.botPlatform?.toUpperCase() == 'WHATSAPP'
                    ? 'Terhubung'
                    : 'Belum terhubung',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: profileState.botPlatform?.toUpperCase() == 'WHATSAPP'
                      ? const Color(0xFF34C759)
                      : AppColors.textSecondary,
                  fontWeight:
                      profileState.botPlatform?.toUpperCase() == 'WHATSAPP'
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F7)),
          ),
          // Telegram Row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.telegram,
                  color: Color(0xFF0088FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Telegram',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                profileState.botPlatform?.toUpperCase() == 'TELEGRAM'
                    ? 'Terhubung'
                    : 'Belum terhubung',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: profileState.botPlatform?.toUpperCase() == 'TELEGRAM'
                      ? const Color(0xFF34C759)
                      : AppColors.textSecondary,
                  fontWeight:
                      profileState.botPlatform?.toUpperCase() == 'TELEGRAM'
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
