// edit_profile_bottom_sheet.dart
//
// Purpose:
// → Full-page screen untuk mengedit profil & data kesehatan user.
//   Sebelumnya bottom sheet, sekarang full Scaffold agar konsisten dengan UI-03.
//
// Used By:
// → profile_screen.dart (via Navigator.push)
//
// Depends On:
// → flutter/material, hooks_riverpod, shared_preferences, google_fonts
// → profile_provider.dart, app_colors.dart
//
// Impact:
// → Form edit nama, telepon, usia, berat, tinggi, lingkar pinggang, riwayat keluarga

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../profile_provider.dart';

/// Full-page screen untuk mengedit profil & data kesehatan user.
class EditProfileBottomSheet extends ConsumerStatefulWidget {
  const EditProfileBottomSheet({
    super.key,
    required this.profileState,
    required this.waistCircumference,
    required this.onSaved,
  });

  final ProfileState profileState;
  final double waistCircumference;

  /// [ID] Callback setelah berhasil menyimpan — dipakai untuk reload settings.
  /// [EN] Callback after successful save — used to reload settings.
  final VoidCallback onSaved;

  @override
  ConsumerState<EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState
    extends ConsumerState<EditProfileBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _waistController;
  late bool _hasFamilyHistory;

  @override
  void initState() {
    super.initState();
    final s = widget.profileState;
    _nameController = TextEditingController(text: s.name);
    _phoneController = TextEditingController(text: s.phoneNumber);
    _ageController = TextEditingController(
      text: s.age > 0 ? s.age.toString() : '',
    );
    _weightController = TextEditingController(
      text: s.weight > 0 ? s.weight.toString() : '',
    );
    _heightController = TextEditingController(
      text: s.height > 0 ? s.height.toString() : '',
    );
    _waistController = TextEditingController(
      text: widget.waistCircumference > 0
          ? widget.waistCircumference.toInt().toString()
          : '98',
    );
    _hasFamilyHistory = s.hasFamilyHistory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _waistController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final age = int.tryParse(_ageController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final height = double.tryParse(_heightController.text) ?? 0.0;
    final waist = double.tryParse(_waistController.text) ?? 98.0;

    final success = await ref
        .read(profileNotifierProvider.notifier)
        .updateProfile(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          age: age,
          weight: weight,
          height: height,
          hasFamilyHistory: _hasFamilyHistory,
        );

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lingkar_pinggang_cm', waist);
      widget.onSaved();

      if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Perbarui Data Kesehatan',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pastikan data terbaru agar Iloo dapat memberikan analisis dan rekomendasi yang lebih akurat.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Nama Lengkap
            _buildLabel('Nama Lengkap'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Pemanasan'),
            ),
            const SizedBox(height: 16),

            // Nomor WhatsApp / Telegram
            _buildLabel('Nomor WhatsApp / Telegram'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('089123456789'),
            ),
            const SizedBox(height: 16),

            // Usia + Tinggi
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Usia'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecorationWithSuffix('tahun'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tinggi'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecorationWithSuffix('cm'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Berat + Lingkar Pinggang
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Berat (kg)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecorationWithSuffix('kg'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Lingkar Pinggang'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _waistController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecorationWithSuffix('cm'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle Riwayat Diabetes
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: SwitchListTile(
                value: _hasFamilyHistory,
                onChanged: (val) => setState(() => _hasFamilyHistory = val),
                title: Text(
                  'Riwayat Diabetes dalam Keluarga',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Aktifkan jika orang tua, saudara kandung, atau anggota keluarga memiliki riwayat diabetes.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                activeThumbColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan
            FilledButton.icon(
              onPressed: profileState.isSaving ? null : _save,
              icon: profileState.isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(
                'Simpan Perubahan',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Perubahan data dapat memengaruhi hasil penilaian risiko dan rekomendasi yang diberikan oleh Iloo.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: AppColors.placeholderGray,
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF2F2F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  InputDecoration _inputDecorationWithSuffix(String suffix) {
    return InputDecoration(
      hintText: suffix,
      hintStyle: GoogleFonts.inter(
        color: AppColors.placeholderGray,
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF2F2F7),
      suffixText: suffix,
      suffixStyle: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
