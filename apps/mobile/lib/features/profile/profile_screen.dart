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
import 'widgets/avatar_editor_widget.dart';
import 'widgets/edit_profile_bottom_sheet.dart';
import 'widgets/profile_stats_widget.dart';
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
  String _avatarBgColor = '0xFF0088FF';
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
        _avatarBgColor = prefs.getString('avatar_bg_color') ?? '0xFF0088FF';
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileBottomSheet(
          profileState: state,
          waistCircumference: _waistCircumference,
          onSaved: _loadSettings,
        ),
      ),
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
