// ============================================================
// VALIDASI KONTEKS — Context Validator untuk Activity Recognition v2.0
// ============================================================
// Layer terakhir sebelum step/aktivitas diterima:
//  • Accelerometer pattern analysis untuk deteksi goyangan HP
//  • GPS correlation untuk validasi langkah dengan movement sungguhan
//  • Rhythm-based heuristic untuk burst detection
//  • Stillness lock untuk deteksi diam
//  • Multi-layer validation (accelerometer + GPS + rhythm)
// ============================================================

import 'dart:math' as math;
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Hasil validasi konteks
// ─────────────────────────────────────────────────────────────────────────────
class ContextValidationResult {
  final bool isValid;
  final String rejectionReason;
  final int validSteps;

  const ContextValidationResult.valid({
    this.validSteps = 1,
  })  : isValid = true,
        rejectionReason = '';

  const ContextValidationResult.rejected({
    required this.rejectionReason,
    this.validSteps = 0,
  }) : isValid = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// ValidasiKonteks — enhanced context manager with GPS correlation
// ─────────────────────────────────────────────────────────────────────────────
class ValidasiKonteks {
  // ── Konfigurasi ─────────────────────────────────────────────────────────────
  /// Max langkah nyata per detik — diperketat untuk cegah burst
  static const double _maxStepsPerSecond = 2.5;

  /// Minimum interval langkah (ms) — diperketat untuk tolak burst
  static const int _minStepIntervalMs = 400;

  /// Burst window: max events per window
  static const int _maxStepsPerWindow = 4;
  static const Duration _burstWindow = Duration(seconds: 1);

  /// Stillness threshold sebelum lock (detik)
  static const Duration _stillnessThreshold = Duration(seconds: 8);

  /// Step length dalam meter
  static const double _stepLengthMeters = 0.7;

  // ── Accelerometer Shake Detection ───────────────────────────────────────
  static const double _shakeThresholdMagnitude = 15.0; // m/s²
  static const int _accelerometerWindowSize = 50;
  final List<double> _accelMagnitudes = [];
  bool _isShakeDetected = false;
  DateTime? _lastShakeTime;

  // ── GPS Correlation State ────────────────────────────────────────────────
  double _lastLat = 0.0;
  double _lastLon = 0.0;
  DateTime? _lastGpsTime;
  double _accumulatedGpsDistanceM = 0.0;

  // ── Step Validation State ────────────────────────────────────────────────
  DateTime? _lastStepTime;
  final List<DateTime> _recentSteps = [];

  // ── Stillness Detection ────────────────────────────────────────────────
  bool _isStillnessLocked = false;
  DateTime? _stillnessStartTime;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Process accelerometer data
  void processAccelerometer(double x, double y, double z) {
    // Calculate magnitude (excluding gravity ~9.8)
    final magnitude = math.sqrt(x * x + y * y + z * z) - 9.8;
    final absMagnitude = magnitude.abs();

    _accelMagnitudes.add(absMagnitude);
    if (_accelMagnitudes.length > _accelerometerWindowSize) {
      _accelMagnitudes.removeAt(0);
    }

    // Check for shake pattern
    if (_accelMagnitudes.length >= 20) {
      _detectShakePattern();
    }
  }

  void _detectShakePattern() {
    if (_accelMagnitudes.length < 20) return;

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

    // Count high-magnitude events
    int highEvents = 0;
    for (final m in _accelMagnitudes) {
      if (m > _shakeThresholdMagnitude) highEvents++;
    }

    final varianceRatio = stdDev / (mean + 0.1);
    final highEventRatio = highEvents / _accelMagnitudes.length;

    // Shake pattern detection
    if (varianceRatio > 3.0 || highEventRatio > 0.3 || stdDev > 20) {
      _isShakeDetected = true;
      _lastShakeTime = DateTime.now();
    } else {
      _isShakeDetected = false;
    }
  }

  bool get isShakeDetected => _isShakeDetected;

  /// Check if recent shake (within 500ms)
  bool get isRecentShake {
    if (_lastShakeTime == null) return false;
    return DateTime.now().difference(_lastShakeTime!).inMilliseconds < 500;
  }

  /// Update GPS position for correlation
  void updateGpsPosition(double lat, double lon) {
    if (_lastLat != 0 && _lastLon != 0) {
      final dist = _calculateHaversineDistance(_lastLat, _lastLon, lat, lon);
      if (dist > 0.5 && dist < 100) { // Valid range: 0.5m - 100m
        _accumulatedGpsDistanceM += dist;
      }
    }
    _lastLat = lat;
    _lastLon = lon;
    _lastGpsTime = DateTime.now();

    // Reset stillness lock if moving
    if (!_isStillnessLocked && _stillnessStartTime != null) {
      _isStillnessLocked = false;
      _stillnessStartTime = null;
    }
  }

  /// Calculate Haversine distance in meters
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
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

  /// Check if GPS has detected movement
  bool get hasGpsMovement {
    if (_lastGpsTime == null) return true;
    final elapsed = DateTime.now().difference(_lastGpsTime!).inSeconds;
    if (elapsed > 30) {
      _accumulatedGpsDistanceM = 0;
      return false;
    }
    return _accumulatedGpsDistanceM > 5.0;
  }

  /// Update stillness state based on speed
  void updateStillness(double speedKmh) {
    if (speedKmh > 0.5) {
      _isStillnessLocked = false;
      _stillnessStartTime = null;
    } else if (!_isStillnessLocked && _stillnessStartTime == null) {
      _stillnessStartTime = DateTime.now();
    } else if (_stillnessStartTime != null && !_isStillnessLocked) {
      if (DateTime.now().difference(_stillnessStartTime!) >= _stillnessThreshold) {
        _isStillnessLocked = true;
      }
    }
  }

