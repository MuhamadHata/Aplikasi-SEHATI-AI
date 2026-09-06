// ==========================================
// LAYANAN PEDOMETER LATAR BELAKANG v2.0
// Enhanced anti-hallucination step counter with:
//  • Accelerometer pattern analysis for shake detection
//  • GPS correlation to validate steps with actual movement
//  • Multi-layer validation (rhythm + burst + GPS + accelerometer)
//  • Auto-start on boot with persistent foreground service
//  • Huawei Health-style persistent notification
// ==========================================

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ─── Konstanta ───────────────────────────────────────────────────────────────
const _chPedometer = 'sehati_pedometer_bg';
const _chPedometerMilestone = 'sehati_pedometer_milestone';
const _keyBgLastTotal = 'bg_pedo_last_total';
const _keyBgPassive = 'bg_pedo_passive';
const _keyBgDate = 'bg_pedo_date';
const _keyUserPrefix = 'bg_user_prefix';
const _keyBgAutoStart = 'bg_pedo_auto_start';
const _keyBgLastGpsSteps = 'bg_pedo_last_gps_steps';

// ─────────────────────────────────────────────────────────────────────────────
// ENHANCED STEP VALIDATOR — Multi-layer validation
// ─────────────────────────────────────────────────────────────────────────────
class EnhancedStepValidator {
  // ── Configuration ──────────────────────────────────────────────────────
  static const double _maxStepsPerSecond = 2.5; // Max realistic walking cadence
  static const int _minIntervalMs = 400; // ~150 spm max (walking), lari ~180 spm
  static const int _burstWindowMs = 2000; // 2 detik window
  static const int _maxEventsInBurst = 5; // Max 5 events per 2 detik

  // GPS correlation constants
  static const double _stepLengthMeters = 0.7; // Average step length

  // Accelerometer constants
  static const double _shakeThresholdMagnitude = 15.0; // m/s²
  static const int _accelerometerWindowSize = 50; // ~1 detik @ 50Hz

  // ── State ──────────────────────────────────────────────────────────────
  static int _lastSensorTotal = -1;
  static DateTime? _lastEventTime;
  static final List<DateTime> _recentEvents = [];

  // GPS correlation state
  static double _lastLatitude = 0.0;
  static double _lastLongitude = 0.0;
  static DateTime? _lastGpsTime;
  static double _accumulatedGpsDistanceM = 0.0;

  // Accelerometer state
  static final List<double> _accelMagnitudes = [];
  static bool _isShakeDetected = false;
  static DateTime? _lastShakeTime;

  // Stillness detection
  static bool _isStillnessLocked = false;
  static DateTime? _stillnessStartTime;
  static const Duration _stillnessThreshold = Duration(seconds: 8);

  // ── Public Getters ──────────────────────────────────────────────────────
  static bool get isShakeDetected => _isShakeDetected;
  static bool get isStillnessLocked => _isStillnessLocked;

  // ── Accelerometer Shake Detection ──────────────────────────────────────
  /// Process accelerometer data and detect if phone is being shaken
  static void processAccelerometer(double x, double y, double z) {
    // Calculate magnitude (排除重力)
    final magnitude = math.sqrt(x * x + y * y + z * z) - 9.8;
    final absMagnitude = magnitude.abs();

    _accelMagnitudes.add(absMagnitude);
    if (_accelMagnitudes.length > _accelerometerWindowSize) {
      _accelMagnitudes.removeAt(0);
    }

    // Check for shake pattern
    if (_accelMagnitudes.length >= 20) {
      _isShakeDetected = _detectShakePattern();
    }
  }

