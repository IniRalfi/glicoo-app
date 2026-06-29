// profile_provider.dart
//
// Purpose:
// StateNotifier to manage user profile load and update operations.
//
// Used By:
// profile_screen.dart
//
// Depends On:
// api_service.dart, hooks_riverpod, supabase_flutter
//
// Impact:
// Profile editing and display features.

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_service.dart';
import '../../core/sync_manager.dart';

class ProfileState {
  final String name;
  final String email;
  final String phoneNumber;
  final int age;
  final double weight;
  final double height;
  final bool hasFamilyHistory;
  final double riskScore;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? botChatId; // WhatsApp chatId or Telegram chatId
  final String? botPlatform; // "TELEGRAM" | "WHATSAPP"

  ProfileState({
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
    this.age = 0,
    this.weight = 0.0,
    this.height = 0.0,
    this.hasFamilyHistory = false,
    this.riskScore = 0.0,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.botChatId,
    this.botPlatform,
  });

  ProfileState copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    int? age,
    double? weight,
    double? height,
    bool? hasFamilyHistory,
    double? riskScore,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? botChatId,
    String? botPlatform,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      hasFamilyHistory: hasFamilyHistory ?? this.hasFamilyHistory,
      riskScore: riskScore ?? this.riskScore,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      botChatId: botChatId ?? this.botChatId,
      botPlatform: botPlatform ?? this.botPlatform,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._apiService, this._syncManager) : super(ProfileState()) {
    loadProfile();
  }

  final ApiService _apiService;
  final SyncManager _syncManager;

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    final prefs = await SharedPreferences.getInstance();
    final currentUser = Supabase.instance.client.auth.currentUser;
    final email = currentUser?.email ?? '';

    // 1. Load dari local cache terlebih dahulu agar UI terisi seketika
    final cachedName = prefs.getString(SyncManager.kPrefProfileName) ?? '';
    final cachedPhone = prefs.getString(SyncManager.kPrefProfilePhone) ?? '';
    final cachedAge = prefs.getInt(SyncManager.kPrefProfileAge) ?? 0;
    final cachedWeight = prefs.getDouble(SyncManager.kPrefProfileWeight) ?? 0.0;
    final cachedHeight = prefs.getDouble(SyncManager.kPrefProfileHeight) ?? 0.0;
    final cachedFamilyHistory =
        prefs.getBool(SyncManager.kPrefProfileFamilyHistory) ?? false;
    final cachedRisk =
        prefs.getDouble(SyncManager.kPrefProfileRiskScore) ?? 0.0;

    if (cachedName.isNotEmpty || cachedAge > 0) {
      state = ProfileState(
        name: cachedName,
        email: email,
        phoneNumber: cachedPhone,
        age: cachedAge,
        weight: cachedWeight,
        height: cachedHeight,
        hasFamilyHistory: cachedFamilyHistory,
        riskScore: cachedRisk,
        isLoading: false,
        // [WHY] Bot fields tidak di-cache locally, hanya dari API
        botChatId: null,
        botPlatform: null,
      );
    }

    // 2. Tarik data terbaru dari API jika online
    try {
      if (await _syncManager.isOnline()) {
        final data = await _apiService.getUserProfile();

        final name = data['name'] as String? ?? 'Pengguna Glicoo';
        final phone = data['phone_number'] as String? ?? '';
        final age = data['age'] as int? ?? 0;
        final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
        final height = (data['height'] as num?)?.toDouble() ?? 0.0;
        final hasFamilyHistory = data['has_family_history'] as bool? ?? false;
        final riskScore = (data['risk_score'] as num?)?.toDouble() ?? 0.0;
        final botChatId = data['bot_chat_id'] as String?;
        final botPlatform = data['bot_platform'] as String?;

        state = ProfileState(
          name: name,
          email: email,
          phoneNumber: phone,
          age: age,
          weight: weight,
          height: height,
          hasFamilyHistory: hasFamilyHistory,
          riskScore: riskScore,
          isLoading: false,
          botChatId: botChatId,
          botPlatform: botPlatform,
        );

        // Update local cache
        await _syncManager.cacheProfileLocally(
          name: name,
          phoneNumber: phone,
          age: age,
          weight: weight,
          height: height,
          hasFamilyHistory: hasFamilyHistory,
          riskScore: riskScore,
        );
        // Tandai sudah sinkron
        await prefs.setBool('glico_profile_pending_sync', false);
      }
    } catch (e) {
      debugPrint('[ProfileProvider] loadProfile API error (using cache): $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phoneNumber,
    required int age,
    required double weight,
    required double height,
    required bool hasFamilyHistory,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    // 1. Simpan ke local cache terlebih dahulu (Offline-First)
    await _syncManager.cacheProfileLocally(
      name: name,
      phoneNumber: phoneNumber,
      age: age,
      weight: weight,
      height: height,
      hasFamilyHistory: hasFamilyHistory,
    );

    // Update state agar UI langsung berubah
    state = state.copyWith(
      name: name,
      phoneNumber: phoneNumber,
      age: age,
      weight: weight,
      height: height,
      hasFamilyHistory: hasFamilyHistory,
    );

    // 2. Coba sinkronisasi langsung ke server jika online
    try {
      if (await _syncManager.isOnline()) {
        final data = await _apiService.updateUserProfile(
          name: name,
          phoneNumber: phoneNumber,
          age: age,
          weight: weight,
          height: height,
          hasFamilyHistory: hasFamilyHistory,
        );

        final riskScore =
            (data['risk_score'] as num?)?.toDouble() ?? state.riskScore;

        state = state.copyWith(
          name: data['name'] as String? ?? name,
          phoneNumber: data['phone_number'] as String? ?? phoneNumber,
          age: data['age'] as int? ?? age,
          weight: (data['weight'] as num?)?.toDouble() ?? weight,
          height: (data['height'] as num?)?.toDouble() ?? height,
          hasFamilyHistory:
              data['has_family_history'] as bool? ?? hasFamilyHistory,
          riskScore: riskScore,
          isSaving: false,
        );

        // Update local cache dengan risk score baru dari server
        await _syncManager.cacheProfileLocally(
          name: state.name,
          phoneNumber: state.phoneNumber,
          age: state.age,
          weight: state.weight,
          height: state.height,
          hasFamilyHistory: state.hasFamilyHistory,
          riskScore: riskScore,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('glico_profile_pending_sync', false);
        return true;
      } else {
        // Jika offline, biarkan pending_sync bernilai true
        state = state.copyWith(isSaving: false);
        return true; // Berhasil disimpan lokal
      }
    } catch (e) {
      debugPrint('[ProfileProvider] updateProfile API error: $e');
      // Data tetap tersimpan lokal, tapi return false agar UI tahu ada masalah
      state = state.copyWith(
        isSaving: false,
        error: 'Gagal menyimpan ke server: $e',
      );
      return false;
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      final syncManager = ref.watch(syncManagerProvider);
      return ProfileNotifier(apiService, syncManager);
    });
