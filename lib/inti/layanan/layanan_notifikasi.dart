// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _trackingChannelId = 'nubi_tracking_realtime';
  static const String _milestoneChannelId = 'nubi_milestone';
  static const String _waterChannelId = 'water_channel_v2';
  static const String _exerciseChannelId = 'exercise_channel_v2';

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create notification channels
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Channel untuk tracking real-time (low importance = tidak bunyi, tidak getar)
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _trackingChannelId,
        'Tracking Real-Time',
        description: 'Update langkah dan kalori saat aktivitas berjalan',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    );

    // Channel untuk milestone (high importance = pop-up)
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _milestoneChannelId,
        'Pencapaian Langkah',
        description: 'Notifikasi saat mencapai target langkah',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Channel untuk air
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _waterChannelId,
        'Pengingat Air',
        description: 'Pengingat untuk minum air',
        importance: Importance.high,
        playSound: true,
      ),
    );

    // Channel untuk olahraga
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _exerciseChannelId,
        'Pengingat Olahraga',
        description: 'Pengingat untuk berolahraga',
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  Future<void> requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  InitializationSettings initialSettings() {
    return const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'));
  }

  /// Tampilkan notifikasi biasa (pop-up)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'nubi_main_channel_v2',
      'SEHATI-AI Notifications',
      channelDescription: 'Channel for general SEHATI-AI notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      channelShowBadge: true,
      category: AndroidNotificationCategory.reminder,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Tampilkan ongoing notification saat tracking dimulai
  Future<void> showTrackingNotification({
    required String activityType,
    int seconds = 0,
    int steps = 0,
    int calories = 0,
  }) async {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    final emoji = activityType == 'Lari' ? '🏃' : '🚶';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _trackingChannelId,
      'Tracking Real-Time',
      channelDescription: 'Update langkah dan kalori saat aktivitas berjalan',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: false,
      channelShowBadge: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.service,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      '$emoji SEHATI-AI $activityType Aktif',
      '$mins:$secs • $steps langkah • $calories kkal',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Update konten ongoing notification (dipanggil tiap detik dari provider)
  Future<void> updateTrackingNotification({
    required String activityType,
    required int seconds,
    required int steps,
    required int calories,
    bool isPaused = false,
  }) async {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    final emoji = activityType == 'Lari' ? '🏃' : '🚶';
    final statusText = isPaused ? ' (Dijeda)' : '';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _trackingChannelId,
      'Tracking Real-Time',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: false,
      channelShowBadge: false,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.service,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      '$emoji SEHATI-AI $activityType$statusText',
      '$mins:$secs • $steps langkah • $calories kkal',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Hapus ongoing tracking notification
  Future<void> cancelTrackingNotification() async {
    await flutterLocalNotificationsPlugin.cancel(999);
  }

  // Milestone yang sudah ditampilkan (session-based, reset saat tracking stop)
  final Set<int> _shownMilestones = {};

  void resetMilestones() {
    _shownMilestones.clear();
  }

  /// Cek & tampilkan notifikasi milestone langkah
  Future<void> checkAndShowStepMilestone(int totalSteps) async {
    final milestones = [2500, 5000, 7500, 10000, 15000, 20000];

    for (final milestone in milestones) {
      if (totalSteps >= milestone && !_shownMilestones.contains(milestone)) {
        _shownMilestones.add(milestone);

        String emoji = '🎉';
        String title = 'Pencapaian Langkah!';
        String body = '';

        if (milestone == 10000) {
          emoji = '🏆';
          title = 'Target Harian Tercapai! 🎊';
          body = '10.000 langkah hari ini. Luar biasa!';
        } else if (milestone == 5000) {
          emoji = '⭐';
          title = 'Setengah Target! ⭐';
          body = '5.000 langkah — kamu udah di tengah jalan!';
        } else if (milestone >= 15000) {
          emoji = '🔥';
          title = 'Melampaui Target! 🔥';
          body = '$milestone langkah — kamu luar biasa hari ini!';
        } else {
          body = '$milestone langkah tercapai! Terus semangat! $emoji';
        }

        await flutterLocalNotificationsPlugin.show(
          5000 + milestone,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _milestoneChannelId,
              'Pencapaian Langkah',
              importance: Importance.high,
              priority: Priority.high,
              channelShowBadge: true,
              icon: '@mipmap/ic_launcher',
              category: AndroidNotificationCategory.event,
            ),
          ),
        );

        break; // Tampilkan satu per satu
      }
    }
  }

  Future<void> evaluateAndSchedule(
      int waterConsumed, int waterTarget, int caloriesBurned,
      {String fastingMode = 'none',
      int ramadanIftarMinute = 18 * 60,
      int ramadanSuhoorEndMinute = 4 * 60 + 30,
      int ifEatStartMinute = 12 * 60,
      int ifEatEndMinute = 20 * 60}) async {
    // Batalkan semua jadwal sebelumnya agar tidak dobel
    // Tapi jangan batalkan tracking notification (id 999)
    final pendingNotifs =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    for (final notif in pendingNotifs) {
      if (notif.id != 999) {
        await flutterLocalNotificationsPlugin.cancel(notif.id);
      }
    }

    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime nextAtHour(int hour) {
      var t = tz.TZDateTime.local(now.year, now.month, now.day, hour, 0, 0);
      if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
      return t;
    }

    tz.TZDateTime nextAtMinute(int minuteOfDay) {
      final h = (minuteOfDay ~/ 60).clamp(0, 23);
      final m = (minuteOfDay % 60).clamp(0, 59);
      var t = tz.TZDateTime.local(now.year, now.month, now.day, h, m, 0);
      if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
      return t;
    }

    // Aturan Waktu Minum Air
    final List<MapEntry<int, int>> waterMilestones = (fastingMode == 'ramadan')
        ? [
            MapEntry((ramadanIftarMinute + 30) % 1440, 2),
            MapEntry((ramadanIftarMinute + 150) % 1440, 4),
            const MapEntry(23 * 60, 6),
            MapEntry((ramadanSuhoorEndMinute + 1440 - 30) % 1440, 8),
          ]
        : const [
            MapEntry(9 * 60, 1),
            MapEntry(12 * 60, 3),
            MapEntry(15 * 60, 5),
            MapEntry(18 * 60, 7),
            MapEntry(21 * 60, 8),
          ];

    // Penjadwalan Air
    for (final entry in waterMilestones) {
      final minuteOfDay = entry.key;
      final expectedGlasses = entry.value;

      final proportion = expectedGlasses / 8.0;
      final actualExpected = (waterTarget * proportion).ceil();

      if (waterConsumed < actualExpected) {
        final scheduledTime = nextAtMinute(minuteOfDay);
        await _scheduleNotification(
          id: 200000 + minuteOfDay,
          title: 'Waktunya Minum Air 💧',
          body:
              'Jangan sampai dehidrasi! Pastikan sudah minum minimal $actualExpected gelas.',
          scheduledTime: scheduledTime,
          channelId: _waterChannelId,
        );
      }
    }

    // Penjadwalan Olahraga
    if (caloriesBurned == 0) {
      if (fastingMode == 'ramadan') {
        await _scheduleNotification(
          id: 1004,
          title: 'Aktivitas Ringan Malam',
          body:
              'Setelah berbuka, coba jalan ringan atau peregangan 10-15 menit.',
          scheduledTime: nextAtMinute((ramadanIftarMinute + 120) % 1440),
          channelId: _exerciseChannelId,
        );
        return;
      }
      await _scheduleNotification(
        id: 1001,
        title: 'Olahraga Pagi 🌅',
        body: 'Awali harimu dengan olahraga ringan 10 menit.',
        scheduledTime: nextAtHour(9),
        channelId: _exerciseChannelId,
      );
      await _scheduleNotification(
        id: 1002,
        title: 'Waktunya Bergerak! 🏃‍♀️',
        body: 'Sepertinya kamu belum berolahraga hari ini. Yuk gerak sejenak!',
        scheduledTime: nextAtHour(15),
        channelId: _exerciseChannelId,
      );
      await _scheduleNotification(
        id: 1003,
        title: 'Olahraga Sore 🌇',
        body: 'Masih ada waktu untuk berolahraga sebelum malam tiba.',
        scheduledTime: nextAtHour(18),
        channelId: _exerciseChannelId,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required String channelId,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
          channelShowBadge: true,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
