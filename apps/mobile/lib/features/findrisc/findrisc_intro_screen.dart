// findrisc_intro_screen.dart
//
// FINDRISC Intro page — ditampilkan setelah login (first-time only).
//
// Purpose:
// Memperkenalkan user tentang kuesioner FINDRISC sebelum memulai pertanyaan.
// Halaman ini hanya muncul sekali (disimpan di SharedPreferences).
//
// Used By:
// main.dart (auth flow: login → findrisc_intro → home)
//
// Depends On:
// flutter/material, flutter_svg, google_fonts, app_colors, app_spacing
//
// Impact:
// First-time post-login experience

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// FINDRISC intro screen — memperkenalkan kuesioner FINDRISC.
class FindriscIntroScreen extends StatelessWidget {
  const FindriscIntroScreen({super.key, this.onComplete});

  /// Callback ketika user tap "Yuk, mulai sekarang!"
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Spacer atas
            const Spacer(flex: 2),

            // Glico FINDRISC illustration — center
            SvgPicture.asset(
              'assets/images/findrisc/glicoo_findrisc.svg',
              width: 200,
              height: 147,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 32),

            // Title: "Bentar..." — Rammetto One
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Bentar...',
                style: GoogleFonts.rammettoOne(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // Body text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Berikut akan ada beberapa pertanyaan yang akan membantuku memahami kondisi kesehatan dan tingkat risiko diabetesmu saat ini. Tenang saja, prosesnya hanya membutuhkan waktu sekitar 2 menit.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Spacer tengah
            const Spacer(flex: 3),

            // Thought bubble Iloo — "Isi dengan sebenar-benarnya ya!"
            // [WHY] Mengingatkan user untuk jujur mengisi kuesioner sebelum mulai
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Mascot Iloo
                  SvgPicture.asset(
                    'assets/images/bothub/pp_iloo.svg',
                    width: 56,
                    height: 56,
                  ),
                  const SizedBox(width: 4),
                  // Dot connectors (thought bubble style)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  // Speech bubble
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Isi dengan sebenar-benarnya ya!',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Button: "Yuk, mulai sekarang!" — kuning background, teks putih
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SizedBox(
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
                      borderRadius: BorderRadius.circular(
                        AppSpacing.buttonRadius,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Yuk, mulai sekarang!',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
