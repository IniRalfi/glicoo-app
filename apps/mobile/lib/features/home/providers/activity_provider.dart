// activity_provider.dart
//
// Purpose:
// → Model data aktivitas harian + provider state management-nya.
//
// Used By:
// → home_screen.dart, quests_screen.dart, food_log_bottom_sheet.dart
//
// Depends On:
// → shared_preferences, hooks_riverpod, supabase_flutter
//
// Impact:
// → Semua fitur yang membaca langkah, tidur, screen time, kalori harian.

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data model untuk aktivitas harian.
class ActivityData {
  final int steps;
  final int stepsGoal;
  final int sleepMinutes;
  final int screenTimeMinutes;
  final int dailyCalories;
  final List<int> stepsHistory;
  final List<int> sleepHistory;
  final List<int> screenTimeHistory;

  const ActivityData({
    required this.steps,
    required this.stepsGoal,
    required this.sleepMinutes,
    required this.screenTimeMinutes,
    required this.dailyCalories,
    required this.stepsHistory,
    required this.sleepHistory,
    required this.screenTimeHistory,
  });
}

/// Provider state untuk data aktivitas harian (langkah, tidur, screen time, history).
class ActivityDataNotifier extends StateNotifier<ActivityData> {
  ActivityDataNotifier()
    : super(
        const ActivityData(
          steps: 0,
          stepsGoal: 5000,
          sleepMinutes: 0,
          screenTimeMinutes: 0,
          dailyCalories: 0,
          // [FIX] Ganti dummy data dengan array kosong untuk prevent progress bar palsu
          stepsHistory: [],
          sleepHistory: [],
          screenTimeHistory: [],
        ),
      ) {
    loadDailyValues();
    _startTimer();
  }

  Timer? _timer;

  Future<void> loadDailyValues() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastActiveDate = prefs.getString('glico_active_date');

    if (lastActiveDate != null && lastActiveDate != todayStr) {
      // Automatic daily reset at midnight (00:00)
      final prevSteps = prefs.getInt('glico_daily_steps') ?? 0;
      final prevSleep = prefs.getInt('glico_daily_sleep_minutes') ?? 0;
      final prevScreenTime = prefs.getInt('glico_daily_screen_time') ?? 0;

      // Update history list with previous day's stats
      final stepsHistory = List<int>.from(state.stepsHistory);
      if (stepsHistory.length >= 6) {
        stepsHistory.removeAt(0);
        stepsHistory.add(prevSteps);
      }

      final sleepHistory = List<int>.from(state.sleepHistory);
      if (sleepHistory.length >= 6) {
        sleepHistory.removeAt(0);
        sleepHistory.add(prevSleep);
      }

      final screenTimeHistory = List<int>.from(state.screenTimeHistory);
      if (screenTimeHistory.length >= 6) {
        screenTimeHistory.removeAt(0);
        screenTimeHistory.add(prevScreenTime);
      }

      // Reset daily values for the new day
      await prefs.setInt('glico_daily_steps', 0);
      await prefs.setInt('glico_daily_screen_time', 0);
      await prefs.setInt('glico_daily_screen_time_seconds', 0);
      await prefs.setInt('glico_daily_sleep_minutes', 0);
      await prefs.setInt('glico_daily_calories', 0);
      await prefs.setString('glico_active_date', todayStr);

      state = ActivityData(
        steps: 0,
        stepsGoal: state.stepsGoal,
        sleepMinutes: 0,
        screenTimeMinutes: 0,
        dailyCalories: 0,
        stepsHistory: stepsHistory,
        sleepHistory: sleepHistory,
        screenTimeHistory: screenTimeHistory,
      );
      return;
    } else if (lastActiveDate == null) {
      await prefs.setString('glico_active_date', todayStr);
    }

    final steps = prefs.getInt('glico_daily_steps') ?? 0;
    final screenTime = prefs.getInt('glico_daily_screen_time') ?? 0;
    final sleepMinutes = prefs.getInt('glico_daily_sleep_minutes') ?? 0;
    final dailyCalories = prefs.getInt('glico_daily_calories') ?? 0;

    final stepsHistory = List<int>.from(state.stepsHistory);
    if (stepsHistory.length > 4) stepsHistory[4] = steps;

    final screenTimeHistory = List<int>.from(state.screenTimeHistory);
    if (screenTimeHistory.length > 4) screenTimeHistory[4] = screenTime;

    state = ActivityData(
      steps: steps,
      stepsGoal: state.stepsGoal,
      sleepMinutes: sleepMinutes,
      screenTimeMinutes: screenTime,
      dailyCalories: dailyCalories,
      stepsHistory: stepsHistory,
      sleepHistory: state.sleepHistory,
      screenTimeHistory: screenTimeHistory,
    );
  }

  /// [ID] Menyimpan durasi tidur ke SharedPreferences dan memperbarui state
  /// [EN] Saves sleep duration to SharedPreferences and updates state
  Future<void> setSleepMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('glico_daily_sleep_minutes', minutes);
    await loadDailyValues();
  }

  /// [ID] Menambahkan kalori harian ke SharedPreferences dan memperbarui state
  /// [EN] Adds daily calories to SharedPreferences and updates state
  Future<void> addCalories(int calories) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('glico_daily_calories') ?? 0;
    await prefs.setInt('glico_daily_calories', current + calories);
    await loadDailyValues();
  }

  void _startTimer() {
    // [FIX] Increase polling interval dari 2 detik ke 15 detik untuk battery efficiency
    // TODO: Refactor ke push-based pattern dari sensor service untuk real-time update
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => loadDailyValues(),
    );
  }

  /// [ID] Update state langsung tanpa reload (untuk dipanggil dari sensor service)
  /// [EN] Update state directly without reload (to be called from sensor service)
  void updateSteps(int steps) {
    if (!mounted) return;
    state = ActivityData(
      steps: steps,
      stepsGoal: state.stepsGoal,
      sleepMinutes: state.sleepMinutes,
      screenTimeMinutes: state.screenTimeMinutes,
      dailyCalories: state.dailyCalories,
      stepsHistory: state.stepsHistory,
      sleepHistory: state.sleepHistory,
      screenTimeHistory: state.screenTimeHistory,
    );
  }

  /// [ID] Update screen time dan simpan ke SharedPreferences
  /// [EN] Update screen time and save to SharedPreferences
  /// [WHY] Persist data agar tidak hilang saat loadDailyValues() polling
  Future<void> updateScreenTime(int minutes) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('glico_daily_screen_time', minutes);
    await loadDailyValues();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activityDataProvider =
    StateNotifierProvider<ActivityDataNotifier, ActivityData>((ref) {
      return ActivityDataNotifier();
    });

/// Provider untuk mengambil data FINDRISC terbaru dari SharedPreferences.
final findriscDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final score = prefs.getInt('findrisc_score') ?? 0;
  final category = prefs.getString('findrisc_category') ?? 'Belum Tes';
  return {'score': score, 'category': category};
});

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
