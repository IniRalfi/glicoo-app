// findrisc_complete_screen.dart
//
// FINDRISC Completion screen — ditampilkan setelah user mengisi semua pertanyaan.
//
// Purpose:
// Memberi konfirmasi visual bahwa penilaian FINDRISC telah selesai.
//
// Used By:
// main.dart (flow: findrisc_step2 → findrisc_complete → home)
//
// Depends On:
// flutter/material, flutter_svg, google_fonts, app_colors, app_spacing
//
// Impact:
// Post-FINDRISC completion flow

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// FINDRISC completion screen — "Penilaian Selesai!".
class FindriscCompleteScreen extends StatelessWidget {
  const FindriscCompleteScreen({super.key, this.onComplete});

  /// Callback ketika user tap "Lanjutkan".
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

              // Glico end illustration — center
              SvgPicture.asset(
                'assets/images/findrisc/glicoo_end.svg',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              // Title: "Penilaian Selesai!" — Rammetto One
              Text(
                'Penilaian Selesai!',
                style: GoogleFonts.rammettoOne(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Button: "Lanjutkan"
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
                    'Lanjutkan',
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
