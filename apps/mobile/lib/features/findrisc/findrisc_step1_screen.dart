// findrisc_step1_screen.dart
//
// FINDRISC Step 1 — data fisik user: usia, tinggi, berat, lingkar pinggang.
//
// Purpose:
// Mengumpulkan data fisik user untuk menghitung BMI dan skor FINDRISC.
// BMI dihitung otomatis ketika tinggi & berat terisi.
//
// Used By:
// main.dart (flow: findrisc_intro → findrisc_step1 → findrisc_step2 → home)
//
// Depends On:
// flutter/material, flutter/services, flutter_svg, google_fonts,
// app_colors, app_spacing
//
// Impact:
// First-time FINDRISC questionnaire — step 1 of 2

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// FINDRISC Step 1 — data fisik (usia, tinggi, berat, lingkar pinggang).
class FindriscStep1Screen extends StatefulWidget {
  const FindriscStep1Screen({super.key, this.onComplete});

  /// Callback ketika user tap "Lanjut" dan form valid.
  final VoidCallback? onComplete;

  @override
  State<FindriscStep1Screen> createState() => _FindriscStep1ScreenState();
}

class _FindriscStep1ScreenState extends State<FindriscStep1Screen> {
  String? _ageGroup;
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();

  double? _bmi;
  String _bmiCategory = '-';

  static const _ageOptions = <String>[
    '< 45 tahun',
    '45 - 54 tahun',
    '55 - 64 tahun',
    '> 64 tahun',
  ];

  @override
  void initState() {
    super.initState();
    _heightCtrl.addListener(_recalculateBmi);
    _weightCtrl.addListener(_recalculateBmi);
    _waistCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    super.dispose();
  }

  void _recalculateBmi() {
    final heightCm = double.tryParse(_heightCtrl.text);
    final weightKg = double.tryParse(_weightCtrl.text);

    if (heightCm == null || weightKg == null || heightCm <= 0) {
      setState(() {
        _bmi = null;
        _bmiCategory = '-';
      });
      return;
    }

    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);

    setState(() {
      _bmi = bmi;
      _bmiCategory = _categoryFor(bmi);
    });
  }

  // Kemenkes BMI categories.
  String _categoryFor(double bmi) {
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 23) return 'Normal';
    if (bmi < 25) return 'Berat Badan Lebih';
    if (bmi < 30) return 'Obesitas I';
    return 'Obesitas II';
  }

  bool get _isFormValid =>
      _ageGroup != null &&
      _heightCtrl.text.isNotEmpty &&
      _weightCtrl.text.isNotEmpty &&
      _waistCtrl.text.isNotEmpty;

  void _onLanjutPressed() {
    if (!_isFormValid) return;
    widget.onComplete?.call();
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
              _buildAgeCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildHeightWeightCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildWaistCard(),
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
          'Tahap 1 dari 2',
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

  // ---------------------------------------------------------------------
  // Card 1 — Age
  // ---------------------------------------------------------------------
  Widget _buildAgeCard() {
    return _Card(
      children: [
        _buildQuestionLabel('1.', 'Berapa usia Anda?'),
        const SizedBox(height: AppSpacing.lg),
        ..._ageOptions.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _OptionTile(
              label: option,
              selected: _ageGroup == option,
              onTap: () => setState(() => _ageGroup = option),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Card 2 — Height / weight / BMI
  // ---------------------------------------------------------------------
  Widget _buildHeightWeightCard() {
    return _Card(
      children: [
        _buildQuestionLabel('2.', 'Berapa tinggi badan Anda?'),
        const SizedBox(height: AppSpacing.md),
        _SuffixField(controller: _heightCtrl, hint: 'misal 170', suffix: 'cm'),
        const SizedBox(height: 20),
        _buildQuestionLabel('3.', 'Berapa berat badan Anda?'),
        const SizedBox(height: AppSpacing.md),
        _SuffixField(controller: _weightCtrl, hint: 'misal 65', suffix: 'kg'),
        const SizedBox(height: 20),
        Text(
          'Indeks Massa Tubuh (BMI)',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ReadOnlyField(
          text: _bmi == null ? 'otomatis terisi' : _bmi!.toStringAsFixed(1),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Kategori',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ReadOnlyField(text: _bmi == null ? 'otomatis terisi' : _bmiCategory),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Card 3 — Waist circumference
  // ---------------------------------------------------------------------
  Widget _buildWaistCard() {
    return _Card(
      children: [
        _buildQuestionLabel('4.', 'Berapa lingkar pinggang Anda?'),
        const SizedBox(height: AppSpacing.md),
        _SuffixField(controller: _waistCtrl, hint: 'misal 80', suffix: 'cm'),
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
            color: isEnabled ? Colors.white : AppColors.textSecondary,
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
            color: selected ? AppColors.brand1 : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.brand1 : AppColors.border,
                  width: 2,
                ),
                color: Colors.white,
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brand1,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text input — pill style dengan unit suffix (cm, kg).
class _SuffixField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;

  const _SuffixField({
    required this.controller,
    required this.hint,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.placeholderGray,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            height: 20,
            width: 1,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Text(
            suffix,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Non-editable display field untuk BMI value & kategori.
class _ReadOnlyField extends StatelessWidget {
  final String text;
  const _ReadOnlyField({required this.text});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = text == 'otomatis terisi';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isPlaceholder ? const Color(0xFFEEEEEE) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w600,
          color: isPlaceholder
              ? AppColors.placeholderGray
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}
