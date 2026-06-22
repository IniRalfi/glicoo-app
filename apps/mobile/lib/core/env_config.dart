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

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required env variable: $key');
    }
    return value;
  }
}
