// settings_widget.dart
//
// Purpose:
// Bottom sheet widget untuk pengaturan aplikasi (background sync, developer options).
// Includes toggle for background activity tracking and debug reset functions.
//
// Used By:
// profile_screen.dart
//
// Depends On:
// sensor_service, workmanager, shared_preferences, notification_service
//
// Impact:
// App settings, background sync, developer debug tools

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/sensor_service.dart';
import '../../../core/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../home/providers/tutorial_provider.dart';

class SettingsWidget extends ConsumerStatefulWidget {
  final bool initialBgSyncEnabled;
  final VoidCallback onSettingsChanged;

  const SettingsWidget({
    super.key,
    required this.initialBgSyncEnabled,
    required this.onSettingsChanged,
  });

  @override
  ConsumerState<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends ConsumerState<SettingsWidget> {
  late bool _bgSyncEnabled;

  @override
  void initState() {
    super.initState();
    _bgSyncEnabled = widget.initialBgSyncEnabled;
  }

  Future<void> _toggleBgSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bg_sync_enabled', value);
    setState(() {
      _bgSyncEnabled = value;
    });

    if (value) {
      await ref.read(sensorServiceProvider).initWorkmanager();
    } else {
      await Workmanager().cancelAll();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Lacak aktivitas latar belakang diaktifkan.'
                : 'Lacak aktivitas latar belakang dimatikan.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: value ? AppColors.success : AppColors.textSecondary,
        ),
      );
      widget.onSettingsChanged();
    }
  }

  Future<void> _resetFindrisc() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('findrisc_done');
    await prefs.remove('findrisc_score');
    await prefs.remove('findrisc_category');
    await prefs.remove('lingkar_pinggang_cm');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('FINDRISC flag direset! Silakan restart aplikasi.'),
      ),
    );
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_done');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Onboarding flag direset! Silakan restart aplikasi.'),
      ),
    );
  }

  Future<void> _resetIlooTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tutorial_iloo_done');
    await prefs.remove('ai_companion_active');
    ref.read(tutorialDoneProvider.notifier).state = false;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tutorial Iloo direset! Silakan buka Beranda.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pengaturan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Lacak Latar Belakang (Switch)
            SwitchListTile(
              value: _bgSyncEnabled,
              onChanged: _toggleBgSync,
              title: Text(
                'Lacak Latar Belakang',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Membaca langkah kaki & sinkronisasi data saat aplikasi ditutup.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFFE5E5EA),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 24, thickness: 1),

            if (!kReleaseMode) ...[
              // Developer Options (ExpansionTile)
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    'Developer Options',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _resetFindrisc,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset FINDRISC Flag'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _resetOnboarding,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset Onboarding Flag'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textSecondary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppColors.textSecondary,
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _resetIlooTutorial,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset Tutorial Iloo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        NotificationService().showInstantTestNotification();
                      },
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      label: const Text('Kirim Notifikasi Tes (Uji Coba)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppColors.success,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, thickness: 1),
            ],

            // Keluar Akun (Logout Button)
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  'Keluar Akun',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
