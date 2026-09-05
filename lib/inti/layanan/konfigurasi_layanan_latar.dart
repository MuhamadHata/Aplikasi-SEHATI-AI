// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Konfigurasi dan kontrol Flutter Background Service untuk:
/// - GPS tracking tetap berjalan saat app ditutup
/// - Timer penghitung waktu sesi lari
/// - Notifikasi foreground yang terupdate real-time
class BackgroundServiceConfig {
  static const String _channelId = 'nubi_tracking';
  static const int _notifId = 888;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Setup foreground notification channel
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      'SEHATI-AI Tracking Aktif',
      description: 'Notifikasi saat sesi aktivitas sedang berjalan',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: '🏃 SEHATI-AI sedang merekam aktivitas',
        initialNotificationContent: '00:00 • 0 langkah • 0 kkal',
        foregroundServiceNotificationId: _notifId,
        foregroundServiceTypes: [AndroidForegroundType.location, AndroidForegroundType.health],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Mulai background service saat user memulai tracking
  static Future<void> startService({
    required String activityType,
  }) async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
    // Kirim sinyal ke service untuk mulai tracking
    service.invoke('startTracking', {
      'type': activityType,
    });
  }

  /// Stop background service saat tracking selesai
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  /// Pause tracking di background
  static Future<void> pauseService() async {
    FlutterBackgroundService().invoke('pauseTracking');
  }

  /// Resume tracking di background
  static Future<void> resumeService() async {
    FlutterBackgroundService().invoke('resumeTracking');
  }

  /// Cek apakah service sedang berjalan
  static Future<bool> isRunning() async {
    return await FlutterBackgroundService().isRunning();
  }

  static bool get isAvailable => true;
}

/// Entry point background service (Android & iOS foreground)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final FlutterLocalNotificationsPlugin notifPlugin =
      FlutterLocalNotificationsPlugin();

  // State lokal di isolate
  bool isPaused = false;
  bool isTracking = false;
  String activityType = 'Lari';
  int seconds = 0;
  double distanceKm = 0.0;
  double lastLat = 0, lastLon = 0;
  bool hasLastPos = false;

  // Setup notifikasi di background
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifPlugin
      .initialize(const InitializationSettings(android: initSettingsAndroid));

  int calculateSessionCalories(int seconds, double distanceKm) {
    if (seconds <= 0 || distanceKm <= 0) return 0;
    final met = activityType == 'Lari' ? 9.0 : 3.5;
    return (met * 70.0 * (seconds / 3600)).round();
  }

  Future<void> updateNotification() async {
    if (service is! AndroidServiceInstance) return;
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    final calories = calculateSessionCalories(seconds, distanceKm);
    final steps = (distanceKm * 1400).round();
    final emoji = activityType == 'Lari' ? '🏃' : '🚶';

    // After is! check, Dart promotes service to AndroidServiceInstance
    service.setForegroundNotificationInfo(
      title: '$emoji SEHATI-AI $activityType ${isPaused ? "(Dijeda)" : "Aktif"}',
      content: '$mins:$secs • $steps langkah • $calories kkal',
    );
  }

  // Kirim data ke UI
  void sendUpdate() {
    service.invoke('trackingUpdate', {
      'seconds': seconds,
      'distanceKm': distanceKm,
      'isPaused': isPaused,
      'isTracking': isTracking,
      'activityType': activityType,
    });
  }

  // Listen commands dari UI
  service.on('stopService').listen((_) async {
    isTracking = false;
    await service.stopSelf();
  });

  service.on('startTracking').listen((data) {
    if (data != null) {
      activityType = data['type'] ?? 'Lari';
    }
    isTracking = true;
    isPaused = false;
    seconds = 0;
    distanceKm = 0.0;
    hasLastPos = false;
    sendUpdate();
  });

  service.on('pauseTracking').listen((_) {
    isPaused = true;
    sendUpdate();
    updateNotification();
  });

  service.on('resumeTracking').listen((_) {
    isPaused = false;
    sendUpdate();
    updateNotification();
  });

  // Timer setiap detik
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (isTracking && !isPaused) {
      seconds++;
      sendUpdate();
      if (seconds % 5 == 0) {
        await updateNotification();
      }
    }
  });

  // GPS stream di background
  StreamSubscription<Position>? posSubscription;

  void startGpsStream() {
    posSubscription?.cancel();
    posSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen((Position pos) {
      if (!isTracking || isPaused) return;

      if (hasLastPos) {
        final dist = Geolocator.distanceBetween(
          lastLat,
          lastLon,
          pos.latitude,
          pos.longitude,
        );
        if (dist > 2) {
          distanceKm += dist / 1000;
          service.invoke('gpsUpdate', {
            'lat': pos.latitude,
            'lon': pos.longitude,
            'distanceKm': distanceKm,
          });
        }
      }

      lastLat = pos.latitude;
      lastLon = pos.longitude;
      hasLastPos = true;
    });
  }

  // Cek apakah ada tracking aktif yang tersimpan (app restart recovery)
  final prefs = await SharedPreferences.getInstance();
  final savedTracking = prefs.getBool('bg_tracking_active') ?? false;
  if (savedTracking) {
    isTracking = true;
    activityType = prefs.getString('bg_tracking_type') ?? 'Lari';
    seconds = prefs.getInt('bg_tracking_seconds') ?? 0;
    distanceKm = prefs.getDouble('bg_tracking_distance') ?? 0.0;
    startGpsStream();
    sendUpdate();
    updateNotification();
  }

  // Listen start tracking -> mulai GPS
  service.on('startTracking').listen((_) {
    startGpsStream();
  });

  // Simpan state secara berkala agar recovery bisa dilakukan
  Timer.periodic(const Duration(seconds: 10), (_) async {
    if (isTracking) {
      final p = await SharedPreferences.getInstance();
      await p.setBool('bg_tracking_active', true);
      await p.setString('bg_tracking_type', activityType);
      await p.setInt('bg_tracking_seconds', seconds);
      await p.setDouble('bg_tracking_distance', distanceKm);
    }
  });

  // Cleanup saat stop
  service.on('stopService').listen((_) async {
    posSubscription?.cancel();
    final p = await SharedPreferences.getInstance();
    await p.remove('bg_tracking_active');
    await p.remove('bg_tracking_type');
    await p.remove('bg_tracking_seconds');
    await p.remove('bg_tracking_distance');
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}
