import 'package:flutter/material.dart';

/// Palet warna brand Glico dari Figma Variables.
///
/// Skala 1–10: orange → yellow. Warna #FFB700 (6) adalah primary.
abstract final class AppColors {
  // Brand scale (Figma Variables)
  static const Color brand1 = Color(0xFFFF7B00);
  static const Color brand2 = Color(0xFFFF8800);
  static const Color brand3 = Color(0xFFFF9500);
  static const Color brand4 = Color(0xFFFFA200);
  static const Color brand5 = Color(0xFFFFAA00);
  static const Color brand6 = Color(0xFFFFB700);
  static const Color brand7 = Color(0xFFFFC300);
  static const Color brand8 = Color(0xFFFFD000);
  static const Color brand9 = Color(0xFFFFDD00);
  static const Color brand10 = Color(0xFFFFEA00);

  static const Color primary = brand6;

  // Neutrals — belum ada di Figma, dipakai untuk layout minimalis
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFFFF5E6);
  static const Color border = Color(0xFFFFE8B3);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textOnPrimary = Color(0xFF1A1A1A);

  // Auth-specific neutrals (from Figma)
  static const Color subtitleGray = Color(0xFF9EA2AE);
  static const Color placeholderGray = Color(0xFF6D717F);
  static const Color linkGray = Color(0xFF8F8F8F);
  static const Color linkBlue = Color(0xFF0095FF);

  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
}
