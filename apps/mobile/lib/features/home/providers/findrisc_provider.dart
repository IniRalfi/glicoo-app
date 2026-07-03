// findrisc_provider.dart
//
// Purpose:
// → Provider untuk membaca data FINDRISC (skor & kategori) dari SharedPreferences.
//   Dipindah dari activity_provider.dart agar tiap provider punya satu domain.
//
// Used By:
// → home_screen.dart, profile_screen.dart
//
// Depends On:
// → shared_preferences, hooks_riverpod
//
// Impact:
// → Tampilan skor risiko diabetes di Home dan Profile

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk mengambil data FINDRISC terbaru dari SharedPreferences.
final findriscDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final score = prefs.getInt('findrisc_score') ?? 0;
  final category = prefs.getString('findrisc_category') ?? 'Belum Tes';
  return {'score': score, 'category': category};
});
