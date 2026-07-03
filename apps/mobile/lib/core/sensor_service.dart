// sensor_service.dart
//
// Purpose:
// Mengelola perekaman langkah kaki (Pedometer) dan screen time secara real-time,
// serta registrasi Workmanager untuk background synchronization ke Elysia backend.
//
// Used By:
// main.dart (inisialisasi), home_screen.dart (state update)
//
// Depends On:
// pedometer, workmanager, permission_handler, shared_preferences, api_service, env_config
//
// Impact:
// Perekaman data sensor pasif (langkah kaki, screen time) dan sinkronisasi berkala.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'api_service.dart';
import 'env_config.dart';
import 'sync_manager.dart';

/// [ID] Kunci konstan untuk SharedPreferences
/// [EN] Constant keys for SharedPreferences
const String kPrefLastBootStepsOffset = 'glico_boot_steps_offset';
const String kPrefLastSyncDate = 'glico_last_sync_date';
const String kPrefTodaySteps = 'glico_daily_steps';
const String kPrefTodayScreenTime = 'glico_daily_screen_time';

/// [ID] Nama task unik untuk Workmanager background sync
/// [EN] Unique task name for Workmanager background sync
const String kBackgroundSyncTaskName = 'glico-sensor-sync-task';

/// [ID] Callback Entry Point untuk Workmanager (wajib top-level & annotasi entry-point)
/// [EN] Callback Entry Point for Workmanager (must be top-level & entry-point annotated)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final steps = prefs.getInt(kPrefTodaySteps) ?? 0;
    final screenTime = prefs.getInt(kPrefTodayScreenTime) ?? 0;

    try {
      // Load environment config
      await EnvConfig.load();

      // Inisialisasi Supabase di background isolate
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        publishableKey: EnvConfig.supabaseAnonKey,
      );

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final now = DateTime.now();
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        // Panggil ApiService langsung untuk sinkronisasi
        final apiService = ApiService();
        await apiService.syncSensors(
          date: dateStr,
          stepCount: steps,
          screenTimeMinutes: screenTime,
        );

        // Sinkronisasi data tertunda lainnya (food log, profile)
        final syncManager = SyncManager(apiService);
        await syncManager.syncPendingData();
      }
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }

    return true;
  });
}

/// [ID] Provider utama untuk mengontrol SensorService
/// [EN] Main provider to control SensorService
final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService(ref);
});

class SensorService with WidgetsBindingObserver {
  SensorService(this._ref);

  final Ref _ref;
  StreamSubscription<StepCount>? _stepSubscription;

  // WHY: channel name matches MainActivity.kt SCREEN_TIME_CHANNEL
  static const MethodChannel _screenTimeChannel = MethodChannel(
    'com.glicoo.glico/screen_time',
  );

  Timer? _screenTimeUpdateTimer;

  /// [ID]
  /// Menginisialisasi Workmanager untuk background execution.
  ///
  /// [EN]
  /// Initializes Workmanager for background execution.
  Future<void> initWorkmanager() async {
    await Workmanager().initialize(callbackDispatcher);

    // Registrasi periodic task (minimal 15 menit di Android)
    await Workmanager().registerPeriodicTask(
      '1',
      kBackgroundSyncTaskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// [ID]
  /// Menginisialisasi Pedometer & meminta permission jika diperlukan.
  ///
  /// [EN]
  /// Initializes Pedometer & requests permissions if required.
  Future<void> initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _startPedometerListener();
    }
  }

  /// [ID]
  /// Memulai polling screen time dari native ScreenTimeReceiver.
  ///
  /// [EN]
  /// Starts polling screen time from the native ScreenTimeReceiver.
  /// [WHY] Polling tetap diperlukan agar UI quest terupdate realtime
  ///        tanpa menunggu event SCREEN_OFF berikutnya.
  void initScreenTimeTracking() {
    WidgetsBinding.instance.addObserver(this);

    _screenTimeUpdateTimer?.cancel();
    _screenTimeUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateScreenTime(),
    );

    _updateScreenTime();
  }

  /// [ID]
  /// Menghentikan semua stream listener dan observer.
  ///
  /// [EN]
  /// Disposes all active stream listeners and observers.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepSubscription?.cancel();
    _screenTimeUpdateTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Pemicu sync manual ke server begitu app dibuka kembali
      _ref.read(syncManagerProvider).syncPendingData().catchError((_) {});
      _updateScreenTime();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateScreenTime();
    }
  }

  void _startPedometerListener() {
    _stepSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCountEvent,
      onError: _onStepCountError,
    );
  }

  Future<void> _onStepCountEvent(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final lastSyncDate = prefs.getString(kPrefLastSyncDate) ?? '';
    int offset = prefs.getInt(kPrefLastBootStepsOffset) ?? -1;

    // Jika ganti hari, offset diset ulang
    if (lastSyncDate != todayStr || offset == -1) {
      offset = event.steps;
      await prefs.setInt(kPrefLastBootStepsOffset, offset);
      await prefs.setString(kPrefLastSyncDate, todayStr);
      await prefs.setInt(kPrefTodayScreenTime, 0);
    }

    // Hitung langkah kaki hari ini
    final stepsToday = (event.steps - offset).clamp(0, 1000000);
    await prefs.setInt(kPrefTodaySteps, stepsToday);
  }

  void _onStepCountError(dynamic error) {
    debugPrint('Pedometer error: $error');
  }

  /// [ID]
  /// Ambil screen time hari ini dari native (detik), simpan ke SharedPreferences.
  ///
  /// [EN]
  /// Fetch today's screen time from native (seconds), persist to SharedPreferences.
  /// [WHY] ScreenTimeReceiver.kt akumulasi di SharedPreferences-nya sendiri (glico_screen_time);
  ///        nilai ini disalin ke kPrefTodayScreenTime (menit) untuk sync ke backend.
  Future<void> _updateScreenTime() async {
    try {
      final seconds =
          await _screenTimeChannel.invokeMethod<int>('getScreenTimeToday') ?? 0;
      final minutes = seconds ~/ 60;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kPrefTodayScreenTime, minutes);
    } catch (e) {
      debugPrint('Error getting screen time from native: $e');
    }
  }

  /// [ID]
  /// Sinkronisasi data sensor secara paksa (manual) ke backend.
  ///
  /// [EN]
  /// Forces manual synchronization of sensor data to the backend.
  Future<void> forceManualSync() async {
    final prefs = await SharedPreferences.getInstance();
    final steps = prefs.getInt(kPrefTodaySteps) ?? 0;
    final screenTime = prefs.getInt(kPrefTodayScreenTime) ?? 0;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      await _ref
          .read(apiServiceProvider)
          .syncSensors(
            date: dateStr,
            stepCount: steps,
            screenTimeMinutes: screenTime,
          );
    } catch (e) {
      debugPrint('Manual sensor sync failed: $e');
    }
  }
}
