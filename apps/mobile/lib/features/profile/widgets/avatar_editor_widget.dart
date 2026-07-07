// avatar_editor_widget.dart
//
// Purpose:
// Bottom sheet widget untuk customize avatar pengguna (warna background & asset picker).
// Allows users to choose from predefined colors and Iloo characters, or upload from gallery.
//
// Used By:
// profile_screen.dart
//
// Depends On:
// image_picker, flutter_svg, shared_preferences
//
// Impact:
// Avatar customization UI

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';

class AvatarEditorWidget extends StatefulWidget {
  final String currentBgColor;
  final String currentAssetPath;
  final String? currentFilePath;
  final String currentType;
  final VoidCallback onSaved;

  const AvatarEditorWidget({
    super.key,
    required this.currentBgColor,
    required this.currentAssetPath,
    this.currentFilePath,
    required this.currentType,
    required this.onSaved,
  });

  @override
  State<AvatarEditorWidget> createState() => _AvatarEditorWidgetState();
}

class _AvatarEditorWidgetState extends State<AvatarEditorWidget> {
  late String _tempType;
  late String _tempBgColor;
  late String _tempAssetPath;
  String? _tempFilePath;

  final List<String> _colors = [
    '0xFFFFB700', // Yellow
    '0xFF0088FF', // Blue
    '0xFFFF2D55', // Red
    '0xFF34C759', // Green
    '0xFFAF52DE', // Purple
    '0xFFFF9500', // Orange
    '0xFF5AC8FA', // Light Teal
    '0xFF8E8E93', // Grey
  ];

  final List<String> _assets = [
    'assets/images/glico_logo.svg',
    'assets/images/misi/iloo_screen.svg',
    'assets/images/misi/iloo_sleep.svg',
    'assets/images/misi/iloo_walk.svg',
    'assets/images/tutorial/iloo-oke.svg',
    'assets/images/tutorial/iloo-kawai.svg',
    'assets/images/tutorial/iloo-greeting.svg',
    'assets/images/bothub/pp_iloo.svg',
  ];

  @override
  void initState() {
    super.initState();
    _tempType = widget.currentType;
    _tempBgColor = widget.currentBgColor;
    _tempAssetPath = widget.currentAssetPath;
    _tempFilePath = widget.currentFilePath;
  }

  Future<void> _saveAvatarSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_type', _tempType);
    await prefs.setString('avatar_bg_color', _tempBgColor);
    await prefs.setString('avatar_asset_path', _tempAssetPath);
    if (_tempFilePath != null) {
      await prefs.setString('avatar_file_path', _tempFilePath!);
    } else {
      await prefs.remove('avatar_file_path');
    }
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _tempType = 'file';
        _tempFilePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = Color(int.parse(_tempBgColor));

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
                child: _tempType == 'file' && _tempFilePath != null
                    ? Image.file(File(_tempFilePath!), fit: BoxFit.cover)
                    : Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SvgPicture.asset(
                          _tempAssetPath,
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
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final hex = _colors[index];
                final isSelected = _tempBgColor == hex;
                final color = Color(int.parse(hex));
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _tempBgColor = hex;
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
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
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
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
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
              itemCount: _assets.length,
              itemBuilder: (context, index) {
                final assetPath = _assets[index];
                final isSelected =
                    _tempType == 'asset' && _tempAssetPath == assetPath;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _tempType = 'asset';
                      _tempAssetPath = assetPath;
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
                    child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          FilledButton(
            onPressed: _saveAvatarSettings,
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
  }
}
