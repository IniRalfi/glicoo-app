// register_screen.dart
//
// Purpose:
// Register screen — email + name + password + confirm password fields,
// Google OAuth, and navigation back to Login.
//
// Used By:
// auth_entry_screen.dart (or main.dart)
//
// Depends On:
// auth_provider.dart, app_colors.dart, app_spacing.dart, app_typography.dart
//
// Impact:
// main.dart auth flow — register → auth → home

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

/// Screen register dengan form email/nama/password/konfirmasi + Google OAuth.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.onNavigateToLogin});

  /// Callback navigasi ke halaman masuk.
  final VoidCallback? onNavigateToLogin;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _emailController.text.isNotEmpty &&
      _nameController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
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
          title: 'Daftar dengan Google',
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

                // --- "Daftar" title (Inter) ---
                Text(
                  'Daftar',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 4),

                // --- subtitle ---
                Text(
                  'Silakan isi data diri kamu!',
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: AppColors.subtitleGray,
                  ),
                ),

                const SizedBox(height: 28),

                // --- Email field ---
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

                // --- Nama field ---
                Text(
                  'Nama',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama',
                    hintStyle: TextStyle(color: AppColors.placeholderGray),
                  ),
                ),

                const SizedBox(height: 16),

                // --- Kata Sandi field ---
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
                    if (value.length < 6) {
                      return 'Kata sandi minimal 6 karakter';
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

                const SizedBox(height: 16),

                // --- Konfirmasi Kata Sandi field ---
                Text(
                  'Konfirmasi Kata Sandi',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi kata sandi tidak boleh kosong';
                    }
                    if (value != _passwordController.text) {
                      return 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Masukkan ulang kata sandi',
                    hintStyle: const TextStyle(
                      color: AppColors.placeholderGray,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.placeholderGray,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- "Daftar" button ---
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isFormValid && !isLoading)
                        ? _onRegister
                        : null,
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
                            'Daftar',
                            style: AppTypography.textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- "Atau daftar dengan" divider ---
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.subtitleGray),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Atau daftar dengan',
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

                // --- "Sudah punya akun? Masuk" ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onNavigateToLogin,
                      child: Text(
                        'Masuk',
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
