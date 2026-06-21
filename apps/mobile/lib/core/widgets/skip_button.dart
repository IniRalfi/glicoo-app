import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Tombol "Lewati" di kanan atas — background kuning muda, text kuning gelap.
class SkipButton extends StatelessWidget {
  const SkipButton({super.key, required this.onPressed, this.label = 'Lewati'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.brand3.withValues(alpha: 0.2), // kuning muda
        foregroundColor: AppColors.brand5, // kuning lebih gelap
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}
