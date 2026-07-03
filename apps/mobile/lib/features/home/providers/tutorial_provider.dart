// tutorial_provider.dart
//
// Purpose:
// → Provider untuk state tutorial Iloo dan nama user.
//   Dipindah dari activity_provider.dart agar domain terpisah.
//
// Used By:
// → home_screen.dart
//
// Depends On:
// → shared_preferences, hooks_riverpod, supabase_flutter
//
// Impact:
// → Dialog tutorial Iloo, greeting nama user di Home

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider untuk mengambil nama user dari Supabase.
final userNameProvider = Provider<String>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  final name = user?.userMetadata?['name'] ?? user?.userMetadata?['full_name'];
  return name ?? 'Pemanasan';
});

/// Provider untuk mendeteksi apakah user sudah menyelesaikan tutorial Iloo.
/// [WHY] FutureProvider — initial load dari SharedPreferences.
final tutorialSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('tutorial_iloo_done') ?? false;
});

/// Synchronous provider untuk status tutorial Iloo.
/// [WHY] Hindari race condition FutureProvider setelah invalidate().
/// [TRADEOFF] Butuh inisialisasi manual di initState + sinkronisasi manual.
final tutorialDoneProvider = StateProvider<bool>((ref) => false);

/// Provider untuk mendeteksi apakah dialog tutorial sedang terbuka.
final tutorialDialogShowingProvider = StateProvider<bool>((ref) => false);
