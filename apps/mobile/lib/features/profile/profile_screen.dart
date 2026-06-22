// profile_screen.dart
//
// Profile screen — placeholder
//
// Purpose:
// Menampilkan profil user dan pengaturan aplikasi.
//
// Used By:
// bottom_nav_shell.dart
//
// Depends On:
// flutter/material, hooks_riverpod, app_colors, auth_provider
//
// Impact:
// Tab Profile di bottom navigation

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../auth/presentation/auth_provider.dart';

/// Profile screen — menampilkan profil user dan settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _resetFindrisc(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('findrisc_done');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('FINDRISC flag direset! Logout & login lagi untuk test.'),
      ),
    );
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_done');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Onboarding flag direset! Logout & login lagi untuk test.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.maybeWhen(
      authenticated: (userId) => userId,
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.brand1,
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              userId,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // --- Debug: Reset FINDRISC flag ---
            OutlinedButton.icon(
              onPressed: () => _resetFindrisc(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset FINDRISC'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand1,
                side: const BorderSide(color: AppColors.brand1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Debug: Reset Onboarding flag ---
            OutlinedButton.icon(
              onPressed: () => _resetOnboarding(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Onboarding'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
