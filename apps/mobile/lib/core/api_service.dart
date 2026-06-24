// api_service.dart
//
// Purpose:
// HttpClient wrapper for calling Glico Elysia backend with Supabase Auth headers.
//
// Used By:
// bot_hub_screen.dart, food_logging, sensor_sync
//
// Depends On:
// http, supabase_flutter, env_config, hooks_riverpod
//
// Impact:
// Backend communication for mobile application.

import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env_config.dart';

/// Provider untuk ApiService agar dapat di-inject ke berbagai feature.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// [ID] Mendapatkan access token JWT dari session aktif Supabase.
  /// [EN] Retrieves the JWT access token from the active Supabase session.
  String? _getAuthToken() {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  /// [ID] Membuat header HTTP default, menyertakan JWT jika tersedia.
  /// [EN] Creates default HTTP headers, attaching the JWT if available.
  Map<String, String> _buildHeaders() {
    final token = _getAuthToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// [ID] Mengambil tautan deep link bot Telegram/WhatsApp dari backend.
  /// [EN] Retrieves the Telegram/WhatsApp bot deep link from the backend.
  Future<Map<String, dynamic>> getBotLink() async {
    final url = Uri.parse('${EnvConfig.backendUrl}/api/v1/bot/link');
    try {
      final response = await _client.get(
        url,
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errBody['message'] ?? 'Failed to get bot link');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  /// [ID] Mengirim data sensor harian (langkah & screen time) ke backend.
  /// [EN] Sends daily sensor data (steps & screen time) to the backend.
  Future<void> syncSensors({
    required String date,
    required int stepCount,
    required int screenTimeMinutes,
  }) async {
    final url = Uri.parse('${EnvConfig.backendUrl}/api/v1/sensors/sync');
    try {
      final response = await _client.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({
          'date': date,
          'step_count': stepCount,
          'screen_time_minutes': screenTimeMinutes,
        }),
      );

      if (response.statusCode != 200) {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errBody['message'] ?? 'Failed to sync sensor data');
      }
    } catch (e) {
      throw Exception('Gagal sinkronisasi sensor: $e');
    }
  }

  /// [ID] Mencatat makanan baru menggunakan deskripsi tekstual.
  /// [EN] Logs new food using natural text description.
  Future<Map<String, dynamic>> logFood(String description) async {
    final url = Uri.parse('${EnvConfig.backendUrl}/api/v1/food/log');
    try {
      final response = await _client.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode({
          'description': description,
        }),
      );

      if (response.statusCode == 202) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errBody['message'] ?? 'Failed to log food');
      }
    } catch (e) {
      throw Exception('Gagal menyimpan log makanan: $e');
    }
  }

  /// [ID] Mengambil data profil user dari backend.
  /// [EN] Retrieves user profile details from backend.
  Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse('${EnvConfig.backendUrl}/api/v1/users/profile');
    try {
      final response = await _client.get(
        url,
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errBody['message'] ?? 'Failed to load user profile');
      }
    } catch (e) {
      throw Exception('Gagal memuat profil: $e');
    }
  }

  /// [ID] Memperbarui data profil user dan menghitung ulang risiko FINDRISC.
  /// [EN] Updates user profile details and recalculates FINDRISC risk score.
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phoneNumber,
    int? age,
    double? weight,
    double? height,
    bool? hasFamilyHistory,
  }) async {
    final url = Uri.parse('${EnvConfig.backendUrl}/api/v1/users/profile');
    try {
      final response = await _client.patch(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(<String, dynamic>{
          'name': name,
          'phone_number': phoneNumber,
          'age': age,
          'weight': weight,
          'height': height,
          'has_family_history': hasFamilyHistory,
        }..removeWhere((key, value) => value == null)),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errBody['message'] ?? 'Failed to update user profile');
      }
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }
}
