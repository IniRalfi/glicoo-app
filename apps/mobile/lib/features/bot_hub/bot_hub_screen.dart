// bot_hub_screen.dart
//
// Bot Hub screen — placeholder
//
// Purpose:
// Menampilkan daftar bot AI yang terhubung (WhatsApp/Telegram).
//
// Used By:
// bottom_nav_shell.dart
//
// Depends On:
// flutter/material, app_colors
//
// Impact:
// Tab Bot Hub di bottom navigation

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Bot Hub screen — menampilkan daftar bot AI yang terhubung.
class BotHubScreen extends StatelessWidget {
  const BotHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Bot Hub',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy, size: 64, color: AppColors.brand5),
            const SizedBox(height: 16),
            Text('Bot Hub', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Bot AI yang terhubung akan muncul di sini.',
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
