// findrisc_focus_screen.dart
//
// Purpose:
// Menampilkan pesan motivasi/fokus setelah melihat hasil analisis risiko FINDRISC.
//
// Used By:
// main.dart (flow: findrisc_result → findrisc_focus → home)
//
// Depends On:
// flutter/material, flutter_svg, google_fonts, app_colors, app_spacing
//
// Impact:
// Post-result motivational screen

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Halaman Fokus — memberikan motivasi setelah pengisian kuesioner risiko.
class FindriscFocusScreen extends StatelessWidget {
  const FindriscFocusScreen({super.key, this.onComplete});

  /// Callback ketika user tap "Lanjut ke Beranda".
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Illustration
              SvgPicture.asset(
                'assets/images/findrisc/glicoo_findrisc.svg',
                width: 200,
                height: 147,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              // Title: "Fokus" — Rammetto One
              Text(
                'Fokus',
                style: GoogleFonts.rammettoOne(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Body: Centered Inter body text
              Text(
                'Kabar baiknya, sebagian besar faktor risiko ini masih bisa diperbaiki melalui kebiasaan sehari-hari.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Button: "Lanjut ke Beranda"
              SizedBox(
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
                    'Lanjut ke Beranda',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
