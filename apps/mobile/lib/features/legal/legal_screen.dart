// features/legal/legal_screen.dart
//
// Legal consent screen — tampil setelah Onboarding, sebelum Auth.
// User harus mencentang ToS + Privacy Policy agar tombol "Lanjut" aktif.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';

/// Layar persetujuan legalitas Glico.
///
/// [onAccepted] dipanggil saat user mencentang keduanya dan menekan "Lanjut".
/// Caller bertanggung jawab navigate ke Auth.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  bool _agreedToS = false;
  bool _agreedPrivacy = false;

  bool get _canProceed => _agreedToS && _agreedPrivacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: splash_text centered ────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Center(
                  child: Image.asset(
                    'assets/images/splash/splash_text.png',
                    width: 110,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Sebelum Mulai',
                style: AppTypography.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Harap baca dan setujui Syarat & Ketentuan serta '
                'Kebijakan Privasi kami sebelum menggunakan Glico.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Scrollable content ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Terms of Service card
                      BentoCard(
                        backgroundColor: AppColors.surfaceMuted,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.article_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Syarat & Ketentuan',
                                  style: AppTypography.textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _LegalText(text: _termsOfService),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Privacy Policy card
                      BentoCard(
                        backgroundColor: AppColors.surfaceMuted,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.privacy_tip_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Kebijakan Privasi',
                                  style: AppTypography.textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _LegalText(text: _privacyPolicy),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Checkboxes ──────────────────────────────────
                      _ConsentCheckbox(
                        value: _agreedToS,
                        onChanged: (v) => setState(() => _agreedToS = v),
                        label:
                            'Saya telah membaca dan menyetujui '
                            'Syarat & Ketentuan Glico.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ConsentCheckbox(
                        value: _agreedPrivacy,
                        onChanged: (v) => setState(() => _agreedPrivacy = v),
                        label:
                            'Saya telah membaca dan menyetujui '
                            'Kebijakan Privasi Glico.',
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // ── CTA Button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canProceed ? widget.onAccepted : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.4,
                    ),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.buttonRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    'Lanjut',
                    style: AppTypography.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widget: scrollable legal text ────────────────────────────────────────

class _LegalText extends StatelessWidget {
  const _LegalText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        height: 1.6,
      ),
    );
  }
}

// ── Sub-widget: consent checkbox row ─────────────────────────────────────────

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primary,
              checkColor: AppColors.textOnPrimary,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legal content strings ─────────────────────────────────────────────────────

const String _termsOfService = '''
1. Penerimaan Syarat

Dengan menggunakan aplikasi Glico, Anda menyetujui Syarat & Ketentuan ini. Jika Anda tidak setuju, mohon hentikan penggunaan aplikasi.

2. Deskripsi Layanan

Glico adalah perangkat lunak berbasis kecerdasan buatan yang dirancang untuk membantu deteksi dini risiko diabetes tipe 2 dan mendorong perubahan gaya hidup sehat melalui pemantauan aktivitas fisik, pola makan, dan interaksi bot AI.

3. Bukan Pengganti Tenaga Medis

Glico bukan merupakan aplikasi telemedicine dan tidak memberikan diagnosis medis. Semua saran yang diberikan bersifat edukatif dan preventif. Selalu konsultasikan kondisi kesehatan Anda kepada tenaga medis profesional.

4. Data Pengguna

Anda bertanggung jawab atas keakuratan data yang Anda masukkan, termasuk data tubuh dan riwayat kesehatan. Glico menggunakan data ini semata-mata untuk memberikan rekomendasi yang relevan.

5. Perubahan Layanan

Glico berhak mengubah atau menghentikan layanan sewaktu-waktu dengan pemberitahuan kepada pengguna melalui aplikasi atau email terdaftar.
''';

const String _privacyPolicy = '''
1. Data yang Dikumpulkan

Glico mengumpulkan data berikut: informasi akun (nama, email via Google OAuth), data kesehatan (usia, tinggi badan, berat badan, lingkar perut, riwayat keluarga), data aktivitas sensor (jumlah langkah, durasi layar, durasi duduk), serta log makanan yang Anda bagikan melalui bot AI.

2. Penggunaan Data

Data Anda digunakan untuk: menghitung skor risiko FINDRISC, memberikan rekomendasi gaya hidup personal, menganalisis tren kesehatan jangka panjang, dan meningkatkan akurasi model AI Glico.

3. Keamanan Data

Semua data disimpan secara terenkripsi di Supabase dengan standar keamanan industri. Kami tidak menjual, menyewakan, atau membagikan data Anda kepada pihak ketiga tanpa izin eksplisit Anda, kecuali diwajibkan oleh hukum.

4. Retensi Data

Data Anda disimpan selama akun aktif. Anda dapat meminta penghapusan data kapan saja melalui halaman Profil > Pengaturan Akun.

5. Hak Pengguna

Anda berhak mengakses, memperbaiki, atau menghapus data pribadi Anda. Hubungi kami di privacy@glico.id untuk permintaan terkait data.
''';
