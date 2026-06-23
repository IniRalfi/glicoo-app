// bot_hub_screen.dart
//
// Purpose:
// High-fidelity Bot Hub screen featuring real-time connection status polling,
// deep-linking to Telegram/WhatsApp with OTP codes, and AI persona customization.
//
// Used By:
// bottom_nav_shell.dart
//
// Depends On:
// flutter/material, hooks_riverpod, url_launcher, supabase_flutter, api_service, env_config

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_service.dart';
import '../../core/env_config.dart';
import '../../core/theme/app_colors.dart';
import '../auth/presentation/auth_provider.dart';

// ── STATE DEFINITION ──

class BotHubState {
  final bool isLoading;
  final bool isGenerating;
  final String? phoneNumber;
  final String? connectedPlatform; // 'telegram' | 'whatsapp' | null
  final String? token;
  final String? telegramLink;
  final String? whatsappLink;
  final String aiPersona; // saved: 'santai' | 'tegas'
  final String pendingPersona; // selected but not yet applied

  final String? errorMessage;

  BotHubState({
    this.isLoading = false,
    this.isGenerating = false,
    this.phoneNumber,
    this.connectedPlatform,
    this.token,
    this.telegramLink,
    this.whatsappLink,
    this.aiPersona = 'santai',
    this.pendingPersona = 'santai',
    this.errorMessage,
  });

  bool get isConnected => phoneNumber != null && phoneNumber!.isNotEmpty;
  bool get personaChanged => pendingPersona != aiPersona;