  static bool _detectShakePattern() {
    if (_accelMagnitudes.length < 20) return false;

    // Calculate statistics
    double sum = 0;
    double sumSq = 0;
    for (final m in _accelMagnitudes) {
      sum += m;
      sumSq += m * m;
    }
    final mean = sum / _accelMagnitudes.length;
    final variance = (sumSq / _accelMagnitudes.length) - (mean * mean);
    final stdDev = math.sqrt(math.max(0, variance));

    // Count high-magnitude events (potential shake)
    int highEvents = 0;
    for (final m in _accelMagnitudes) {
      if (m > _shakeThresholdMagnitude) highEvents++;
    }

    // Pattern indicators:
    // 1. High variance = irregular movement (shake)
    // 2. Many high-magnitude events = sustained shaking
    // 3. Very high stdDev = sudden jerky movements

    final varianceRatio = stdDev / (mean + 0.1);
    final highEventRatio = highEvents / _accelMagnitudes.length;

    // Shake pattern if:
    // - Variance ratio > 3.0 (irregular)
    // - OR high event ratio > 0.3 (sustained high magnitude)
    // - OR stdDev > 20 (very jerky)
    if (varianceRatio > 3.0 || highEventRatio > 0.3 || stdDev > 20) {
      _lastShakeTime = DateTime.now();
      return true;
    }

    return false;
  }

  /// Check if shake was recent (within last 500ms)
  static bool isRecentShake() {
    if (_lastShakeTime == null) return false;
    return DateTime.now().difference(_lastShakeTime!).inMilliseconds < 500;
  }

  // ── GPS Correlation ────────────────────────────────────────────────────
  /// Update GPS position for step correlation
  static void updateGpsPosition(double lat, double lon) {
    if (_lastLatitude != 0 && _lastLongitude != 0) {
      final dist = _calculateDistance(_lastLatitude, _lastLongitude, lat, lon);
      if (dist > 0.5 && dist < 100) { // Valid: 0.5m - 100m per update
        _accumulatedGpsDistanceM += dist;
      }
    }
    _lastLatitude = lat;
    _lastLongitude = lon;
    _lastGpsTime = DateTime.now();
  }

  /// Calculate distance between two GPS coordinates (Haversine)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Calculate expected steps from GPS distance
  static int get expectedStepsFromGps => (_accumulatedGpsDistanceM / _stepLengthMeters).round();

  /// Check if GPS has moved (phone is actually being carried while walking)
  static bool hasGpsMovement() {
    if (_lastGpsTime == null) return true; // First GPS fix, assume moving
    final elapsed = DateTime.now().difference(_lastGpsTime!).inSeconds;
    // Reset accumulation if GPS hasn't updated in 30 seconds
    if (elapsed > 30) {
      _accumulatedGpsDistanceM = 0;
      return false;
    }
    return _accumulatedGpsDistanceM > 5.0; // At least 5m movement
  }

  // ── Stillness Detection ───────────────────────────────────────────────
  /// Update stillness state based on accelerometer
  static void updateStillnessState(double speedKmh) {
    if (speedKmh > 0.5) {
      // User is moving
      _isStillnessLocked = false;
      _stillnessStartTime = null;
    } else if (!_isStillnessLocked && _stillnessStartTime == null) {
      // Start tracking stillness
      _stillnessStartTime = DateTime.now();
    } else if (_stillnessStartTime != null && !_isStillnessLocked) {
      final stillnessDuration = DateTime.now().difference(_stillnessStartTime!);
      if (stillnessDuration >= _stillnessThreshold) {
        _isStillnessLocked = true;
      }
    }
  }


