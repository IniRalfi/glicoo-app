// notification_service.dart
//
// Purpose:
// Local notification manager to handle daily health checks & reminders.
//
// Used By:
// main.dart, profile_screen.dart
//
// Depends On:
// flutter_local_notifications, timezone

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// [ID] Inisialisasi plugin notifikasi lokal dan timezone data.
  /// [EN] Initializes local notification plugin and timezone data.
  Future<void> init() async {
    tz.initializeTimeZones();
    // Default location to Asia/Jakarta (WIB)
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Fallback jika timezone lokal tidak ditemukan
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification clicked: ${details.payload}");
      },
    );
  }

  /// [ID] Meminta izin akses notifikasi untuk Android 13+ dan iOS.
  /// [EN] Requests notification permission for Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    bool? androidGranted = false;
    bool? iosGranted = false;

    // Android 13+
    final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      androidGranted = await androidImpl.requestNotificationsPermission();
    }

    // iOS
    final iosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      iosGranted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  /// [ID] Menjadwalkan pengingat harian pada jam tertentu.
  /// [EN] Schedules a daily reminder at a specific hour and minute.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'glicoo_reminders',
          'Pengingat Glicoo',
          channelDescription: 'Pengingat harian untuk aktivitas dan cek gizi',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// [ID] Mengirim notifikasi instan langsung untuk keperluan pengujian.
  /// [EN] Sends instant notification immediately for testing purposes.
  Future<void> showInstantTestNotification() async {
    await _notificationsPlugin.show(
      999,
      'Tes Notifikasi Glicoo! 🍌',
      'Yay! Notifikasi lokal di aplikasi Glicoo berfungsi dengan sempurna.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'glicoo_test',
          'Uji Coba Notifikasi',
          channelDescription: 'Saluran pengujian notifikasi instan',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// [ID] Menjadwalkan seluruh rutinitas pengingat default Glicoo (pagi jam 08:00 dan malam jam 21:00).
  /// [EN] Schedules all default Glicoo routines (morning 08:00 and night 21:00).
  Future<void> scheduleDefaultGlicooReminders() async {
    // 1. Morning Check (08:00 AM)
    await scheduleDailyNotification(
      id: 101,
      title: 'Pagi! Waktunya Bergerak Semangat 🏃‍♂️',
      body: 'Iloo di sini! Jangan lupa cek misi langkah kaki hari ini agar tetap bugar dan terhindar dari diabetes ya.',
      hour: 8,
      minute: 0,
    );

    // 2. Night Check (09:00 PM)
    await scheduleDailyNotification(
      id: 102,
      title: 'Sudah Malam, Waktunya Istirahat 🌙',
      body: 'Bagaimana aktivitasmu hari ini? Jangan lupa catat menu makan malammu dan siapkan waktu tidur yang cukup ya.',
      hour: 21,
      minute: 0,
    );
  }

  /// [ID] Membatalkan seluruh jadwal notifikasi harian.
  /// [EN] Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
