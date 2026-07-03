// edit_profile_bottom_sheet.dart
//
// Purpose:
// → Bottom sheet untuk mengedit profil & data kesehatan user.
//   Dipindah dari _showEditProfileDialog() inline di profile_screen.dart.
//
// Used By:
// → profile_screen.dart
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

/// Bottom sheet untuk mengedit profil & data kesehatan user.
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
              controller: _nameController,
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
              controller: _phoneController,
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
                    controller: _ageController,
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
                    controller: _heightController,
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
                    controller: _weightController,
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
                    controller: _waistController,
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
                value: _hasFamilyHistory,
                onChanged: (val) => setState(() => _hasFamilyHistory = val),
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
              onPressed: profileState.isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: profileState.isSaving
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
  }
}
