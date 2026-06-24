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

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_service.dart';

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
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._apiService) : super(ProfileState()) {
    loadProfile();
  }

  final ApiService _apiService;

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final email = currentUser?.email ?? '';
      
      final data = await _apiService.getUserProfile();
      
      state = ProfileState(
        name: data['name'] as String? ?? 'Pengguna Glicoo',
        email: email,
        phoneNumber: data['phone_number'] as String? ?? '',
        age: data['age'] as int? ?? 0,
        weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
        height: (data['height'] as num?)?.toDouble() ?? 0.0,
        hasFamilyHistory: data['has_family_history'] as bool? ?? false,
        riskScore: (data['risk_score'] as num?)?.toDouble() ?? 0.0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    try {
      final data = await _apiService.updateUserProfile(
        name: name,
        phoneNumber: phoneNumber,
        age: age,
        weight: weight,
        height: height,
        hasFamilyHistory: hasFamilyHistory,
      );

      state = state.copyWith(
        name: data['name'] as String? ?? name,
        phoneNumber: data['phone_number'] as String? ?? phoneNumber,
        age: data['age'] as int? ?? age,
        weight: (data['weight'] as num?)?.toDouble() ?? weight,
        height: (data['height'] as num?)?.toDouble() ?? height,
        hasFamilyHistory: data['has_family_history'] as bool? ?? hasFamilyHistory,
        riskScore: (data['risk_score'] as num?)?.toDouble() ?? state.riskScore,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProfileNotifier(apiService);
});
