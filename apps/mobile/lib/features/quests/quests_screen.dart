// quests_screen.dart
//
// Quests screen — placeholder
//
// Purpose:
// Menampilkan daftar quests/gamifikasi kesehatan untuk user.
//
// Used By:
// bottom_nav_shell.dart
//
// Depends On:
// flutter/material, app_colors
//
// Impact:
// Tab Quests di bottom navigation

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Quests screen — menampilkan daftar tantangan kesehatan.
class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quests',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flag, size: 64, color: AppColors.brand3),
            const SizedBox(height: 16),
            Text('Quests', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Tantangan kesehatanmu akan muncul di sini.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
