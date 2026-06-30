// profile_screen.dart
//
// Purpose:
// Display and edit user profile details, health stats (FINDRISC risk score),
// and configure application settings (background sync permission).
// Now refactored to delegate UI sections to dedicated widget files.
//
// Used By:
// bottom_nav_shell.dart
//
// Depends On:
// flutter/material, hooks_riverpod, shared_preferences, google_fonts, flutter_svg, image_picker
// widgets/bot_connection_widget, widgets/avatar_editor_widget, widgets/settings_widget, widgets/profile_stats_widget
//
// Impact:
// Profile tab, health score adjustments, background worker toggling.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/api_service.dart';
import '../../core/widgets/glico_loading.dart';
import 'profile_provider.dart';
import 'widgets/profile_stats_widget.dart';
import 'widgets/avatar_editor_widget.dart';
import 'widgets/settings_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _bgSyncEnabled = true;

  // Local settings for FINDRISC & Custom Avatar
  // [WHY] Initial defaults harus cocok dgn SharedPreferences defaults biar ga mismatch dgn Home
  int _findriscScore = 0;
  String _findriscCategory = 'Belum Tes';
  double _waistCircumference = 0.0;
  String _avatarBgColor = '0xFFFFB700';
  String _avatarAssetPath = 'assets/images/bothub/pp_iloo.svg';
  String? _avatarFilePath;
  String _avatarType = 'asset';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // [ID] Load dari SharedPreferences terlebih dahulu
    // [EN] Load from SharedPreferences first
    if (mounted) {
      setState(() {
        _bgSyncEnabled = prefs.getBool('bg_sync_enabled') ?? true;
        _findriscScore = prefs.getInt('findrisc_score') ?? 0;
        _findriscCategory = prefs.getString('findrisc_category') ?? 'Belum Tes';
        _waistCircumference = prefs.getDouble('lingkar_pinggang_cm') ?? 0.0;
        _avatarBgColor = prefs.getString('avatar_bg_color') ?? '0xFFFFB700';
        _avatarAssetPath =
            prefs.getString('avatar_asset_path') ??
            'assets/images/bothub/pp_iloo.svg';
        _avatarFilePath = prefs.getString('avatar_file_path');
        _avatarType = prefs.getString('avatar_type') ?? 'asset';
      });
    }

    // [ID] Jika FINDRISC kosong di SharedPreferences, fetch dari API
    // [WHY] Bug: Setelah logout/ganti akun, prefs.clear() menghapus semua data
    // tapi ProfileScreen tidak re-fetch dari API
    // [EN] If FINDRISC is empty in SharedPreferences, fetch from API
    if (_findriscScore == 0 && _findriscCategory == 'Belum Tes') {
      try {
        final profileData = await ref.read(apiServiceProvider).getUserProfile();
        final riskScore =
            (profileData['risk_score'] as num?)?.toDouble() ?? 0.0;
        final riskCategory =
            (profileData['risk_category'] as String?) ?? 'Belum Tes';

        if (riskScore > 0) {
          // [ID] Ambil category langsung dari API response
          // [EN] Get category directly from API response
          // [WHY] Backend sudah hitung category, tidak perlu kalkulasi ulang di client

          // Update SharedPreferences untuk cache
          await prefs.setInt('findrisc_score', riskScore.toInt());
          await prefs.setString('findrisc_category', riskCategory);

          // Update UI
          if (mounted) {
            setState(() {
              _findriscScore = riskScore.toInt();
              _findriscCategory = riskCategory;
            });
          }
        }
      } catch (e) {
        // Ignore error - tetap gunakan default
        debugPrint('[ProfileScreen] Error fetching FINDRISC from API: $e');
      }
    }
  }

  void _showAvatarEditorBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarEditorWidget(
        currentBgColor: _avatarBgColor,
        currentAssetPath: _avatarAssetPath,
        currentFilePath: _avatarFilePath,
        currentType: _avatarType,
        onSaved: _loadSettings,
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsWidget(
        initialBgSyncEnabled: _bgSyncEnabled,
        onSettingsChanged: _loadSettings,
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, ProfileState state) {
    final nameController = TextEditingController(text: state.name);
    final phoneController = TextEditingController(text: state.phoneNumber);
    final ageController = TextEditingController(
      text: state.age > 0 ? state.age.toString() : '',
    );
    final weightController = TextEditingController(
      text: state.weight > 0 ? state.weight.toString() : '',
    );
    final heightController = TextEditingController(
      text: state.height > 0 ? state.height.toString() : '',
    );
    final waistController = TextEditingController(
      text: _waistCircumference > 0
          ? _waistCircumference.toInt().toString()
          : '98',
    );
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
                          color: const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ubah Profil & Data Kesehatan',
                      style: GoogleFonts.inter(
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Tinggi (cm)',
                              hintText: 'Tinggi',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Berat (kg)',
                              hintText: 'Berat',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: waistController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Lingkar Pinggang (cm)',
                              hintText: 'Lingkar',
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
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: SwitchListTile(
                        value: hasFamilyHistory,
                        onChanged: (val) {
                          setModalState(() {
                            hasFamilyHistory = val;
                          });
                        },
                        title: Text(
                          'Riwayat Diabetes Keluarga',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Kakek, nenek, orang tua, atau saudara kandung dengan diabetes.',
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        activeThumbColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        final age = int.tryParse(ageController.text) ?? 0;
                        final weight =
                            double.tryParse(weightController.text) ?? 0.0;
                        final height =
                            double.tryParse(heightController.text) ?? 0.0;
                        final waist =
                            double.tryParse(waistController.text) ?? 98.0;

                        final success = await ref
                            .read(profileNotifierProvider.notifier)
                            .updateProfile(
                              name: nameController.text.trim(),
                              phoneNumber: phoneController.text.trim(),
                              age: age,
                              weight: weight,
                              height: height,
                              hasFamilyHistory: hasFamilyHistory,
                            );

                        if (success) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setDouble('lingkar_pinggang_cm', waist);
                          await _loadSettings();

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Profil & Data Kesehatan berhasil diperbarui! ✓',
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
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
                          : Text(
                              'Simpan Perubahan',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.rammettoOne(fontSize: 28, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.black,
              size: 28,
            ),
            onPressed: _showSettingsBottomSheet,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: profileState.isLoading
          ? const GlicoLoadingOverlay(
              title: 'Memuat Profil...',
              subtitle: 'Menghubungkan ke server Glicoo',
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(profileNotifierProvider.notifier).loadProfile();
                await _loadSettings();
              },
              color: AppColors.brand1,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                children: [
                  // --- PROFILE USER INFO ROW (TAP TO EDIT NAME/BASIC STATS) ---
                  GestureDetector(
                    onTap: () => _showEditProfileDialog(context, profileState),
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          // Avatar Circle
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: _showAvatarEditorBottomSheet,
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(_avatarBgColor)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child:
                                        _avatarType == 'file' &&
                                            _avatarFilePath != null
                                        ? Image.file(
                                            File(_avatarFilePath!),
                                            fit: BoxFit.cover,
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SvgPicture.asset(
                                              _avatarAssetPath,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              // Small Edit Icon
                              GestureDetector(
                                onTap: _showAvatarEditorBottomSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ],
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
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profileState.email,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- STATS & BOT CONNECTION SECTION ---
                  ProfileStatsWidget(
                    findriscScore: _findriscScore,
                    findriscCategory: _findriscCategory,
                    waistCircumference: _waistCircumference,
                    onEditProfile: () =>
                        _showEditProfileDialog(context, profileState),
                    onAvatarEdit: _showAvatarEditorBottomSheet,
                  ),
                ],
              ),
            ),
    );
  }
}
