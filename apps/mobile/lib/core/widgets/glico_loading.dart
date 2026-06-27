// glico_loading.dart
//
// Animated loading widget — 2 SVG frames yang bergantian setiap 200ms.
//
// Purpose:
// Menampilkan loading animation dengan karakter Glico yang lucu,
// digunakan sebagai overlay saat proses fetch/loading berlangsung.
//
// Used By:
// main.dart (overlay), loading_provider.dart
//
// Depends On:
// flutter/material, flutter_svg, app_colors
//
// Impact:
// Tampilan loading di seluruh aplikasi

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Animated loading widget dengan 2 frame SVG.
///
/// Props:
/// - [title]: Judul loading (wajib, default: "Bentar yaa")
/// - [subtitle]: Teks tambahan di bawah judul (opsional)
class GlicoLoading extends StatefulWidget {
  const GlicoLoading({super.key, this.title = 'Bentar yaa', this.subtitle});

  /// Judul loading — ditampilkan di bawah animasi.
  final String title;

  /// Teks tambahan di bawah judul (opsional).
  final String? subtitle;

  @override
  State<GlicoLoading> createState() => _GlicoLoadingState();
}

class _GlicoLoadingState extends State<GlicoLoading> {
  int _currentFrame = 0;
  Timer? _timer;

  static const List<String> _frames = [
    'assets/images/loading/glico_1.svg',
    'assets/images/loading/glico_2.svg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _frames.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated SVG frames
          SizedBox(
            width: 148,
            height: 121,
            child: SvgPicture.asset(
              _frames[_currentFrame],
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            widget.title,
            style: GoogleFonts.rammettoOne(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          // Subtitle (optional)
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen loading overlay — semi-transparent background + GlicoLoading.
///
/// Props:
/// - [title]: Judul loading (wajib, default: "Bentar yaa")
/// - [subtitle]: Teks tambahan (opsional)
class GlicoLoadingOverlay extends StatelessWidget {
  const GlicoLoadingOverlay({
    super.key,
    this.title = 'Bentar yaa',
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: GlicoLoading(title: title, subtitle: subtitle),
    );
  }
}
