import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/page_indicator.dart';
import '../../core/widgets/skip_button.dart';

/// Data untuk satu halaman onboarding.
class OnboardingPageData {
  const OnboardingPageData({
    required this.imageAsset,
    required this.title,
    required this.description,
    required this.isFirstPage,
    required this.isLastPage,
  });

  final String imageAsset;
  final String title;
  final String description;
  final bool isFirstPage;
  final bool isLastPage;
}

/// Halaman onboarding individual.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final OnboardingPageData data;
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header: splash_text.svg (tengah) + Skip button (kanan) ───
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  // Spacer kiri — sama lebar dengan SkipButton agar logo benar-benar tengah
                  const SizedBox(width: 72),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/splash/splash_text.png',
                        width: 110,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SkipButton(onPressed: onSkip),
                ],
              ),
            ),

            // ─── Ilustrasi ───
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: SvgPicture.asset(data.imageAsset, fit: BoxFit.contain),
                ),
              ),
            ),

            // ─── Page indicator (di bawah ilustrasi, di atas text) ───
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: PageIndicator(
                pageCount: totalPages,
                currentPage: currentPage,
              ),
            ),

            // ─── Text content ───
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Text(
                    data.title,
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    data.description,
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ─── Bottom buttons: Back ← + Lanjut ───
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Row(
                children: [
                  // Back button — filled #9EA2AE, 56x56, rounded.
                  // Disabled on first page (alpha 0.5).
                  Opacity(
                    opacity: data.isFirstPage ? 0.5 : 1.0,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: data.isFirstPage ? null : onBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9EA2AE),
                          disabledBackgroundColor: const Color(0xFF9EA2AE),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Lanjut button — expanded, white bold text
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          'Lanjut',
                          style: AppTypography.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}
