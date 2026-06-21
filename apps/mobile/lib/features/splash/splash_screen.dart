import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';

/// Durasi splash screen sebelum navigasi otomatis.
const Duration _kSplashDuration = Duration(seconds: 3);

/// Durasi animasi fade in/out.
const Duration _kFadeDuration = Duration(milliseconds: 500);

/// Jarak floating logo naik-turun (dalam logical pixels).
const double _kFloatOffset = 8.0;

/// Durasi satu siklus floating (naik + turun).
const Duration _kFloatDuration = Duration(milliseconds: 1500);

/// Splash screen Glico — tampil saat aplikasi pertama kali dibuka.
///
/// [onInitializationComplete] dipanggil setelah splash selesai
/// (fade out selesai). Caller bertanggung jawab untuk navigate
/// ke layar berikutnya (onboarding / home).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onInitializationComplete});

  final VoidCallback? onInitializationComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: _kFloatDuration,
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -_kFloatOffset, end: _kFloatOffset)
        .animate(
          CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
        );

    // Trigger fade in pada frame berikutnya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isVisible = true);
    });

    // Auto-navigate setelah durasi splash
    Future.delayed(_kSplashDuration, _exitSplash);
  }

  Future<void> _exitSplash() async {
    if (!mounted) return;
    setState(() => _isVisible = false);

    // Tunggu fade out selesai sebelum navigate
    await Future<void>.delayed(_kFadeDuration);
    if (mounted) widget.onInitializationComplete?.call();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        duration: _kFadeDuration,
        opacity: _isVisible ? 1.0 : 0.0,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary, // #FFB700
                AppColors.brand8, // #FFD000
              ],
            ),
          ),
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: child,
              );
            },
            child: Center(
              child: SvgPicture.asset(
                'assets/images/glico_logo.svg',
                width: 1200,
                height: 1200,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
