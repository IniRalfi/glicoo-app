// findrisc_step2_screen.dart
//
// FINDRISC Step 2 — pertanyaan gaya hidup dan riwayat kesehatan.
//
// Purpose:
// Mengumpulkan data gaya hidup dan riwayat kesehatan untuk menghitung skor FINDRISC.
//
// Used By:
// main.dart (flow: findrisc_step1 → findrisc_step2 → findrisc_complete → result → home)
//
// Depends On:
// flutter/material, flutter_svg, google_fonts, app_colors, app_spacing, domain/findrisc_data.dart
//
// Impact:
// First-time FINDRISC questionnaire — step 2 of 2

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'domain/findrisc_data.dart';

/// FINDRISC Step 2 — pertanyaan gaya hidup dan riwayat kesehatan.
class FindriscStep2Screen extends StatefulWidget {
  const FindriscStep2Screen({
    super.key,
    required this.age,
    required this.ageGroup,
    required this.tinggiCm,
    required this.beratKg,
    required this.lingkarPinggangCm,
    this.onComplete,
  });

  /// Data fisik dari step 1.
  final int age;
  final String ageGroup;
  final double tinggiCm;
  final double beratKg;
  final double lingkarPinggangCm;

  /// Callback ketika user tap "Lanjut" dan form valid.
  /// Mengembalikan data FINDRISC lengkap.
  final void Function(FindriscData)? onComplete;

  @override
  State<FindriscStep2Screen> createState() => _FindriscStep2ScreenState();
}

class _FindriscStep2ScreenState extends State<FindriscStep2Screen> {
  String? _q5; // aktivitas fisik
  String? _q6; // sayur/buah/beri
  String? _q7; // obat hipertensi
  String? _q8; // gula darah tinggi
  String? _q9; // riwayat keluarga diabetes

  bool get _isFormValid =>
      _q5 != null && _q6 != null && _q7 != null && _q8 != null && _q9 != null;

  void _onLanjutPressed() {
    if (!_isFormValid) return;

    final data = FindriscData(
      age: widget.age,
      ageGroup: widget.ageGroup,
      tinggiCm: widget.tinggiCm,
      beratKg: widget.beratKg,
      lingkarPinggangCm: widget.lingkarPinggangCm,
      aktivitasFisik: _q5!,
      konsumsiBuahSayur: _q6!,
      obatHipertensi: _q7!,
      riwayatGulaDarah: _q8!,
      riwayatKeluargaDM: _q9!,
    );

    widget.onComplete?.call(data);
  }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.lg),
              _buildMascotBubble(),
              const SizedBox(height: AppSpacing.xl),
              _Card(
                children: [
                  _buildQuestionLabel(
                    '5.',
                    'Apakah Anda melakukan aktivitas fisik minimal 30 menit setiap hari?',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _OptionTile(
                    label: 'Iya',
                    selected: _q5 == 'Iya',
                    onTap: () => setState(() => _q5 = 'Iya'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OptionTile(
                    label: 'Tidak',
                    selected: _q5 == 'Tidak',
                    onTap: () => setState(() => _q5 = 'Tidak'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Card(
                children: [
                  _buildQuestionLabel(
                    '6.',
                    'Apakah Anda mengonsumsi sayur, buah, atau beri setiap hari?',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _OptionTile(
                    label: 'Iya, setiap hari',
                    selected: _q6 == 'Iya, setiap hari',
                    onTap: () => setState(() => _q6 = 'Iya, setiap hari'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OptionTile(
                    label: 'Tidak setiap hari',
                    selected: _q6 == 'Tidak setiap hari',
                    onTap: () => setState(() => _q6 = 'Tidak setiap hari'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Card(
                children: [
                  _buildQuestionLabel(
                    '7.',
                    'Apakah Anda rutin mengonsumsi obat untuk tekanan darah tinggi (hipertensi)?',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _OptionTile(
                    label: 'Iya',
                    selected: _q7 == 'Iya',
                    onTap: () => setState(() => _q7 = 'Iya'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OptionTile(
                    label: 'Tidak',
                    selected: _q7 == 'Tidak',
                    onTap: () => setState(() => _q7 = 'Tidak'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Card(
                children: [
                  _buildQuestionLabel(
                    '8.',
                    'Apakah Anda pernah diketahui memiliki kadar gula darah tinggi?',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _OptionTile(
                    label: 'Iya',
                    selected: _q8 == 'Iya',
                    onTap: () => setState(() => _q8 = 'Iya'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OptionTile(
                    label: 'Tidak',
                    selected: _q8 == 'Tidak',
                    onTap: () => setState(() => _q8 = 'Tidak'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Card(
                children: [
                  _buildQuestionLabel(
                    '9.',
                    'Apakah ada anggota keluarga Anda yang didiagnosis diabetes?',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _OptionTile(
                    label: 'Tidak ada',
                    selected: _q9 == 'Tidak ada',
                    onTap: () => setState(() => _q9 = 'Tidak ada'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OptionTile(
                    label: 'Iya, kakek/nenek, paman, bibi, atau sepupu',
                    selected:
                        _q9 == 'Iya, kakek/nenek, paman, bibi, atau sepupu',
                    onTap: () => setState(
                      () => _q9 = 'Iya, kakek/nenek, paman, bibi, atau sepupu',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OptionTile(
                    label: 'Iya, orang tua, saudara kandung, atau anak',
                    selected:
                        _q9 == 'Iya, orang tua, saudara kandung, atau anak',
                    onTap: () => setState(
                      () => _q9 = 'Iya, orang tua, saudara kandung, atau anak',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildLanjutButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Findrisc',
          style: GoogleFonts.rammettoOne(
            fontSize: 36,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tahap 2 dari 2',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Mascot + speech bubble
  // ---------------------------------------------------------------------
  Widget _buildMascotBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/findrisc/glicoo_findrisc.svg',
          width: 72,
          height: 72,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Isi dengan sebenar-benarnya ya!',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionLabel(String number, String text) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        children: [
          TextSpan(text: '$number $text'),
          TextSpan(
            text: ' *',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CTA button
  // ---------------------------------------------------------------------
  Widget _buildLanjutButton() {
    final isEnabled = _isFormValid;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled ? _onLanjutPressed : null,
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
          'Lanjut',
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

// ===========================================================================
// Reusable pieces
// ===========================================================================

/// Rounded card untuk mengelompokkan pertanyaan.
class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Single selectable radio row — pill style.
class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.white,
                border: selected
                    ? null
                    : Border.all(color: AppColors.border, width: 2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
