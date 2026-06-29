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
// flutter/material, hooks_riverpod, shared_preferences, workmanager, api_service, app_colors, google_fonts, flutter_svg, image_picker
//
// Impact:
// Profile tab, health score adjustments, background worker toggling.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/sensor_service.dart';
import '../../core/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glico_loading.dart';
import '../../core/api_service.dart';
import '../../core/bot_link_exception.dart';
import '../auth/presentation/auth_provider.dart';
import '../home/providers/activity_provider.dart';
import 'profile_provider.dart';

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

  // OTP Link state
  String? _otpToken;
  String? _telegramLink;
  bool _isLoadingOtp = false;

  // Bot connection state
  bool _isBotConnected = false;
  bool _isDisconnecting = false;
  String? _connectedPlatform; // telegram/whatsapp
  String _selectedPlatform = 'telegram'; // default for new connections

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBotStatus();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
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
    }
  }

  Future<void> _saveAvatarSettings({
    required String type,
    required String bgColor,
    required String assetPath,
    String? filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_type', type);
    await prefs.setString('avatar_bg_color', bgColor);
    await prefs.setString('avatar_asset_path', assetPath);
    if (filePath != null) {
      await prefs.setString('avatar_file_path', filePath);
    } else {
      await prefs.remove('avatar_file_path');
    }
    await _loadSettings();
  }

  Future<void> _resetFindrisc(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('findrisc_done');
    await prefs.remove('findrisc_score');
    await prefs.remove('findrisc_category');
    await prefs.remove('lingkar_pinggang_cm');
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

  double calculateBMI(double weight, double height) {
    if (height <= 0) return 0.0;
    final heightM = height / 100.0;
    return weight / (heightM * heightM);
  }

  Future<void> _loadBotStatus() async {
    try {
      final connected = await ref.read(apiServiceProvider).getBotStatus();
      final platform = await ref
          .read(apiServiceProvider)
          .getConnectedPlatform();
      if (mounted) {
        setState(() {
          _isBotConnected = connected;
          _connectedPlatform = platform;
        });
      }
    } catch (_) {}
  }

  Future<void> _disconnectBot() async {
    final platformName = _connectedPlatform == 'whatsapp'
        ? 'WhatsApp'
        : 'Telegram';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Putuskan Koneksi Bot?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Setelah diputuskan, Iloo tidak bisa lagi membalas pesan $platformName kamu. Kamu bisa menghubungkan ulang kapan saja.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Putuskan',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDisconnecting = true);
    try {
      await ref.read(apiServiceProvider).disconnectBot();
      if (mounted) {
        setState(() {
          _isBotConnected = false;
          _isDisconnecting = false;
          _connectedPlatform = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bot berhasil diputus dari akun kamu.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDisconnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memutus koneksi: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _generateOtp() async {
    setState(() => _isLoadingOtp = true);
    try {
      final res = await ref
          .read(apiServiceProvider)
          .getBotLink(platform: _selectedPlatform);
      setState(() {
        _otpToken = res['token']?.toString();
        _telegramLink = res['telegramLink']?.toString();
        _isLoadingOtp = false;
      });
      _showOtpDialog();
    } on BotLinkException catch (e) {
      setState(() => _isLoadingOtp = false);
      if (mounted) {
        final otherPlatform = e.connectedPlatform ?? 'platform lain';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Sudah Terhubung',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Akun kamu sudah terhubung ke $otherPlatform. Putuskan koneksi dulu untuk menghubungkan ke platform lain.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingOtp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat OTP: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showOtpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Kode Verifikasi Iloo',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedPlatform == 'telegram'
                    ? 'Buka @glicoo_bot di Telegram, kirim "/start [kode]", atau klik tombol di bawah:'
                    : 'Kirim pesan "OTP [kode]" ke nomor WhatsApp bot Glicoo:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _otpToken ?? '------',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.brand1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        if (_otpToken != null) {
                          Clipboard.setData(ClipboardData(text: _otpToken!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kode OTP berhasil disalin!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Color(0xFF0088FF),
                      ),
                      label: Text(
                        'Salin Kode',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0088FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_otpToken != null && _selectedPlatform == 'telegram') ...[
                FilledButton.icon(
                  onPressed: () async {
                    final telegramUrl =
                        _telegramLink ??
                        'https://t.me/glicoo_bot?start=$_otpToken';
                    final uri = Uri.parse(telegramUrl);
                    try {
                      final success = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!success) {
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                      }
                    } catch (_) {
                      // Fallback ke browser jika gagal membuka aplikasi eksternal
                      try {
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Gagal membuka tautan Telegram: $e',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Hubungkan ke Telegram',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0088FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Kode ini berlaku selama 10 menit.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAvatarEditorBottomSheet() {
    String tempType = _avatarType;
    String tempBgColor = _avatarBgColor;
    String tempAssetPath = _avatarAssetPath;
    String? tempFilePath = _avatarFilePath;

    final List<String> colors = [
      '0xFFFFB700', // Yellow
      '0xFF0088FF', // Blue
      '0xFFFF2D55', // Red
      '0xFF34C759', // Green
      '0xFFAF52DE', // Purple
      '0xFFFF9500', // Orange
      '0xFF5AC8FA', // Light Teal
      '0xFF8E8E93', // Grey
    ];

    final List<String> assets = [
      'assets/images/bothub/pp_iloo.svg',
      'assets/images/tutorial/iloo-greeting.svg',
      'assets/images/tutorial/iloo-kawai.svg',
      'assets/images/tutorial/iloo-oke.svg',
      'assets/images/misi/iloo_walk.svg',
      'assets/images/misi/iloo_sleep.svg',
      'assets/images/misi/iloo_screen.svg',
      'assets/images/glico_logo.svg',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final previewColor = Color(int.parse(tempBgColor));
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24),
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
                    'Atur Avatar Kamu',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Avatar Preview
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: previewColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: tempType == 'file' && tempFilePath != null
                            ? Image.file(File(tempFilePath!), fit: BoxFit.cover)
                            : Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: SvgPicture.asset(
                                  tempAssetPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Background Colors Selection
                  Text(
                    'Warna Background',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: colors.length,
                      itemBuilder: (context, index) {
                        final hex = colors[index];
                        final isSelected = tempBgColor == hex;
                        final color = Color(int.parse(hex));
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempBgColor = hex;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Characters selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Karakter Iloo',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            setModalState(() {
                              tempType = 'file';
                              tempFilePath = pickedFile.path;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 16,
                        ),
                        label: Text(
                          'Pilih dari Galeri',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0088FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: assets.length,
                      itemBuilder: (context, index) {
                        final assetPath = assets[index];
                        final isSelected =
                            tempType == 'asset' && tempAssetPath == assetPath;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempType = 'asset';
                              tempAssetPath = assetPath;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0088FF)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              assetPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  FilledButton(
                    onPressed: () async {
                      await _saveAvatarSettings(
                        type: tempType,
                        bgColor: tempBgColor,
                        assetPath: tempAssetPath,
                        filePath: tempFilePath,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB700),
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Simpan Avatar',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSettingsBottomSheet() {
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
                      onChanged: (val) async {
                        await _toggleBgSync(val);
                        setModalState(() {});
                      },
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
                              onPressed: () => _resetFindrisc(context),
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
                              onPressed: () => _resetOnboarding(context),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Reset Onboarding Flag'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.textSecondary
                                    .withValues(alpha: 0.1),
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
                                NotificationService()
                                    .showInstantTestNotification();
                              },
                              icon: const Icon(
                                Icons.notifications_active_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Kirim Notifikasi Tes (Uji Coba)',
                              ),
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
          },
        );
      },
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

    // Dynamic Risk styling helper
    Color riskColor = const Color(0xFFFFB700); // Default Yellow
    String riskTitle = _findriscCategory;
    final catLower = _findriscCategory.toLowerCase();

    if (catLower.contains('sangat tinggi')) {
      riskColor = const Color(0xFFFF3B30); // Red
      riskTitle = 'Sangat Tinggi';
    } else if (catLower.contains('tinggi')) {
      riskColor = const Color(0xFFFF8800); // Orange
      riskTitle = 'Tinggi';
    } else if (catLower.contains('sedikit')) {
      riskColor = const Color(0xFF007AFF); // Blue
      riskTitle = 'Sedikit Meningkat';
    } else if (catLower.contains('rendah')) {
      riskColor = const Color(0xFF24B35F); // Green
      riskTitle = 'Rendah';
    } else if (catLower.contains('sedang')) {
      riskColor = const Color(0xFFFFB700); // Yellow
      riskTitle = 'Sedang';
    }

    final double bmi = calculateBMI(profileState.weight, profileState.height);

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

                  // --- RISIKO SAAT INI CARD ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Risiko Saat Ini',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/images/home/kategori.svg',
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(
                                  riskColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                riskTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- SKOR FINDRISC CARD ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Skor FINDRISC',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$_findriscScore',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- DATA DASAR SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Data Dasar',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _showEditProfileDialog(context, profileState),
                        child: Text(
                          'Ubah',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0088FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bento Grid: 2x2 cards for Usia, Tinggi, Berat, Lingkar Pinggang
                  Row(
                    children: [
                      Expanded(
                        child: _buildBentoStatCard(
                          title: 'Usia',
                          value: '${profileState.age}',
                          unit: 'Tahun',
                          onTap: () =>
                              _showEditProfileDialog(context, profileState),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBentoStatCard(
                          title: 'Tinggi Badan',
                          value: '${profileState.height.toInt()}',
                          unit: 'cm',
                          onTap: () =>
                              _showEditProfileDialog(context, profileState),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBentoStatCard(
                          title: 'Berat Badan',
                          value: '${profileState.weight.toInt()}',
                          unit: 'kg',
                          onTap: () =>
                              _showEditProfileDialog(context, profileState),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBentoStatCard(
                          title: 'Lingkar Pinggang',
                          value: '${_waistCircumference.toInt()}',
                          unit: 'cm',
                          onTap: () =>
                              _showEditProfileDialog(context, profileState),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Indeks Massa Tubuh (BMI) full-width blue card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0088FF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0088FF).withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Indeks Massa Tubuh (BMI)',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          bmi > 0 ? bmi.toStringAsFixed(1) : '0.0',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- PENDAMPING AI SECTION ---
                  Text(
                    'Pendamping AI',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hubungkan WhatsApp atau Telegram untuk menerima pengingat dan rekomendasi kesehatan dari Iloo.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Integrations Card (WhatsApp & Telegram statuses)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        // WhatsApp Row
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F8EF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.phone_android,
                                color: Color(0xFF25D366),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'WhatsApp',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Belum terhubung',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF2F2F7),
                          ),
                        ),
                        // Telegram Row
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE6F2FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.telegram,
                                color: Color(0xFF0088FF),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Telegram',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              profileState.phoneNumber.isNotEmpty
                                  ? 'Terhubung'
                                  : 'Belum terhubung',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: profileState.phoneNumber.isNotEmpty
                                    ? const Color(0xFF34C759)
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Langkah Tautkan Akun & Dapatkan Kode OTP Card
                  _buildOtpLinkingCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildBentoStatCard({
    required String title,
    required String value,
    required String unit,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpLinkingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Status Baris ---
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isBotConnected
                      ? AppColors.success
                      : const Color(0xFFD1D1D6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isBotConnected ? 'Bot Terhubung' : 'Bot Belum Terhubung',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isBotConnected
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isBotConnected) ...[
            // --- Status Terhubung ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _connectedPlatform == 'whatsapp'
                          ? 'Akun kamu sudah terhubung dengan Iloo di WhatsApp. Kamu bisa mengobrol dan mencatat makanan langsung dari sana!'
                          : 'Akun kamu sudah terhubung dengan Iloo di Telegram. Kamu bisa mengobrol dan mencatat makanan langsung dari sana!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.success,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isDisconnecting ? null : _disconnectBot,
              icon: _isDisconnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_off, size: 18),
              label: Text(
                'Putuskan Koneksi Bot',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ] else ...[
            // --- Status Belum Terhubung ---
            Text(
              'Pilih platform lalu dapatkan kode verifikasi untuk menghubungkan akun dengan Pendamping AI:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Platform Picker Chips
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.telegram, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Telegram',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    selected: _selectedPlatform == 'telegram',
                    onSelected: (selected) {
                      if (selected)
                        setState(() => _selectedPlatform = 'telegram');
                    },
                    selectedColor: const Color(
                      0xFF0088FF,
                    ).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF0088FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedPlatform == 'telegram'
                            ? const Color(0xFF0088FF)
                            : const Color(0xFFE5E5EA),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_android, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'WhatsApp',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    selected: _selectedPlatform == 'whatsapp',
                    onSelected: (selected) {
                      if (selected)
                        setState(() => _selectedPlatform = 'whatsapp');
                    },
                    selectedColor: const Color(
                      0xFF25D366,
                    ).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedPlatform == 'whatsapp'
                            ? const Color(0xFF25D366)
                            : const Color(0xFFE5E5EA),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _isLoadingOtp ? null : _generateOtp,
              icon: _isLoadingOtp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.key, size: 18),
              label: Text(
                'Dapatkan Kode OTP',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFB700),
                foregroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