  bool get isStillnessLocked => _isStillnessLocked;

  /// Reset GPS accumulation (called periodically to recalibrate)
  void resetGpsAccumulation() {
    _accumulatedGpsDistanceM = 0;
  }

  /// Get expected steps from GPS distance
  int get expectedStepsFromGps => (_accumulatedGpsDistanceM / _stepLengthMeters).round();

  /// Validasi apakah satu langkah boleh dihitung.
  ContextValidationResult validateStep({
    int rawDelta = 1,
    bool isMLShake = false,
    String mlActivity = 'unknown',
  }) {
    final now = DateTime.now();

    // ── Guard 1: Accelerometer shake detection ──────────────────────────
    if (_isShakeDetected || isRecentShake || isMLShake) {
      return const ContextValidationResult.rejected(
        rejectionReason: 'Goyangan HP terdeteksi',
      );
    }

    // ── Guard 2: Stillness lock ─────────────────────────────────────
    if (_isStillnessLocked) {
      return const ContextValidationResult.rejected(
        rejectionReason: 'Pengguna terdeteksi diam',
      );
    }

    // ── Guard 3: Activity tidak mendukung langkah ──────────────────────
    if (mlActivity == 'stationary' || mlActivity == 'cycling') {
      return const ContextValidationResult.rejected(
        rejectionReason: 'Aktivitas tidak mendukung langkah kaki',
      );
    }

    // ── Guard 4: Minimum interval ──────────────────────────────────────
    if (_lastStepTime != null) {
      final intervalMs = now.difference(_lastStepTime!).inMilliseconds;
      if (intervalMs < _minStepIntervalMs && rawDelta > 1) {
        return const ContextValidationResult.rejected(
          rejectionReason: 'Interval terlalu cepat',
        );
      }
    }

    // ── Guard 5: Burst detection ──────────────────────────────────────
    _recentSteps.removeWhere(
      (t) => now.difference(t) > _burstWindow,
    );
    if (_recentSteps.length >= _maxStepsPerWindow) {
      return const ContextValidationResult.rejected(
        rejectionReason: 'Burst detected',
        validSteps: 1,
      );
    }

    // ── Guard 6: GPS correlation check ─────────────────────────────────
    if (rawDelta > 1 && hasGpsMovement) {
      final expected = expectedStepsFromGps;
      if (rawDelta > expected * 3) {
        return ContextValidationResult.rejected(
          rejectionReason: 'Langkah tidak korelasi dengan GPS',
          validSteps: math.min(rawDelta, expected),
        );
      }
    }

    // ── All guards passed ────────────────────────────────────────────
    _lastStepTime = now;
    _recentSteps.add(now);
    if (_recentSteps.length > 20) {
      _recentSteps.removeAt(0);
    }

    return ContextValidationResult.valid(validSteps: math.min(rawDelta, _maxStepsPerWindow));
  }

  /// Validasi delta langkah dari pedometer hardware
  int validateStepDelta({
    required int rawDelta,
    required Duration windowDuration,
    bool isMLShake = false,
    String mlActivity = 'unknown',
  }) {
    // Guard: shake detection
    if (_isShakeDetected || isRecentShake || isMLShake) {
      debugPrint('[ValidasiKonteks] Delta $rawDelta DITOLAK: shake');
      return 0;
    }

    // Guard: stillness lock
    if (_isStillnessLocked) {
      debugPrint('[ValidasiKonteks] Delta $rawDelta DITOLAK: stillness locked');
      return 0;
    }

    // Guard: aktivitas tidak mendukung langkah
    if (mlActivity == 'stationary' || mlActivity == 'cycling') {
      debugPrint('[ValidasiKonteks] Delta $rawDelta DITOLAK: $mlActivity');
      return 0;
    }

    final windowSec = windowDuration.inMilliseconds / 1000.0;

    // Guard: very short window with large delta
    if (windowSec < 0.5 && rawDelta > 3) {
      debugPrint('[ValidasiKonteks] Delta $rawDelta DITOLAK: window=${windowSec.toStringAsFixed(2)}s');
      return math.min(rawDelta, 2);
    }

    // Cap: max realistic steps per window
    final maxRealistic = (_maxStepsPerSecond * windowSec).ceil();

    if (rawDelta > maxRealistic && windowSec < 10.0) {
      debugPrint('[ValidasiKonteks] Delta $rawDelta -> capped to $maxRealistic');
      return math.min(rawDelta, maxRealistic);
    }

    // Absolute cap
    const absoluteMax = 250;
    if (rawDelta > absoluteMax) {
      return absoluteMax;
    }

    return rawDelta;
  }

  /// Aktifkan stillness lock secara manual
  void activateStillnessLock() {
    if (!_isStillnessLocked) {
      _isStillnessLocked = true;
      _stillnessStartTime = DateTime.now();
      debugPrint('[ValidasiKonteks] Stillness lock diaktifkan');
    }
  }

  void reset() {
    _recentSteps.clear();
    _lastStepTime = null;
    _accelMagnitudes.clear();
    _isShakeDetected = false;
    _lastShakeTime = null;
    _lastLat = 0;
    _lastLon = 0;
    _lastGpsTime = null;
    _accumulatedGpsDistanceM = 0;
    _isStillnessLocked = false;
    _stillnessStartTime = null;
  }
}