  // ── Main Validation ──────────────────────────────────────────────────
  /// Validate step delta with multi-layer checks
  /// Returns the number of valid steps (0 = rejected)
  static int validate({
    required int currentSensorSteps,
    required DateTime now,
    double? currentSpeedKmh,
  }) {
    // ── Layer 0: Initial state ────────────────────────────────────────
    if (_lastSensorTotal < 0) {
      _lastSensorTotal = currentSensorSteps;
      _lastEventTime = now;
      return 0;
    }

    final rawDelta = currentSensorSteps - _lastSensorTotal;

    // ── Layer 1: Negative delta (reboot/counter wrap) ─────────────────
    if (rawDelta <= 0) {
      _lastSensorTotal = currentSensorSteps;
      _lastEventTime = now;
      return 0;
    }

    // ── Layer 2: Accelerometer shake detection ─────────────────────────
    if (_isShakeDetected || isRecentShake()) {
      debugPrint('[StepValidator] REJECT: Accelerometer shake detected');
      _lastSensorTotal = currentSensorSteps;
      _lastEventTime = now;
      return 0;
    }

    // ── Layer 3: Stillness lock ───────────────────────────────────────
    if (_isStillnessLocked) {
      debugPrint('[StepValidator] REJECT: Stillness locked - user is stationary');
      _lastSensorTotal = currentSensorSteps;
      _lastEventTime = now;
      return 0;
    }

    // ── Layer 4: Minimum interval ──────────────────────────────────────
    if (_lastEventTime != null) {
      final intervalMs = now.difference(_lastEventTime!).inMilliseconds;

      // Very fast events (<200ms) with any delta > 1 = suspicious
      if (intervalMs < 200 && rawDelta > 1) {
        debugPrint('[StepValidator] REJECT: Interval ${intervalMs}ms too short for delta=$rawDelta');
        _lastSensorTotal = currentSensorSteps;
        _lastEventTime = now;
        return 0;
      }

      // Fast events (<400ms) with large delta = suspicious
      if (intervalMs < _minIntervalMs && rawDelta > 3) {
        debugPrint('[StepValidator] REJECT: Interval ${intervalMs}ms too short for delta=$rawDelta');
        _lastSensorTotal = currentSensorSteps;
        _lastEventTime = now;
        return 0;
      }
    }

    // ── Layer 5: Burst detection ────────────────────────────────────────
    _recentEvents.removeWhere(
      (t) => now.difference(t).inMilliseconds > _burstWindowMs,
    );
    _recentEvents.add(now);

    if (_recentEvents.length >= _maxEventsInBurst) {
      debugPrint('[StepValidator] REJECT: Burst ${_recentEvents.length} events in ${_burstWindowMs}ms');
      _lastSensorTotal = currentSensorSteps;
      _lastEventTime = now;
      // Give 1 step max during burst (conservative)
      return math.min(rawDelta, 1);
    }

    // ── Layer 6: Rate limiting (steps per second) ──────────────────
    if (_lastEventTime != null) {
      final intervalSec = now.difference(_lastEventTime!).inMilliseconds / 1000.0;
      if (intervalSec > 0 && intervalSec < 5.0) {
        final stepsPerSec = rawDelta / intervalSec;
        if (stepsPerSec > _maxStepsPerSecond) {
          debugPrint('[StepValidator] REJECT: ${stepsPerSec.toStringAsFixed(1)} steps/sec > $_maxStepsPerSecond');
          final realisticMax = (_maxStepsPerSecond * intervalSec).ceil();
          _lastSensorTotal = currentSensorSteps;
          _lastEventTime = now;
          return math.min(rawDelta, realisticMax.clamp(1, _maxEventsInBurst));
        }
      }
    }

    // ── Layer 7: GPS correlation (if speed available) ──────────────────
    if (currentSpeedKmh != null && currentSpeedKmh > 0.5) {
      // User is moving according to GPS - validate steps correlate
      final expectedSteps = (currentSpeedKmh * 1000 / 3600 * 10 / _stepLengthMeters).round();
      if (rawDelta > expectedSteps * 3) {
        debugPrint('[StepValidator] REJECT: $rawDelta steps >> expected $expectedSteps from GPS');
        _lastSensorTotal = currentSensorSteps;
        _lastEventTime = now;
        return math.min(rawDelta, expectedSteps);
      }
    }

    // ── Layer 8: Cap delta per event ──────────────────────────────────
    final cappedDelta = math.min(rawDelta, _maxEventsInBurst * 2);

    // ── All validations passed ─────────────────────────────────────────
    _lastSensorTotal = currentSensorSteps;
    _lastEventTime = now;

    debugPrint('[StepValidator] ACCEPT: $cappedDelta steps');
    return cappedDelta;
  }

  /// Reset all state (called at day change)
  static void reset() {
    _lastSensorTotal = -1;
    _lastEventTime = null;
    _recentEvents.clear();
    _lastLatitude = 0;
    _lastLongitude = 0;
    _lastGpsTime = null;
    _accumulatedGpsDistanceM = 0;
    _accelMagnitudes.clear();
    _isShakeDetected = false;
    _lastShakeTime = null;
    _isStillnessLocked = false;
    _stillnessStartTime = null;
  }

