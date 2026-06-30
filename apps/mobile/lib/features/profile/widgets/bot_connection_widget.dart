// bot_connection_widget.dart
//
// Purpose:
// Widget untuk mengelola koneksi bot (WhatsApp/Telegram) dengan OTP flow.
// Includes status display, OTP generation, connection polling, and disconnect functionality.
//
// Used By:
// profile_screen.dart
//
// Depends On:
// api_service, profile_provider, bot_link_exception
//
// Impact:
// Bot connection management, OTP dialog, polling mechanism

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_service.dart';
import '../../../core/bot_link_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../profile_provider.dart';

class BotConnectionWidget extends ConsumerStatefulWidget {
  const BotConnectionWidget({super.key});

  @override
  ConsumerState<BotConnectionWidget> createState() =>
      _BotConnectionWidgetState();
}

class _BotConnectionWidgetState extends ConsumerState<BotConnectionWidget> {
  // OTP Link state
  String? _otpToken;
  String? _telegramLink;
  bool _isLoadingOtp = false;

  // Bot connection state
  bool _isDisconnecting = false;
  final String _selectedPlatform = 'telegram'; // default for new connections

  /// [ID] Baca status koneksi dari ProfileState
  /// [EN] Read connection status from ProfileState
  /// [WHY] Tidak pakai ref.watch() di getter biar aman dipanggil dari polling async
  bool _readBotConnected(ProfileState state) {
    return state.botChatId != null && state.botChatId!.isNotEmpty;
  }

  String _readConnectedPlatform(ProfileState state) {
    return state.botPlatform?.toLowerCase() ?? '';
  }

  Future<void> _disconnectBot() async {
    final profileState = ref.read(profileNotifierProvider);
    final connectedPlatform = _readConnectedPlatform(profileState);
    final platformName = connectedPlatform == 'whatsapp'
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

      // [ID] Reload ProfileState untuk update bot_chat_id & bot_platform ke NULL
      // [EN] Reload ProfileState to update bot_chat_id & bot_platform to NULL
      await ref.read(profileNotifierProvider.notifier).loadProfile();

      if (mounted) {
        setState(() {
          _isDisconnecting = false;
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

  /// [ID] Tampilkan dialog OTP dengan design baru sesuai screenshot (popup-aktivasi-ai)
  /// [EN] Show OTP dialog with new design matching screenshot (popup-aktivasi-ai)
  /// [WHY] Includes polling mechanism to detect connection asynchronously
  Future<void> _showOtpDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          actionsPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button (top-left)
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                'Aktifkan Pendamping AI',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Salin kode di bawah, lalu kirimkan ke bot WhatsApp atau Telegram untuk menghubungkan akunmu dengan Iloo.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // OTP Display + Copy Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _otpToken ?? '------',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_otpToken != null) {
                          Clipboard.setData(ClipboardData(text: _otpToken!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Kode OTP berhasil disalin!',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.content_copy, size: 18),
                      label: Text(
                        'Salin',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0088FF),
                        side: const BorderSide(color: Color(0xFF0088FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Timer (countdown)
              Text(
                'Kode kedaluwarsa dalam: 10:00 detik',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // WhatsApp Button (always show)
              if (_otpToken != null) ...[
                FilledButton.icon(
                  onPressed: () async {
                    // WhatsApp bot number: +62 896-7258-5765
                    final whatsappUrl =
                        'https://wa.me/6289672585765?text=OTP%20$_otpToken';
                    final uri = Uri.parse(whatsappUrl);
                    try {
                      final success = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!success) {
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal membuka WhatsApp: $e'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat, size: 20),
                  label: Text(
                    'Hubungkan ke WhatsApp',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 52),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 12),

                // Telegram Button
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
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal membuka Telegram: $e'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send, size: 20),
                  label: Text(
                    'Hubungkan ke Telegram',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0088FF), // Telegram blue
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 52),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    // [ID] Polling untuk check apakah user sudah connect di bot
    // [EN] Poll to check if user has connected via bot
    // [WHY] User mungkin sudah kirim OTP di WhatsApp/Telegram tapi belum close dialog
    // [CRITICAL] Polling mechanism yang baru diperbaiki untuk detect connection async
    if (mounted) {
      // Poll setiap 2 detik selama max 30 detik (15 attempts)
      int attempts = 0;
      const maxAttempts = 15;

      while (attempts < maxAttempts && mounted) {
        await Future.delayed(const Duration(seconds: 2));

        // Reload profile dari API
        await ref.read(profileNotifierProvider.notifier).loadProfile();
        final profileState = ref.read(profileNotifierProvider);
        final isConnected = _readBotConnected(profileState);

        // Jika sudah connected, break loop
        if (isConnected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✅ Bot berhasil terhubung!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          break;
        }

        attempts++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final isBotConnected = _readBotConnected(profileState);
    final connectedPlatform = _readConnectedPlatform(profileState);

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
                  color: isBotConnected
                      ? AppColors.success
                      : const Color(0xFFD1D1D6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isBotConnected ? 'Bot Terhubung' : 'Bot Belum Terhubung',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isBotConnected
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isBotConnected) ...[
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
                      connectedPlatform == 'whatsapp'
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
              'Hubungkan akun dengan Pendamping AI untuk mendapatkan pengingat harian dan tips kesehatan langsung di chat kamu!',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
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
                  : const Icon(Icons.link, size: 18),
              label: Text(
                'Hubungkan Bot',
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
