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
  });

  final String imageAsset;
  final String title;
  final String description;
}

/// Onboarding screen — 3 halaman, hanya tampil first-time user.
///
/// Ilustrasi slide (PageView), teks fade in/out.
/// [onComplete] dipanggil saat user selesai onboarding.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  /// Durasi animasi fade teks.
  static const Duration _fadeDuration = Duration(milliseconds: 300);

  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      imageAsset: 'assets/images/splash/splash_1.svg',
      title: 'Kenali Risikomu',
      description:
          'Deteksi risiko diabetes lebih awal untuk langkah hidup yang lebih sehat.',
    ),
    OnboardingPageData(
      imageAsset: 'assets/images/splash/splash_2.svg',
      title: 'Pantau Setiap Hari',
      description:
          'Aktivitas, tidur, dan pola hidupmu terpantau dalam satu aplikasi.',
    ),
    OnboardingPageData(
      imageAsset: 'assets/images/splash/splash_3.svg',
      title: 'Pantau Teman Sehatmu',
      description:
          'Dapatkan pengingat dan saran personal untuk hidup lebih sehat.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() => widget.onComplete();

  bool get _isFirstPage => _currentPage == 0;

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header: splash_text.png (tengah) + Skip button (kanan) ───
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
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
                  SkipButton(onPressed: _skip),
                ],
              ),
            ),

            // ─── Ilustrasi (PageView — slides left/right) ───
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: _pageController,
                // WARNING: swipe disabled — navigasi pakai tombol saja
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: SvgPicture.asset(
                        _pages[index].imageAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── Page indicator ───
            PageIndicator(pageCount: _pages.length, currentPage: _currentPage),
            const SizedBox(height: AppSpacing.lg),

            // ─── Text content (fade in/out) ───
            Expanded(
              flex: 2,
              child: AnimatedSwitcher(
                duration: _fadeDuration,
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: Padding(
                  key: ValueKey<int>(_currentPage),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        page.title,
                        style: AppTypography.textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        page.description,
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Bottom buttons: Back ← + Lanjut ───
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  // Back button — filled #9EA2AE, 56x56, rounded.
                  // Disabled on first page (alpha 0.5).
                  Opacity(
                    opacity: _isFirstPage ? 0.5 : 1.0,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isFirstPage ? null : _previousPage,
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
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
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
