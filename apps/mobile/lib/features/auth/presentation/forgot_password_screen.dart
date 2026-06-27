// forgot_password_screen.dart
//
// Purpose:
// Forgot password screen — email field + "Kirim tautan reset" button.
// Sends a password reset email via Supabase Auth.
//
// Used By:
// main.dart or login_screen.dart (navigated from "Lupa kata sandi?" link)
//
// Depends On:
// auth_provider.dart, app_colors.dart, app_spacing.dart, app_typography.dart
//
// Impact:
// Auth flow — password reset email

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'auth_provider.dart';

/// Screen lupa kata sandi — kirim email reset.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.onBack});

  /// Callback untuk kembali ke halaman login.
  final VoidCallback? onBack;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendReset() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .resetPassword(_emailController.text.trim());
    if (mounted) {
      setState(() => _success = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
    final errorMessage = authState.maybeWhen(
      error: (message) => message,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: _success
              ? _buildSuccessView()
              : _buildForm(isLoading, errorMessage),
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading, String? errorMessage) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // --- Title ---
          Text(
            'Lupa Kata Sandi',
            style: AppTypography.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Masukkan email Anda dan kami akan mengirim tautan untuk mereset kata sandi.',
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              color: AppColors.subtitleGray,
            ),
          ),

          const SizedBox(height: 32),

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

          const SizedBox(height: 8),

          // --- Error message ---
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                errorMessage,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // --- "Kirim tautan reset" button ---
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _onSendReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
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
                      'Kirim tautan reset',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),
        Text(
          'Email Terkirim!',
          style: AppTypography.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cek inbox email Anda untuk tautan reset kata sandi.',
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.bodyLarge?.copyWith(
            color: AppColors.subtitleGray,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: widget.onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              elevation: 0,
            ),
            child: Text(
              'Kembali ke Masuk',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
