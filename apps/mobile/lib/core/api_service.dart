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
import 'bot_link_exception.dart';

/// Provider untuk ApiService agar dapat di-inject ke berbagai feature.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// [ID] Mendapatkan access token JWT dari session aktif Supabase secara aman.
  /// [EN] Safely retrieves the JWT access token from the active Supabase session.
  Future<String?> _getAuthToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;

    if (session.isExpired) {
      final response = await Supabase.instance.client.auth.refreshSession();
      return response.session?.accessToken;
    }
    return session.accessToken;
  }

  /// [ID] Membuat header HTTP default secara asinkron, menyertakan JWT jika tersedia.
  /// [EN] Asynchronously creates default HTTP headers, attaching the JWT if available.
  Future<Map<String, String>> _buildHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// [ID] Memeriksa apakah user sudah menautkan bot (bot_platform tidak null).
  /// [EN] Checks if the user has an active bot link (bot_platform is not null).
  Future<bool> getBotStatus() async {
    try {
      final profile = await getUserProfile();
      final platform = profile['bot_platform']?.toString();
      return platform != null && platform.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// [ID] Mendapatkan platform bot yang terhubung (telegram/whatsapp).
  /// [EN] Get connected bot platform (telegram/whatsapp).
  Future<String?> getConnectedPlatform() async {
    try {
      final profile = await getUserProfile();
      return profile['bot_platform']?.toString().toLowerCase();
    } catch (_) {
      return null;
    }
  }

  /// [ID] Memutus koneksi bot Telegram/WhatsApp dari akun pengguna.
  /// [EN] Disconnects the Telegram/WhatsApp bot from the user account.
  Future<void> disconnectBot() async {
    final url = Uri.parse('${EnvConfig.backendUrl}/api/v1/bot/disconnect');
    try {
      final response = await _client.delete(
        url,
        headers: await _buildHeaders(),
      );
      if (response.statusCode != 200) {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errBody['message'] ?? 'Failed to disconnect bot');
      }
    } catch (e) {
      throw Exception('Gagal memutus koneksi bot: $e');
    }
  }

  /// [ID] Mengambil tautan deep link bot Telegram/WhatsApp dari backend.
  /// [EN] Retrieves the Telegram/WhatsApp bot deep link from the backend.
  Future<Map<String, dynamic>> getBotLink({
    String platform = 'telegram',
  }) async {
    final url = Uri.parse(
      '${EnvConfig.backendUrl}/api/v1/bot/link?platform=$platform',
    );
    try {
      final response = await _client.get(url, headers: await _buildHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 409) {
        // [WHY] Exclusive connection conflict
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw BotLinkException(
          errBody['message'] ?? 'Already connected to another platform',
          errBody['connectedPlatform']?.toString(),
        );
      } else {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errBody['message'] ?? 'Failed to get bot link');
      }
    } catch (e) {
      if (e is BotLinkException) rethrow;
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
        headers: await _buildHeaders(),
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
        headers: await _buildHeaders(),
        body: jsonEncode({'description': description}),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
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
      final response = await _client.get(url, headers: await _buildHeaders());

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
        headers: await _buildHeaders(),
        body: jsonEncode(
          <String, dynamic>{
            'name': name,
            'phone_number': phoneNumber?.isEmpty == true ? null : phoneNumber,
            'age': age,
            'weight': weight,
            'height': height,
            'has_family_history': hasFamilyHistory,
          }..removeWhere((key, value) => value == null),
        ),
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

  /// [ID] Mengirim pesan ke in-app chatbot Elysia backend beserta konteks lokal.
  /// [EN] Sends chat message to Glico Elysia backend in-app chatbot along with local context.
  Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    final url = Uri.parse('${EnvConfig.backendUrl}/api/v1/chat');
    try {
      final response = await _client.post(
        url,
        headers: await _buildHeaders(),
        body: jsonEncode({'message': message, 'context': context}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errBody['message'] ?? 'Failed to send chat message');
      }
    } catch (e) {
      throw Exception('Gagal mengirim pesan chat: $e');
    }
  }
}
