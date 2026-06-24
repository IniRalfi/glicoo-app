// profile_screen.dart
//
// Purpose:
// Display and edit user profile details, health stats (FINDRISC risk score),
// and configure application settings (background sync permission).
//
// Used By:
// bottom_nav_shell.dart
//
// Depends On:
// flutter/material, hooks_riverpod, shared_preferences, workmanager, api_service, app_colors, bento_card
//
// Impact:
// Profile tab, health score adjustments, background worker toggling.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/sensor_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/glico_loading.dart';
import '../auth/presentation/auth_provider.dart';
import '../home/home_screen.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _bgSyncEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgSyncEnabled = prefs.getBool('bg_sync_enabled') ?? true;
    });
  }

  Future<void> _toggleBgSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bg_sync_enabled', value);
    setState(() {
      _bgSyncEnabled = value;
    });

    if (value) {
      // Re-initialize background sync
      await ref.read(sensorServiceProvider).initWorkmanager();
    } else {
      // Cancel background tasks
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
    }
  }

  Future<void> _resetFindrisc(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('findrisc_done');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('FINDRISC flag direset! Silakan restart aplikasi.'),
      ),
    );
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_done');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Onboarding flag direset! Silakan restart aplikasi.'),
      ),
    );
  }

  Future<void> _resetIlooTutorial(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tutorial_iloo_done');
    await prefs.remove('ai_companion_active');
    ref.invalidate(tutorialSeenProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tutorial Iloo direset! Silakan buka Beranda.'),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, ProfileState state) {
    final nameController = TextEditingController(text: state.name);
    final phoneController = TextEditingController(text: state.phoneNumber);
    final ageController = TextEditingController(text: state.age > 0 ? state.age.toString() : '');
    final weightController = TextEditingController(text: state.weight > 0 ? state.weight.toString() : '');
    final heightController = TextEditingController(text: state.height > 0 ? state.height.toString() : '');
    bool hasFamilyHistory = state.hasFamilyHistory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ubah Profil & Data Kesehatan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Masukkan nama lengkap',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor WhatsApp / Telegram',
                        hintText: 'Contoh: 628123456789',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Usia (tahun)',
                              hintText: 'Usia',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Tinggi (cm)',
                              hintText: 'Tinggi',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Berat (kg)',
                              hintText: 'Berat',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SwitchListTile(
                        value: hasFamilyHistory,
                        onChanged: (val) {
                          setModalState(() {
                            hasFamilyHistory = val;
                          });
                        },
                        title: const Text(
                          'Riwayat Diabetes Keluarga',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: const Text(
                          'Kakek, nenek, orang tua, atau saudara kandung dengan diabetes.',
                          style: TextStyle(fontSize: 11),
                        ),
                        activeThumbColor: AppColors.brand1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        final age = int.tryParse(ageController.text) ?? 0;
                        final weight = double.tryParse(weightController.text) ?? 0.0;
                        final height = double.tryParse(heightController.text) ?? 0.0;

                        final success = await ref.read(profileNotifierProvider.notifier).updateProfile(
                              name: nameController.text.trim(),
                              phoneNumber: phoneController.text.trim(),
                              age: age,
                              weight: weight,
                              height: height,
                              hasFamilyHistory: hasFamilyHistory,
                            );

                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Profil & Data Kesehatan berhasil diperbarui! ✓'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand1,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state.isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);

    // Dynamic Risk styling helper
    Color riskColor = AppColors.success;
    String riskTitle = 'Risiko Rendah';
    String riskAdvice = 'Skormu aman. Pertahankan gaya hidup aktif dan pola makan sehatmu!';

    if (profileState.riskScore >= 70) {
      riskColor = AppColors.error;
      riskTitle = 'Risiko Tinggi';
      riskAdvice = 'Sangat disarankan untuk mengurangi konsumsi gula dan rutin jalan kaki.';
    } else if (profileState.riskScore >= 35) {
      riskColor = AppColors.brand1; // Amber/Yellow
      riskTitle = 'Risiko Sedang';
      riskAdvice = 'Risiko sedang terdeteksi. Mulailah memantau screen time harian Anda.';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil Kesehatan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: profileState.isLoading
          ? const GlicoLoadingOverlay(
              title: 'Memuat Profil...',
              subtitle: 'Menghubungkan ke server Glicoo',
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(profileNotifierProvider.notifier).loadProfile(),
              color: AppColors.brand1,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                children: [
                  // --- KARTU UTAMA PROFIL BENTO ---
                  BentoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.brand1.withValues(alpha: 0.1),
                              child: Text(
                                profileState.name.isNotEmpty
                                    ? profileState.name[0].toUpperCase()
                                    : 'G',
                                style: const TextStyle(
                                  color: AppColors.brand1,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profileState.name.isNotEmpty
                                        ? profileState.name
                                        : 'Pengguna Glicoo',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profileState.email,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (profileState.phoneNumber.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${profileState.phoneNumber}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showEditProfileDialog(context, profileState),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Profil & Parameter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brand1,
                              side: const BorderSide(color: AppColors.brand1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- BENTO GRID: KESEHATAN & RISIKO ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kolom Kiri: Skor Risiko FINDRISC
                      Expanded(
                        child: BentoCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Risiko Diabetes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${profileState.riskScore.toInt()}%',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: riskColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  riskTitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: riskColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Kolom Kanan: Parameter Fisik
                      Expanded(
                        child: BentoCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Statistik Fisik',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildParamRow(Icons.cake_outlined, '${profileState.age} thn'),
                              const SizedBox(height: 8),
                              _buildParamRow(Icons.height_outlined, '${profileState.height.toInt()} cm'),
                              const SizedBox(height: 8),
                              _buildParamRow(Icons.monitor_weight_outlined, '${profileState.weight.toInt()} kg'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- ANJURAN BENTO ---
                  BentoCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white,
                    child: Row(
                      children: [
                        Icon(Icons.healing_outlined, color: riskColor, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saran Kesehatan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                riskAdvice,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- PENGATURAN BENTO ---
                  BentoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengaturan Aplikasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: _bgSyncEnabled,
                          onChanged: _toggleBgSync,
                          title: const Text(
                            'Lacak Latar Belakang',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: const Text(
                            'Membaca langkah kaki & waker sync saat aplikasi ditutup.',
                            style: TextStyle(fontSize: 11),
                          ),
                          activeThumbColor: AppColors.brand1,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- DEV / DEBUG TOOLS BENTO ---
                  ExpansionTile(
                    title: const Text(
                      'Developer Options',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    children: [
                      BentoCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _resetFindrisc(context),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Reset FINDRISC Flag'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brand1.withValues(alpha: 0.1),
                                foregroundColor: AppColors.brand1,
                                elevation: 0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _resetOnboarding(context),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Reset Onboarding Flag'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                                foregroundColor: AppColors.textSecondary,
                                elevation: 0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _resetIlooTutorial(context, ref),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Reset Tutorial Iloo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- KELUAR BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => ref.read(authProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Keluar Akun'),
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildParamRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
