// findrisc_result_screen.dart
//
// FINDRISC Result screen — menampilkan hasil penilaian risiko diabetes.
//
// Purpose:
// Menampilkan skor, kategori risiko, dan faktor-faktor yang berkontribusi
// berdasarkan algoritma FINDRISC.
//
// Used By:
// main.dart (flow: findrisc_complete → findrisc_result → home)
//
// Depends On:
// flutter/material, flutter_svg, google_fonts, app_colors, app_spacing,
// domain/findrisc_data.dart
//
// Impact:
// Post-FINDRISC result display

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'domain/findrisc_data.dart';

/// FINDRISC Result screen — menampilkan hasil analisis risiko.
class FindriscResultScreen extends StatelessWidget {
  const FindriscResultScreen({super.key, required this.data, this.onComplete});

  /// Data FINDRISC lengkap yang sudah diisi user.
  final FindriscData data;

  /// Callback ketika user tap "Selesai".
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.lg),
              _buildResultIllustration(),
              const SizedBox(height: AppSpacing.xl),
              _buildScoreSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildRiskFactors(),
              const SizedBox(height: AppSpacing.lg),
              _buildRecommendation(),
              const SizedBox(height: AppSpacing.xl),
              _buildDoneButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultIllustration() {
    return SvgPicture.asset(
      'assets/images/findrisc/glicoo_result.svg',
      width: 160,
      height: 168,
      fit: BoxFit.contain,
    );
  }

  Widget _buildScoreSection() {
    return Column(
      children: [
        // "Risiko Anda:" label
        Text(
          'Risiko Anda:',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Kategori risiko — Rammetto One, warna kuning
        Text(
          data.kategori,
          style: GoogleFonts.rammettoOne(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Skor
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          child: Text(
            'Skor: ${data.totalSkor} | Probabilitas: ${data.probabilitas}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskFactors() {
    final factors = data.faktorPositif;

    if (factors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faktor yang perlu diperhatikan:',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...factors.map((f) => _FactorItem(faktor: f)),
      ],
    );
  }

  Widget _buildRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E6),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Rekomendasi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.rekomendasi,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onComplete,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.subtitleGray,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          elevation: 0,
        ),
        child: Text(
          'Selesai',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Menampilkan satu faktor risiko dengan bullet kuning.
class _FactorItem extends StatelessWidget {
  final FaktorRisiko faktor;

  const _FactorItem({required this.faktor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary, // yellow dot
            ),
          ),
          Expanded(
            child: Text(
              faktor.detail,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