  /// Reset only GPS accumulation (called periodically to recalibrate)
  static void resetGpsAccumulation() {
    _accumulatedGpsDistanceM = 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PEDOMETER BACKGROUND SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class PedometerBackgroundService {
  PedometerBackgroundService._();
  static final instance = PedometerBackgroundService._();

  static const String _channelId = 'sehati_pedometer_bg';
  static const String _channelMilestoneId = 'sehati_pedometer_milestone';

  /// Initialize notification channels
  Future<void> initialize() async {
    final plugin = FlutterLocalNotificationsPlugin();

    // Main pedometer channel (low importance - no sound)
    await plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        'Penghitung Langkah',
        description: 'Menghitung langkah kaki secara real-time',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ));

    // Milestone channel (high importance - with sound)
    await plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        _channelMilestoneId,
        'Pencapaian Langkah',
        description: 'Notifikasi pencapaian target langkah',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ));
  }

  /// Start continuous step tracking
  static Future<void> startContinuousTracking({
    required String userPrefix,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserPrefix, userPrefix);
    await prefs.setBool(_keyBgAutoStart, true);
    await prefs.setBool('bg_pedo_enabled', true);

    // Start the background service if not running
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
    service.invoke('startPedometer', {'prefix': userPrefix});

    debugPrint('[PedometerBG] Continuous tracking started for: $userPrefix');
  }

  /// Stop continuous step tracking
  static Future<void> stopContinuousTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBgAutoStart, false);
    await prefs.setBool('bg_pedo_enabled', false);

    final service = FlutterBackgroundService();
    service.invoke('stopPedometer');

    debugPrint('[PedometerBG] Continuous tracking stopped');
  }

  /// Sync step count from sensor to SharedPreferences
  static Future<void> syncStepToPrefs(int currentSensorSteps) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final lastDate = prefs.getString(_keyBgDate) ?? '';
    final savedPassive = prefs.getInt(_keyBgPassive) ?? 0;

    // Day change - reset everything
    if (lastDate != today) {
      final prefix = prefs.getString(_keyUserPrefix) ?? 'guest_';

      // Arsipkan langkah hari kemarin sebelum di-reset agar riwayat tidak hilang
      if (lastDate.isNotEmpty && savedPassive > 0) {
        try {
          final historyListJson = prefs.getString('${prefix}dailySummaries');
          List<dynamic> list = [];
          if (historyListJson != null) {
            final decoded = jsonDecode(historyListJson);
            if (decoded is List) list = decoded;
          }
          final bool alreadyExists =
              list.any((e) => e is Map && e['date'] == lastDate);
          if (!alreadyExists) {
            final calConsumed = prefs.getInt('${prefix}calorieConsumed') ?? 0;
            final water = prefs.getInt('${prefix}waterGlasses') ?? 0;
            final calBurned = (savedPassive * 0.03).round();
            list.insert(0, {
              'date': lastDate,
              'steps': savedPassive,
              'caloriesBurned': calBurned,
              'caloriesConsumed': calConsumed,
              'waterGlasses': water,
              'sleepHours': 0.0,
              'isSmoker': false,
              'foodLogs': [],
            });
            if (list.length > 30) list = list.sublist(0, 30);
            await prefs.setString('${prefix}dailySummaries', jsonEncode(list));
            debugPrint(
                '[PedometerBG] Archived $savedPassive steps for date $lastDate');
          }
        } catch (e) {
          debugPrint('[PedometerBG] Error archiving daily summary: $e');
        }
      }

      await prefs.setString(_keyBgDate, today);
      await prefs.setInt(_keyBgPassive, 0);
      await prefs.setInt(_keyBgLastTotal, currentSensorSteps);
      await prefs.setInt(_keyBgLastGpsSteps, 0);
      EnhancedStepValidator.reset();

      await prefs.setInt('${prefix}passiveSteps', 0);
      await prefs.setInt('${prefix}lastKnownTotalSteps', currentSensorSteps);
      return;
    }

    final lastTotal = prefs.getInt(_keyBgLastTotal) ?? -1;
    if (lastTotal < 0) {
      await prefs.setInt(_keyBgLastTotal, currentSensorSteps);
      return;
    }

    // Validate with enhanced multi-layer validator
    final validatedDelta = EnhancedStepValidator.validate(
      currentSensorSteps: currentSensorSteps,
      now: DateTime.now(),
    );

    if (validatedDelta <= 0) {
      await prefs.setInt(_keyBgLastTotal, currentSensorSteps);
      return;
    }

    final newPassive = savedPassive + validatedDelta;

    await prefs.setInt(_keyBgPassive, newPassive);
    await prefs.setInt(_keyBgLastTotal, currentSensorSteps);

    // Update provider steps
    final prefix = prefs.getString(_keyUserPrefix) ?? 'guest_';
    final providerSteps = prefs.getInt('${prefix}passiveSteps') ?? 0;
    if (newPassive > providerSteps) {
      await prefs.setInt('${prefix}passiveSteps', newPassive);
      await prefs.setInt('${prefix}lastKnownTotalSteps', currentSensorSteps);
    }
  }

  /// Update GPS position for step correlation
  static void updateGpsPosition(double lat, double lon) {
    EnhancedStepValidator.updateGpsPosition(lat, lon);
  }

  /// Process accelerometer for shake detection
  static void processAccelerometer(double x, double y, double z) {
    EnhancedStepValidator.processAccelerometer(x, y, z);
  }

  /// Update stillness state
  static void updateStillnessState(double speedKmh) {
    EnhancedStepValidator.updateStillnessState(speedKmh);
  }
}

