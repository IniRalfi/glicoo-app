// sync_manager.dart
//
// Purpose:
// Mengelola antrean data lokal (local-first) dan sinkronisasi otomatis ke server backend.
//
// Used By:
// home_screen.dart, profile_provider.dart, sensor_service.dart
//
// Depends On:
// shared_preferences, api_service.dart, dart:io, dart:convert
//
// Impact:
// Sinkronisasi otomatis data luring (offline) ke server saat jaringan tersedia.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Provider untuk SyncManager agar dapat di-inject.
final syncManagerProvider = Provider<SyncManager>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SyncManager(apiService);
});

class SyncManager {
  SyncManager(this._apiService);

  final ApiService _apiService;

  static const String _kFoodQueueKey = 'glico_food_sync_queue';
  static const String _kProfilePendingSyncKey = 'glico_profile_pending_sync';
  
  // Kunci profil cache lokal
  static const String kPrefProfileName = 'glico_cached_profile_name';
  static const String kPrefProfilePhone = 'glico_cached_profile_phone';
  static const String kPrefProfileAge = 'glico_cached_profile_age';
  static const String kPrefProfileWeight = 'glico_cached_profile_weight';
  static const String kPrefProfileHeight = 'glico_cached_profile_height';
  static const String kPrefProfileFamilyHistory = 'glico_cached_profile_has_family_history';
  static const String kPrefProfileRiskScore = 'glico_cached_profile_risk_score';

  /// [ID]
  /// Memeriksa apakah perangkat terhubung ke internet.
  ///
  /// [EN]
  /// Checks if the device is connected to the internet.
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// [ID]
  /// Memasukkan log makanan ke antrean lokal jika offline, atau langsung mengirimkan jika online.
  ///
  /// [EN]
  /// Queues food log locally if offline, or sends immediately if online.
  Future<bool> queueFoodLog(String description) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Simpan ke antrean lokal terlebih dahulu (Local-First)
    final queueStr = prefs.getString(_kFoodQueueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueStr) as List<dynamic>;
    
    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    queue.add(newItem);
    await prefs.setString(_kFoodQueueKey, jsonEncode(queue));
    
    // Coba sync langsung jika online
    if (await isOnline()) {
      await syncPendingData();
      return true;
    }
    
    return false; // Mengembalikan false jika disave offline
  }

  /// [ID]
  /// Menyimpan data profil secara lokal dan menandai status sinkronisasi tertunda.
  ///
  /// [EN]
  /// Saves profile data locally and flags synchronization as pending.
  Future<void> cacheProfileLocally({
    required String name,
    required String phoneNumber,
    required int age,
    required double weight,
    required double height,
    required bool hasFamilyHistory,
    double? riskScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefProfileName, name);
    await prefs.setString(kPrefProfilePhone, phoneNumber);
    await prefs.setInt(kPrefProfileAge, age);
    await prefs.setDouble(kPrefProfileWeight, weight);
    await prefs.setDouble(kPrefProfileHeight, height);
    await prefs.setBool(kPrefProfileFamilyHistory, hasFamilyHistory);
    if (riskScore != null) {
      await prefs.setDouble(kPrefProfileRiskScore, riskScore);
    }
    await prefs.setBool(_kProfilePendingSyncKey, true);
  }

  /// [ID]
  /// Melakukan sinkronisasi seluruh data yang tertunda (makanan, profil, sensor) ke server.
  ///
  /// [EN]
  /// Synchronizes all pending data (food logs, profile, sensors) to the server.
  Future<void> syncPendingData() async {
    if (!await isOnline()) {
      debugPrint('[SyncManager] Perangkat offline, menunda sinkronisasi.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // 1. Sync Profil Terlebih Dahulu
    final pendingProfile = prefs.getBool(_kProfilePendingSyncKey) ?? false;
    if (pendingProfile) {
      debugPrint('[SyncManager] Sinkronisasi profil tertunda...');
      try {
        final name = prefs.getString(kPrefProfileName) ?? '';
        final phone = prefs.getString(kPrefProfilePhone) ?? '';
        final age = prefs.getInt(kPrefProfileAge) ?? 0;
        final weight = prefs.getDouble(kPrefProfileWeight) ?? 0.0;
        final height = prefs.getDouble(kPrefProfileHeight) ?? 0.0;
        final hasFamilyHistory = prefs.getBool(kPrefProfileFamilyHistory) ?? false;

        final res = await _apiService.updateUserProfile(
          name: name.isNotEmpty ? name : null,
          phoneNumber: phone.isNotEmpty ? phone : null,
          age: age > 0 ? age : null,
          weight: weight > 0 ? weight : null,
          height: height > 0 ? height : null,
          hasFamilyHistory: hasFamilyHistory,
        );

        // Update score hasil kalkulasi backend ke lokal jika ada
        if (res['risk_score'] != null) {
          final newRisk = (res['risk_score'] as num).toDouble();
          await prefs.setDouble(kPrefProfileRiskScore, newRisk);
          
          // Juga update score di findrisc_score untuk HomeScreen compat
          await prefs.setInt('findrisc_score', newRisk.toInt());
          final category = newRisk >= 15 ? 'Tinggi' : (newRisk >= 7 ? 'Sedang' : 'Rendah');
          await prefs.setString('findrisc_category', category);
        }

        await prefs.setBool(_kProfilePendingSyncKey, false);
        debugPrint('[SyncManager] Profil berhasil disinkronisasi.');
      } catch (e) {
        debugPrint('[SyncManager] Gagal sinkronisasi profil: $e');
      }
    }

    // 2. Sync Food Logs
    final queueStr = prefs.getString(_kFoodQueueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueStr) as List<dynamic>;
    if (queue.isNotEmpty) {
      debugPrint('[SyncManager] Sinkronisasi ${queue.length} log makanan tertunda...');
      final List<dynamic> remaining = [];
      
      for (final item in queue) {
        final description = item['description'] as String;
        try {
          await _apiService.logFood(description);
          debugPrint('[SyncManager] Berhasil mencatat makanan: "$description"');
        } catch (e) {
          debugPrint('[SyncManager] Gagal mencatat makanan "$description": $e. Memasukkan kembali ke antrean.');
          remaining.add(item);
        }
      }
      
      await prefs.setString(_kFoodQueueKey, jsonEncode(remaining));
      debugPrint('[SyncManager] Sinkronisasi log makanan selesai. Sisa antrean: ${remaining.length}');
    }

    debugPrint('[SyncManager] Sinkronisasi selesai.');
  }
}