  BotHubState copyWithNullable({
    bool? isLoading,
    bool? isGenerating,
    String? phoneNumber,
    bool clearPhone = false,
    String? connectedPlatform,
    bool clearPlatform = false,
    String? token,
    bool clearToken = false,
    String? telegramLink,
    String? whatsappLink,
    String? aiPersona,
    String? pendingPersona,
    String? errorMessage,
  }) {
    return BotHubState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      phoneNumber: clearPhone ? null : (phoneNumber ?? this.phoneNumber),
      connectedPlatform: clearPlatform
          ? null
          : (connectedPlatform ?? this.connectedPlatform),
      token: clearToken ? null : (token ?? this.token),
      telegramLink: telegramLink ?? this.telegramLink,
      whatsappLink: whatsappLink ?? this.whatsappLink,
      aiPersona: aiPersona ?? this.aiPersona,
      pendingPersona: pendingPersona ?? this.pendingPersona,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── STATE NOTIFIER ──

class BotHubNotifier extends StateNotifier<BotHubState> {
  BotHubNotifier(this._apiService) : super(BotHubState()) {
    _loadInitialData();
  }

  final ApiService _apiService;
  Timer? _pollingTimer;

  Future<void> _loadInitialData() async {
    state = state.copyWithNullable(isLoading: true);
    await checkConnectionStatus();
    final prefs = await SharedPreferences.getInstance();
    final persona = prefs.getString('ai_persona') ?? 'santai';
    state = state.copyWithNullable(
      isLoading: false,
      aiPersona: persona,
      pendingPersona: persona,
    );
  }

  /// [ID] Cek status koneksi ke database Supabase secara manual.
  /// [EN] Checks connection status from Supabase and infers platform from phone prefix.
  Future<void> checkConnectionStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('users')
          .select('phone_number, connected_platform')
          .eq('id', user.id)
          .maybeSingle();
      if (response != null) {
        final phone = response['phone_number'] as String?;
        // [ID] platform disimpan di DB jika ada, fallback ke deteksi nomor
        final platform = response['connected_platform'] as String?;
        state = state.copyWithNullable(
          phoneNumber: phone,
          clearPhone: phone == null,
          connectedPlatform: platform,
          clearPlatform: platform == null,
        );
        if (phone != null && phone.isNotEmpty) {
          _pollingTimer?.cancel();
          _pollingTimer = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching connection status: $e');
    }
  }

  /// [ID] Dapatkan token OTP verifikasi bot dari backend Elysia.
  /// [EN] Generates the bot verification OTP token from the Elysia backend.
  Future<void> generateBotToken() async {
    state = state.copyWithNullable(isGenerating: true, errorMessage: null);
    try {
      final res = await _apiService.getBotLink();
      final token = res['token'] as String;
      final telegramLink = res['telegramLink'] as String;
      final waNumber = EnvConfig.whatsappBotNumber;
      final waMessage = Uri.encodeComponent('start $token');
      final whatsappLink = 'https://wa.me/$waNumber?text=$waMessage';
      state = state.copyWithNullable(
        isGenerating: false,
        token: token,
        telegramLink: telegramLink,
        whatsappLink: whatsappLink,
      );
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => checkConnectionStatus(),
      );
    } catch (e) {
      state = state.copyWithNullable(
        isGenerating: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// [ID] Catat platform yang digunakan (telegram/whatsapp) saat user membuka deep link.
  /// [EN] Records which platform the user tapped to connect.
  Future<void> recordPlatformChoice(String platform) async {
    state = state.copyWithNullable(connectedPlatform: platform);
  }

  /// [ID] Memutuskan tautan bot.
  /// [EN] Disconnects the bot.
  Future<void> disconnectBot() async {
    state = state.copyWithNullable(isLoading: true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client
          .from('users')
          .update({'phone_number': null})
          .eq('id', user.id);
      state = state.copyWithNullable(
        isLoading: false,
        clearPhone: true,
        clearPlatform: true,
        clearToken: true,
      );
      _pollingTimer?.cancel();
    } catch (e) {
      state = state.copyWithNullable(
        isLoading: false,
        errorMessage: 'Gagal memutuskan bot: $e',
      );
    }
  }

  /// [ID] Mengubah pilihan persona sementara (belum tersimpan).
  /// [EN] Sets a pending persona selection (not saved yet).
  void setPendingPersona(String persona) {
    state = state.copyWithNullable(pendingPersona: persona);
  }

  /// [ID] Menyimpan persona yang dipilih ke SharedPreferences.
  /// [EN] Saves the selected persona to SharedPreferences.
  Future<void> applyPersona() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_persona', state.pendingPersona);
    state = state.copyWithNullable(aiPersona: state.pendingPersona);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

// ── PROVIDER ──

final botHubStateProvider =
    StateNotifierProvider.autoDispose<BotHubNotifier, BotHubState>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return BotHubNotifier(apiService);
    });

// ── SCREEN IMPLEMENTATION ──

class BotHubScreen extends ConsumerWidget {
  const BotHubScreen({super.key});

  Future<void> _launchUrlHelper(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi chat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(botHubStateProvider);
    final notifier = ref.read(botHubStateProvider.notifier);

    // Watch auth status to refresh if logged in
    ref.listen(authProvider, (prev, next) {
      next.maybeWhen(
        authenticated: (_) => notifier.checkConnectionStatus(),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Bot Hub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Segarkan Status',
            onPressed: notifier.checkConnectionStatus,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. STATUS KONEKSI PER PLATFORM
                  _buildPlatformStatusCard(
                    context,
                    'telegram',
                    state,
                    notifier,
                  ),
                  const SizedBox(height: 12),
                  _buildPlatformStatusCard(
                    context,
                    'whatsapp',
                    state,
                    notifier,
                  ),
                  const SizedBox(height: 16),

                  // 2. OTP CARD (jika belum terhubung)
                  if (!state.isConnected)
                    _buildLinkBotCard(context, state, notifier),

                  // 3. PERSONA SELECTOR
                  const SizedBox(height: 16),
                  _buildPersonaSelectorCard(context, state, notifier),

                  // 4. PETUNJUK
                  const SizedBox(height: 16),
                  _buildInstructionsCard(context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── WIDGET BUILDERS ──

  Widget _buildPlatformStatusCard(
    BuildContext context,
    String platform,
    BotHubState state,
    BotHubNotifier notifier,
  ) {
    final isTelegram = platform == 'telegram';
    // Connected = ada phone number DAN platform yang tersimpan cocok
    final isThisPlatformConnected =
        state.isConnected &&
        (state.connectedPlatform == platform ||
            state.connectedPlatform ==
                null); // fallback jika platform belum tersimpan di DB

    final platformName = isTelegram ? 'Telegram' : 'WhatsApp';
    final platformColor = isTelegram
        ? const Color(0xFF29B6F6)
        : const Color(0xFF43A047);
    final platformBgConnected = isTelegram
        ? const Color(0xFFE1F5FE)
        : const Color(0xFFE8F5E9);
    final platformBorderConnected = isTelegram
        ? const Color(0xFFB3E5FC)
        : const Color(0xFFC8E6C9);
    final platformIcon = isTelegram
        ? Icons.send_rounded
        : Icons.chat_bubble_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isThisPlatformConnected
            ? platformBgConnected
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isThisPlatformConnected
              ? platformBorderConnected
              : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isThisPlatformConnected
                  ? platformColor.withValues(alpha: 0.15)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              platformIcon,
              color: isThisPlatformConnected
                  ? platformColor
                  : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$platformName Bot',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isThisPlatformConnected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isThisPlatformConnected
                      ? 'Terhubung · ${state.phoneNumber}'
                      : 'Belum terhubung',
                  style: TextStyle(
                    fontSize: 12,
                    color: isThisPlatformConnected
                        ? platformColor
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isThisPlatformConnected) ...[
            const _PulseDot(),
            const SizedBox(width: 6),
          ],
          if (isThisPlatformConnected)
            IconButton(
              icon: const Icon(
                Icons.link_off_rounded,
                color: AppColors.error,
                size: 20,
              ),
              tooltip: 'Putuskan',
              onPressed: () => _showDisconnectConfirmDialog(context, notifier),
            ),
        ],
      ),
    );
  }

  Widget _buildLinkBotCard(
    BuildContext context,
    BotHubState state,
    BotHubNotifier notifier,
  ) {
    final hasToken = state.token != null && state.token!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Langkah Tautkan Akun',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasToken) ...[
            Text(
              'Tekan tombol di bawah untuk membuat kode verifikasi OTP sementara (berlaku 10 menit).',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: state.isGenerating ? null : notifier.generateBotToken,
              icon: state.isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.vpn_key_outlined),
              label: Text(
                state.isGenerating ? 'Membuat Kode...' : 'Dapatkan Kode OTP',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ] else ...[
            // Kode OTP Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'KODE VERIFIKASI ANDA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.token!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: AppColors.brand1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 20,
                          color: AppColors.brand1,
                        ),
                        tooltip: 'Salin Kode',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: state.token!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kode berhasil disalin!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih salah satu chat bot di bawah untuk menghubungkan:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // TOMBOL TELEGRAM & WHATSAPP ROW
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _launchUrlHelper(context, state.telegramLink!),
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text('Telegram Bot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF29B6F6), // Telegram Blue
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _launchUrlHelper(context, state.whatsappLink!),
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text('WhatsApp Bot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF66BB6A,
                      ), // WhatsApp Green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: notifier.generateBotToken,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Buat Ulang Kode'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildPersonaSelectorCard(
    BuildContext context,
    BotHubState state,
    BotHubNotifier notifier,
  ) {
    final pendingIsSantai = state.pendingPersona == 'santai';
    final hasChanges = state.personaChanged;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gaya Chat Iloo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Aktif: ${state.aiPersona == 'santai' ? 'Santai' : 'Tegas'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.brand1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih gaya balasan Iloo, lalu tekan Terapkan untuk menyimpan.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setPendingPersona('santai'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: pendingIsSantai ? const Color(0xFFFFF9C4) : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: pendingIsSantai ? AppColors.brand6 : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.face_retouching_natural,
                            color: pendingIsSantai ? AppColors.brand1 : AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'Santai & Empatik',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: pendingIsSantai ? AppColors.brand1 : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hangat & supportif',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: pendingIsSantai ? AppColors.brand2 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setPendingPersona('tegas'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: !pendingIsSantai ? const Color(0xFFFFCDD2) : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !pendingIsSantai ? AppColors.error : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.gavel_rounded,
                            color: !pendingIsSantai ? AppColors.error : AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'Tegas & Disiplin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: !pendingIsSantai ? AppColors.error : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lugas & to-the-point',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: !pendingIsSantai ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: hasChanges
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final chosen = state.pendingPersona;
                          await notifier.applyPersona();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gaya chat: ${chosen == 'santai' ? 'Santai & Empatik' : 'Tegas & Disiplin'} ✓',
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Terapkan Perubahan'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand1,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cara Penggunaan Bot',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _InstructionStep(
            number: '1',
            text:
                'Laporkan menu makanan Anda via chat (contoh: "Iloo, tadi pagi saya makan nasi goreng telur dadar satu porsi").',
          ),
          SizedBox(height: 12),
          _InstructionStep(
            number: '2',
            text:
                'Iloo akan secara otomatis menghitung estimasi gizi, kalori, dan dampak FINDRISC secara berkala.',
          ),
          SizedBox(height: 12),
          _InstructionStep(
            number: '3',
            text:
                'Konsultasikan gejala atau mintalah rekomendasi menu pencegah diabetes secara interaktif.',
          ),
        ],
      ),
    );
  }

  void _showDisconnectConfirmDialog(
    BuildContext context,
    BotHubNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Putuskan Koneksi Bot?'),
        content: const Text(
          'Apakah Anda yakin ingin memutuskan tautan bot chat? Anda tidak akan menerima saran gizi harian dari Iloo di WhatsApp/Telegram lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.disconnectBot();
            },
            child: const Text(
              'Ya, Putuskan',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM CHILD COMPONENT WIDGETS ──

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.brand1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