String _todayStr() {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND SERVICE ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void onStartPedometer(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final plugin = FlutterLocalNotificationsPlugin();

  // Initialize notifications
  await plugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  ));

  // Create notification channels
  await plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(const AndroidNotificationChannel(
      _chPedometer,
      'Penghitung Langkah Aktif',
      description: 'Menghitung langkah kaki secara real-time',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    ));

  await plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(const AndroidNotificationChannel(
      _chPedometerMilestone,
      'Pencapaian Langkah',
      description: 'Notifikasi pencapaian target langkah',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ));

  // ── State ──────────────────────────────────────────────────────────────
  StreamSubscription<StepCount>? stepSub;
  StreamSubscription<AccelerometerEvent>? accelSub;
  StreamSubscription<Position>? gpsSub;

  int lastNotifiedSteps = -1;
  final Set<int> notifiedMilestones = {};

  String userPrefix = 'guest_';

  // ── Notification Helpers ───────────────────────────────────────────────
  Future<void> updateNotificationFn(int steps) async {
    if (service is! AndroidServiceInstance) return;

    final prefs = await SharedPreferences.getInstance();
    final target = prefs.getInt('${userPrefix}stepTarget') ??
        prefs.getInt('global_step_target') ??
        10000;
    final progress = (steps / target * 100).clamp(0, 100).round();

    service.setForegroundNotificationInfo(
      title: '👟 SEHATI-AI Langkah Aktif',
      content: '$steps langkah ($progress% target)',
    );
  }

  Future<void> showMilestoneFn(int milestone) async {
    String title;
    String body;
    String emoji;

    if (milestone >= 20000) {
      emoji = '🔥';
      title = 'Super Aktiv!';
      body = '$milestone langkah! Kamu超级活跃！';
    } else if (milestone >= 15000) {
      emoji = '🌟';
      title = 'Luar Biasa!';
      body = '$milestone langkah - luar biasa!';
    } else if (milestone >= 10000) {
      emoji = '🏆';
      title = 'Target Tercapai!';
      body = '🎊 10.000 langkah hari ini!';
    } else if (milestone >= 5000) {
      emoji = '⭐';
      title = 'Setengah jalan!';
      body = '$milestone langkah - terus semangat!';
    } else {
      emoji = '🎉';
      title = 'Pencapaian!';
      body = '$milestone langkah tercapai!';
    }

    await plugin.show(
      milestone,
      '$emoji $title',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _chPedometerMilestone,
          'Pencapaian Langkah',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.event,
        ),
      ),
    );
  }

  Future<void> checkMilestonesFn(int steps, Set<int> milestones) async {
    const allMilestones = [2500, 5000, 7500, 10000, 12500, 15000, 20000];

    for (final m in allMilestones) {
      if (steps >= m && !milestones.contains(m)) {
        milestones.add(m);
        await showMilestoneFn(m);
      }
    }
  }

  // ── Accelerometer Stream ────────────────────────────────────────────────
  void startAccelerometerStream() {
    accelSub?.cancel();
    accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20), // ~50Hz
    ).listen((event) {
      EnhancedStepValidator.processAccelerometer(event.x, event.y, event.z);
    }, onError: (e) {
      debugPrint('[PedometerBG] Accelerometer error: $e');
    });
  }

  // ── GPS Stream ────────────────────────────────────────────────────────
  void startGpsStream() {
    gpsSub?.cancel();
    gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // meters
      ),
    ).listen((pos) {
      EnhancedStepValidator.updateGpsPosition(pos.latitude, pos.longitude);
      EnhancedStepValidator.updateStillnessState(pos.speed * 3.6); // m/s to km/h
    }, onError: (e) {
      debugPrint('[PedometerBG] GPS error: $e');
    });
  }

  // ── Step Stream ────────────────────────────────────────────────────────
  void startStepStream() {
    stepSub?.cancel();
    stepSub = Pedometer.stepCountStream.listen(
      (StepCount event) async {
        // Sync to SharedPreferences
        await PedometerBackgroundService.syncStepToPrefs(event.steps);

        // Send update to UI
        final prefs = await SharedPreferences.getInstance();
        final passive = prefs.getInt('${userPrefix}passiveSteps') ?? 0;

        service.invoke('pedometerUpdate', {
          'passiveSteps': passive,
          'sensorSteps': event.steps,
          'isShaking': EnhancedStepValidator.isShakeDetected,
          'isStill': EnhancedStepValidator.isStillnessLocked,
        });

        // Update notification every 50 steps
        if ((passive - lastNotifiedSteps).abs() >= 50 || lastNotifiedSteps < 0) {
          lastNotifiedSteps = passive;
          await updateNotificationFn(passive);
        }

        // Check milestones
        await checkMilestonesFn(passive, notifiedMilestones);
      },
      onError: (e) {
        debugPrint('[PedometerBG] StepCount error: $e');
      },
    );
  }

  service.on('startPedometer').listen((data) async {
    debugPrint('[PedometerBG] startPedometer command received');

    if (data != null && data['prefix'] != null) {
      userPrefix = data['prefix'];
    }

    final status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      startStepStream();
      startAccelerometerStream();
      startGpsStream();

      // Set as foreground
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
      }
    }
  });

  service.on('stopPedometer').listen((_) async {
    debugPrint('[PedometerBG] stopPedometer command received');
    await stepSub?.cancel();
    await accelSub?.cancel();
    await gpsSub?.cancel();
    await service.stopSelf();
  });

  service.on('updatePrefix').listen((data) async {
    if (data == null) return;
    final prefix = data['prefix'] as String?;
    if (prefix != null) {
      userPrefix = prefix;
      await (await SharedPreferences.getInstance()).setString(_keyUserPrefix, prefix);
    }
  });

  service.on('updateTarget').listen((data) async {
    final prefs = await SharedPreferences.getInstance();
    final steps = prefs.getInt('${userPrefix}passiveSteps') ?? 0;
    await updateNotificationFn(steps);
  });

  // ── Start streams if permissions granted ───────────────────────────────
  final status = await Permission.activityRecognition.status;
  if (status.isGranted) {
    startStepStream();
    startAccelerometerStream();

    // Start GPS for correlation (if location permission)
    final locStatus = await Permission.location.status;
    if (locStatus.isGranted) {
      startGpsStream();
    }

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
  }

  // ── Periodic notification update ──────────────────────────────────────
  Timer.periodic(const Duration(seconds: 30), (_) async {
    final prefs = await SharedPreferences.getInstance();
    final steps = prefs.getInt('${userPrefix}passiveSteps') ?? 0;
    await updateNotificationFn(steps);
  });

  // ── Service callbacks ──────────────────────────────────────────────────
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) => service.setAsForegroundService());
    service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
  }
}
