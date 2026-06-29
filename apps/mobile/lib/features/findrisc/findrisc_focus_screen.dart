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
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'domain/findrisc_data.dart';

/// Halaman Fokus — memberikan motivasi setelah pengisian kuesioner risiko.
class FindriscFocusScreen extends StatefulWidget {
  const FindriscFocusScreen({
    super.key,
    this.data,
    this.category,
    this.onComplete,
  });

  /// Data FINDRISC jika tersedia dari flow kuesioner.
  final FindriscData? data;

  /// Kategori risiko spesifik jika diberikan.
  final String? category;

  /// Callback ketika user tap "Lanjut ke Beranda".
  final VoidCallback? onComplete;

  @override
  State<FindriscFocusScreen> createState() => _FindriscFocusScreenState();
}

class _FindriscFocusScreenState extends State<FindriscFocusScreen> {
  String? _loadedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.category == null && widget.data == null) {
      _loadSavedCategory();
    }
  }

  Future<void> _loadSavedCategory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loadedCategory = prefs.getString('findrisc_category');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cat =
        widget.category ?? widget.data?.kategori ?? _loadedCategory ?? 'Sedang';
    final catLower = cat.toLowerCase();

    String title = 'Fokus';
    String description =
        'Kabar baiknya, sebagian besar faktor risiko ini masih bisa diperbaiki melalui kebiasaan sehari-hari.';
    // [WHY] Selalu pake glicoo_end.svg untuk semua kategori — permintaan user.
    const String svgAsset = 'assets/images/findrisc/glicoo_end.svg';

    if (catLower.contains('sangat tinggi')) {
      title = 'Hadapi!';
      description =
          'Jangan khawatir, hasil ini bukan diagnosis diabetes. Namun, kondisi ini menunjukkan bahwa perubahan hidup dan pemantauan kesehatan perlu mulai dilakukan sejak sekarang.';
    } else if (catLower.contains('tinggi')) {
      title = 'Pasti Bisa!';
      description =
          'Risiko ini masih dapat diturunkan melalui perubahan gaya hidup yang lebih sehat dan konsisten.';
    } else if (catLower.contains('sedikit')) {
      title = 'Semangat!';
      description =
          'Kabar baiknya, perubahan kecil yang dilakukan secara konsisten dapat membantu menjaga kesehatan dan menurunkan risiko di kemudian hari.';
    } else if (catLower.contains('rendah')) {
      title = 'Pertahankan!';
      description =
          'Kondisi ini merupakan awal yang baik. Tetap pertahankan kebiasaan sehatmu agar risiko tetap rendah di masa mendatang.';
    }

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
                svgAsset,
                width: 200,
                height: 147,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              // Title — Rammetto One
              Text(
                title,
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
                description,
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
                  onPressed: widget.onComplete,
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
