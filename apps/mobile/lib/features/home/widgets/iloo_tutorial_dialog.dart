// Purpose:
// Dialog onboarding/tutorial karakter Iloo.
//
// Used By:
// home_screen.dart
//
// Depends On:
// flutter/material.dart
// flutter_svg/flutter_svg.dart
// google_fonts/google_fonts.dart
// hooks_riverpod/hooks_riverpod.dart
// shared_preferences/shared_preferences.dart
//
// Impact:
// Tampilan onboarding/tutorial Iloo saat user baru pertama kali masuk ke Home.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/activity_provider.dart';

class IlooTutorialDialog extends ConsumerStatefulWidget {
  const IlooTutorialDialog({super.key});

  static bool isShowing = false;

  @override
  ConsumerState<IlooTutorialDialog> createState() => _IlooTutorialDialogState();
}

class _IlooTutorialDialogState extends ConsumerState<IlooTutorialDialog> {
  int _step = 1;

  Future<void> _completeTutorial(bool enableAi) async {
    debugPrint('DEBUG: _completeTutorial called with enableAi = $enableAi');
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setBool('tutorial_iloo_done', true);
    debugPrint('DEBUG: tutorial_iloo_done set to true, success = $success');
    if (enableAi) {
      await prefs.setBool('ai_companion_active', true);
    }
    // Refresh provider agar dialog tidak dipanggil lagi
    ref.invalidate(tutorialSeenProvider);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    IlooTutorialDialog.isShowing = false;
    super.dispose();
  }

  Widget _buildPageIndicator(int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == (activeIndex - 1);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isActive ? 20.0 : 6.0,
          height: 6.0,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(3.0),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    String assetPath;
    String titleText = '';
    String descriptionText = '';
    Widget? customDescription;
    Widget buttonWidget;

    if (_step == 1) {
      assetPath = 'assets/images/tutorial/iloo-greeting.svg';
      titleText = 'Halo, aku Iloo!';
      descriptionText = 'Aku akan menjadi teman sehatmu selama menggunakan aplikasi ini.\n\n'
          'Aku akan membantu memantau kebiasaanmu dan memberikan saran yang sesuai dengan kondisi kesehatanmu.';
      buttonWidget = SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            setState(() => _step = 2);
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
            'Lanjut',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else if (_step == 2) {
      assetPath = 'assets/images/tutorial/iloo-kawai.svg';
      titleText = 'Aktifkan Asisten';
      descriptionText = 'Agar aku bisa memberikan pengingat dan rekomendasi yang sesuai, aktifkan fitur Pendamping AI di pengaturan.';
      buttonWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _completeTutorial(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: Text(
                'Aktifkan Sekarang',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => _completeTutorial(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                'Nanti Saja',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      assetPath = 'assets/images/tutorial/iloo-oke.svg';
      titleText = 'Siap!';
      customDescription = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          children: [
            const TextSpan(text: 'Baik, mungkin lain waktu ya! Saat kamu siap, fitur Pendamping AI dapat diaktifkan kapan saja melalui '),
            TextSpan(
              text: 'Pengaturan > Pendamping AI',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const TextSpan(text: ' untuk mendapatkan saran dan pengingat yang lebih personal.'),
          ],
        ),
      );
      buttonWidget = SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => _completeTutorial(false),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          child: Text(
            'Oke',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Dialog(
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
              // Yellow Container wrapping Iloo character
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6), // Soft cream/yellow pastel color
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title text
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Description text
              customDescription ?? Text(
                descriptionText,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Page indicator dots
              _buildPageIndicator(_step),
              const SizedBox(height: 24),
              
              // Action button(s)
              buttonWidget,
            ],
          ),
        ),
      ),
    );
  }
}
