// login_screen.dart
//
// Purpose:
// Login screen — email + password with form validation, forgot password link,
// Google OAuth, and navigation to Register.
//
// Based on Figma node 100:2947 ("login-tidak-berisi").
//
// Used By:
// auth_entry_screen.dart (or main.dart directly)
//
// Depends On:
// auth_provider.dart, app_colors.dart, app_spacing.dart, app_typography.dart
//
// Impact:
// main.dart flow — login → auth → home

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/loading_provider.dart';
import 'auth_provider.dart';
import '../domain/auth_state.dart';

/// Screen login dengan form email/password + Google OAuth.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.onNavigateToRegister,
    this.onNavigateToForgotPassword,
  });

  /// Callback navigasi ke halaman daftar.
  final VoidCallback? onNavigateToRegister;

  /// Callback navigasi ke halaman lupa kata sandi.
  final VoidCallback? onNavigateToForgotPassword;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  Future<void> _onGoogleSignIn() async {
    ref.read(authProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    // Listen to auth state for error handling
    ref.listen<AuthState>(authProvider, (prev, next) {
      next.maybeWhen(
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          ref.read(authProvider.notifier).clearError();
        },
        orElse: () {},
      );
    });

    // Listen to auth state for global loading overlay (Google sign-in exchange token)
    ref.listen<AuthState>(authProvider, (prev, next) {
      final loading = ref.read(loadingProvider.notifier);
      next.maybeWhen(
        loading: () => loading.show(
          title: 'Masuk dengan Google',
          subtitle: 'Mohon tunggu sebentar...',
        ),
        authenticated: (_) => loading.hide(),
        error: (_) => loading.hide(),
        unauthenticated: () => loading.hide(),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // --- splash_text.png logo ---
                Center(
                  child: Image.asset(
                    'assets/images/splash/splash_text.png',
                    width: 110,
                    height: 29.64,
                  ),
                ),

                const SizedBox(height: 40),

                // --- "Masuk" title (Inter) ---
                Text(
                  'Masuk',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 4),

                // --- subtitle ---
                Text(
                  'Hai, selamat datang kembali!',
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: AppColors.subtitleGray,
                  ),
                ),

                const SizedBox(height: 28),

                // --- Email field label ---
                Text(
                  'Email',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Masukkan email',
                    hintStyle: TextStyle(color: AppColors.placeholderGray),
                  ),
                ),

                const SizedBox(height: 16),

                // --- Password field label ---
                Text(
                  'Kata Sandi',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi tidak boleh kosong';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Masukkan kata sandi',
                    hintStyle: const TextStyle(
                      color: AppColors.placeholderGray,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.placeholderGray,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                // --- "Lupa kata sandi?" ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onNavigateToForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Lupa kata sandi?',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.linkGray,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // --- "Lanjut" button ---
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isFormValid && !isLoading) ? _onLogin : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid
                          ? AppColors.primary
                          : AppColors.subtitleGray,
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
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Lanjut',
                            style: AppTypography.textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- "Atau masuk dengan" divider ---
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.subtitleGray),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Atau masuk dengan',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.linkGray,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.subtitleGray),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Google OAuth button ---
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _onGoogleSignIn,
                    icon: SvgPicture.asset(
                      'assets/images/logo_google.svg',
                      width: 20,
                      height: 20,
                    ),
                    label: Text(
                      'Google',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- "Belum punya akun? Daftar" ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onNavigateToRegister,
                      child: Text(
                        'Daftar',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.linkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
