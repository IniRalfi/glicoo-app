// env_config.dart
//
// Purpose:
// Load environment variables from .env file so the app can access Supabase
// credentials and other secrets at runtime.
//
// Used By:
// main.dart — initializes Supabase before runApp()
//
// Depends On:
// flutter_dotenv
//
// Impact:
// Any file that reads SUPABASE_URL / SUPABASE_ANON_KEY

import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class EnvConfig {
  static Future<void> load() => dotenv.load();

  /// Supabase project URL from .env
  static String get supabaseUrl => _require('SUPABASE_URL');

  /// Supabase anon (public) key from .env
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  /// Backend Elysia API URL from .env (defaults to Android emulator host IP)
  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3001';

  /// Telegram Bot Username from .env (defaults to 'GlicoBot')
  static String get telegramBotUsername => dotenv.env['TELEGRAM_BOT_USERNAME'] ?? 'GlicoBot';

  /// WhatsApp Bot Number from .env (defaults to '628123456789')
  static String get whatsappBotNumber => dotenv.env['WHATSAPP_BOT_NUMBER'] ?? '628123456789';

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required env variable: $key');
    }
    return value;
  }
}
