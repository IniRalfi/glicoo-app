import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi Glico: Rametto One (judul) + Inter (body).
abstract final class AppTypography {
  static TextTheme textTheme = TextTheme(
    displayLarge: _titleStyle(32, FontWeight.w400),
    displayMedium: _titleStyle(28, FontWeight.w400),
    displaySmall: _titleStyle(24, FontWeight.w400),
    headlineLarge: _titleStyle(22, FontWeight.w400),
    headlineMedium: _titleStyle(20, FontWeight.w400),
    headlineSmall: _titleStyle(18, FontWeight.w400),
    titleLarge: _bodyStyle(18, FontWeight.w600),
    titleMedium: _bodyStyle(16, FontWeight.w600),
    titleSmall: _bodyStyle(14, FontWeight.w600),
    bodyLarge: _bodyStyle(16, FontWeight.w400),
    bodyMedium: _bodyStyle(14, FontWeight.w400),
    bodySmall: _bodyStyle(12, FontWeight.w400),
    labelLarge: _bodyStyle(14, FontWeight.w500),
    labelMedium: _bodyStyle(12, FontWeight.w500),
    labelSmall: _bodyStyle(11, FontWeight.w500),
  );

  static TextStyle _titleStyle(double size, FontWeight weight) {
    return GoogleFonts.rammettoOne(
      fontSize: size,
      fontWeight: weight,
      color: AppColors.textPrimary,
      height: 1.2,
    );
  }

  static TextStyle _bodyStyle(double size, FontWeight weight) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: AppColors.textPrimary,
      height: 1.5,
    );
  }
}
