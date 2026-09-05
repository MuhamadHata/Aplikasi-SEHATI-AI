// ============================================================
// DETEKTOR AKTIVITAS ML — Machine Learning Activity Classifier
// ============================================================
// Mengklasifikasikan aktivitas user berdasarkan data accelerometer
// menggunakan pendekatan multi-stage classification:
//
//  Stage 1: Anti-Shake Guard  → langsung tolak pola goyang HP
//  Stage 2: Feature-based ML  → Rule-based RandomForest (pure Dart)
//  Stage 3: Temporal Smoother → Majority vote 7 prediksi terakhir
//  Stage 4: Confidence Filter → Tolak prediksi confidence < threshold
// ============================================================

import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'filter_sinyal.dart';
import 'gait_quality_index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum Tipe Aktivitas dengan metadata
// ─────────────────────────────────────────────────────────────────────────────
enum DetectedActivity {
  stationary,
  walking,
  running,
  cycling,
  shake, // ← BARU: HP digoyang, bukan aktivitas fisik!
  unknown,
}

extension DetectedActivityExt on DetectedActivity {
  String get label {
    switch (this) {
      case DetectedActivity.stationary:
        return 'Diam';
      case DetectedActivity.walking:
        return 'Berjalan';
      case DetectedActivity.running:
        return 'Berlari';
      case DetectedActivity.cycling:
        return 'Bersepeda';
      case DetectedActivity.shake:
        return '⚠️ HP Digoyang';
      case DetectedActivity.unknown:
        return 'Mendeteksi...';
    }
  }

  String get emoji {
    switch (this) {
      case DetectedActivity.stationary:
        return '🪑';
      case DetectedActivity.walking:
        return '🚶';
      case DetectedActivity.running:
        return '🏃';
      case DetectedActivity.cycling:
        return '🚴';
      case DetectedActivity.shake:
        return '📱';
      case DetectedActivity.unknown:
        return '🔍';
    }
  }

  bool get isActiveExercise =>
      this == DetectedActivity.walking ||
      this == DetectedActivity.running ||
      this == DetectedActivity.cycling;

  /// Apakah boleh menghitung langkah?
  bool get allowsStepCounting =>
      this == DetectedActivity.walking || this == DetectedActivity.running;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hasil Klasifikasi
// ─────────────────────────────────────────────────────────────────────────────
class ActivityClassification {
  final DetectedActivity activity;
  final double confidence; // 0.0 – 1.0
  final bool isShakeDetected;
  final SignalFeatures? features;
  final String debugInfo;

  const ActivityClassification({
    required this.activity,
    required this.confidence,
    this.isShakeDetected = false,
    this.features,
    this.debugInfo = '',
  });

  bool get isReliable => confidence >= 0.65;

  @override
  String toString() =>
      '${activity.label} (${(confidence * 100).toStringAsFixed(0)}%) '
      '${isShakeDetected ? "[SHAKE BLOCKED]" : ""}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Rule-based Random Forest — pure Dart, tidak perlu TFLite
//
// Implementasi ensemble sederhana dari 5 decision tree.
// Setiap tree menggunakan subset fitur yang berbeda untuk diversitas.
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityForest {
  // Tree 1: fokus pada variance & frequency domain
  static DetectedActivity _tree1(SignalFeatures f) {
    if (f.variance < 0.3) return DetectedActivity.stationary;
    if (f.dominantFreqHz > 4.5 && f.shakeBandEnergy > f.stepBandEnergy) {
      return DetectedActivity.shake;
    }
    if (f.dominantFreqHz >= 1.0 && f.dominantFreqHz <= 2.5) {
      return f.rms > 11.5 ? DetectedActivity.running : DetectedActivity.walking;
    }
    if (f.dominantFreqHz > 2.5 && f.dominantFreqHz <= 4.5) {
      return DetectedActivity.running;
    }
    if (f.variance > 0.3 && f.variance < 1.5 && f.dominantFreqHz < 1.0) {
      return DetectedActivity.cycling;
    }
    return DetectedActivity.unknown;
  }

  // Tree 2: fokus pada energi band & kurtosis
  static DetectedActivity _tree2(SignalFeatures f) {
    if (f.kurtosis > 6.0 && f.shakeBandEnergy > 0.5) {
      return DetectedActivity.shake; // abrupt spikes = shake
    }
    if (f.rms < 9.8) return DetectedActivity.stationary;
    if (f.stepBandEnergy > f.shakeBandEnergy * 1.5) {
      // Energi utama di band langkah
      return f.zcr > 60 ? DetectedActivity.running : DetectedActivity.walking;
    }
    if (f.shakeBandEnergy > f.stepBandEnergy) {
      return f.kurtosis > 4.0
          ? DetectedActivity.shake
          : DetectedActivity.cycling;
    }
    return DetectedActivity.unknown;
  }

  // Tree 3: fokus pada RMS & ZCR (cadence-based)
  static DetectedActivity _tree3(SignalFeatures f) {
    if (f.rms < 9.5 && f.variance < 0.4) return DetectedActivity.stationary;
    if (f.zcr > 80 && f.peakToPeak > 8.0) {
      return DetectedActivity.shake; // frekuensi tinggi + amplitudo besar
    }
    if (f.zcr >= 30 && f.zcr <= 80) {
      return f.rms > 11.0 ? DetectedActivity.running : DetectedActivity.walking;
    }
    if (f.zcr < 30 && f.variance > 0.3) {
      return DetectedActivity.cycling;
    }
    return DetectedActivity.stationary;
  }

  // Tree 4: fokus pada spectral entropy & skewness
  static DetectedActivity _tree4(SignalFeatures f) {
    // Entropy tinggi = sinyal acak = shake atau noise
    if (f.spectralEntropy > 0.85 && f.variance > 2.0) {
      return DetectedActivity.shake;
    }
    if (f.spectralEntropy < 0.4) {
      // Sinyal terkonsentrasi pada satu frekuensi
      if (f.dominantFreqHz > 0 && f.dominantFreqHz < 4.0) {
        return f.dominantFreqHz >= 2.0
            ? DetectedActivity.running
            : DetectedActivity.walking;
      }
    }
    if (f.mean > 9.5 && f.mean < 10.5 && f.variance < 0.5) {
      return DetectedActivity.stationary; // hanya gravitasi
    }
    return DetectedActivity.unknown;
  }

  // Tree 5: fokus pada kombinasi fitur temporal (anti-shake specialist)
  static DetectedActivity _tree5(SignalFeatures f) {
    // Signature unik goyang HP:
    // - Peak-to-peak sangat besar (> 15 m/s²)
    // - Kurtosis tinggi (burst impulsif)
    // - Energi shake band dominan
    if (f.peakToPeak > 15.0 &&
        f.kurtosis > 4.5 &&
        f.shakeBandEnergy > f.stepBandEnergy) {
      return DetectedActivity.shake;
    }

    // Signature berjalan:
    // - Mean dekat gravitasi (9.0–11.0 m/s²)
    // - Variance moderate
    // - Step band dominant
    if (f.mean > 8.5 &&
        f.mean < 11.5 &&
        f.variance > 0.3 &&
        f.variance < 8.0 &&
        f.stepBandEnergy > f.shakeBandEnergy) {
      return f.variance > 3.0
          ? DetectedActivity.running
          : DetectedActivity.walking;
    }

    if (f.variance < 0.3) return DetectedActivity.stationary;
    return DetectedActivity.unknown;
  }

  /// Ensemble prediction: majority vote dari 5 trees
  static ActivityClassification predict(SignalFeatures features) {
    final votes = <DetectedActivity, int>{};
    final trees = [_tree1, _tree2, _tree3, _tree4, _tree5];

    for (final tree in trees) {
      final result = tree(features);
      votes[result] = (votes[result] ?? 0) + 1;
    }

    // Cek shake secara eksplisit: jika >= 2 tree bilang shake → shake
    final shakeVotes = votes[DetectedActivity.shake] ?? 0;
    if (shakeVotes >= 2) {
      return ActivityClassification(
        activity: DetectedActivity.shake,
        confidence: shakeVotes / trees.length,
        isShakeDetected: true,
        features: features,
        debugInfo: 'Shake detected by $shakeVotes/5 trees',
      );
    }

    // Remove shake dari voting normal
    votes.remove(DetectedActivity.shake);

    if (votes.isEmpty) {
      return const ActivityClassification(
        activity: DetectedActivity.unknown,
        confidence: 0.0,
        debugInfo: 'No majority',
      );
    }

    // Cari pemenang voting
    final winner = votes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final totalVotes = votes.values.reduce((a, b) => a + b);
    final confidence = winner.value / trees.length;

    return ActivityClassification(
      activity: winner.key,
      confidence: confidence,
      features: features,
      debugInfo:
          'Vote: ${votes.map((k, v) => MapEntry(k.label, v))} total=$totalVotes',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Temporal Smoother — Majority Vote dari N prediksi terakhir
// Mencegah flip-flop aktivitas (misalnya: jalan-lari-jalan-lari)
// ─────────────────────────────────────────────────────────────────────────────
class _TemporalSmoother {
  final int windowSize;
  final List<ActivityClassification> _history = [];

  _TemporalSmoother({this.windowSize = 7});

  ActivityClassification smooth(ActivityClassification newResult) {
    _history.add(newResult);
    if (_history.length > windowSize) _history.removeAt(0);

    // Shake override: jika ada shake dalam history terbaru, selalu laporkan
    final recentShakes =
        _history.reversed.take(3).where((r) => r.isShakeDetected).length;
    if (recentShakes >= 2) {
      return ActivityClassification(
        activity: DetectedActivity.shake,
        confidence: recentShakes / 3.0,
        isShakeDetected: true,
        debugInfo: 'Temporal: shake confirmed ($recentShakes/3)',
      );
    }

    // Majority vote (exclude shake)
    final votes = <DetectedActivity, double>{};
    for (final r in _history) {
      if (!r.isShakeDetected) {
        votes[r.activity] = (votes[r.activity] ?? 0) + r.confidence;
      }
    }

    if (votes.isEmpty) return newResult;

    final winner = votes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final totalWeight = votes.values.reduce((a, b) => a + b);
    final smoothedConfidence =
        (winner.value / totalWeight * newResult.confidence).clamp(0.0, 1.0);

    return ActivityClassification(
      activity: winner.key,
      confidence: smoothedConfidence,
      debugInfo: 'Smoothed: ${winner.key.label} '
          '(${(smoothedConfidence * 100).toStringAsFixed(0)}%)',
    );
  }

  void reset() => _history.clear();

  DetectedActivity get currentActivity =>
      _history.isEmpty ? DetectedActivity.unknown : _history.last.activity;
}

// ─────────────────────────────────────────────────────────────────────────────
// DETEKTOR AKTIVITAS ML — Main Class
// ─────────────────────────────────────────────────────────────────────────────
class DetektorAktivitasML {
  static const double _sampleRateHz = 50.0;
  static const int _windowSizeSamples = 100; // 2 detik @ 50Hz
  static const int _hopSizeSamples = 25; // update setiap 0.5 detik
  static const double _minConfidenceThreshold = 0.55;

  // Signal processing — cutoff 4 Hz: loloskan langkah 1-3 Hz, redam goyang >5 Hz
  final ButterworthLowPassFilter _filterX =
      ButterworthLowPassFilter(sampleRateHz: _sampleRateHz, cutoffHz: 4.0);
  final ButterworthLowPassFilter _filterY =
      ButterworthLowPassFilter(sampleRateHz: _sampleRateHz, cutoffHz: 4.0);
  final ButterworthLowPassFilter _filterZ =
      ButterworthLowPassFilter(sampleRateHz: _sampleRateHz, cutoffHz: 4.0);

  final FeatureExtractor _featureExtractor =
      const FeatureExtractor(sampleRateHz: _sampleRateHz);
  final _TemporalSmoother _smoother = _TemporalSmoother(windowSize: 7);
  final StepRhythmValidator _rhythmValidator = StepRhythmValidator();

  // Circular buffer untuk magnitudes
  final List<double> _magnitudeBuffer = [];
  int _samplesInCurrentHop = 0;

  // Stream
  final _classificationController =
      StreamController<ActivityClassification>.broadcast();
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // State
  ActivityClassification _lastClassification = const ActivityClassification(
    activity: DetectedActivity.unknown,
    confidence: 0.0,
  );

  bool _isRunning = false;

  // Public stream
  Stream<ActivityClassification> get classificationStream =>
      _classificationController.stream;

  ActivityClassification get lastClassification => _lastClassification;
  DetectedActivity get currentActivity => _lastClassification.activity;
  double get confidence => _lastClassification.confidence;
  bool get isShakeDetected => _lastClassification.isShakeDetected;

  // Gait Quality
  final GaitQualityAnalyzer _gaitAnalyzer = GaitQualityAnalyzer();
  GaitQualityResult _lastGaitQuality = GaitQualityResult.empty;
  DateTime? _lastStepTimeForGait;

  GaitQualityResult get gaitQuality => _lastGaitQuality;

  /// Mulai monitoring accelerometer
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    _reset();

    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(_onAccelerometerEvent, onError: (e) {
      debugPrint('[DetektorML] Accelerometer error: $e');
    });

    debugPrint('[DetektorML] Started — window=${_windowSizeSamples}samples '
        'hop=${_hopSizeSamples}samples');
  }

  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
    _isRunning = false;
    debugPrint('[DetektorML] Stopped');
  }

  void dispose() {
    stop();
    _classificationController.close();
  }

  void _reset() {
    _magnitudeBuffer.clear();
    _samplesInCurrentHop = 0;
    _smoother.reset();
    _rhythmValidator.reset();
    _gaitAnalyzer.reset();
    _lastStepTimeForGait = null;
    _lastGaitQuality = GaitQualityResult.empty;
    _filterX.reset();
    _filterY.reset();
    _filterZ.reset();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Apply low-pass filter untuk membuang noise goyang tinggi
    final fx = _filterX.process(event.x);
    final fy = _filterY.process(event.y);
    final fz = _filterZ.process(event.z);

    // Hitung magnitude 3D
    final magnitude = math.sqrt(fx * fx + fy * fy + fz * fz);
    _magnitudeBuffer.add(magnitude);
    _samplesInCurrentHop++;

    // Batasi buffer pada 2x window size
    if (_magnitudeBuffer.length > _windowSizeSamples * 2) {
      _magnitudeBuffer.removeAt(0);
    }

    // Process setiap hop
    if (_samplesInCurrentHop >= _hopSizeSamples &&
        _magnitudeBuffer.length >= _windowSizeSamples) {
      _samplesInCurrentHop = 0;
      _processWindow();
    }
  }

  void _processWindow() {
    // Ambil window terbaru
    final window = _magnitudeBuffer.length > _windowSizeSamples
        ? _magnitudeBuffer.sublist(_magnitudeBuffer.length - _windowSizeSamples)
        : List<double>.from(_magnitudeBuffer);

    // Ekstraksi fitur
    final features = _featureExtractor.extract(window);
    if (features == null) return;

    // Stage 1: Anti-Shake Fast-Path
    if (_fastShakeCheck(features)) {
      final shakeResult = ActivityClassification(
        activity: DetectedActivity.shake,
        confidence: 0.95,
        isShakeDetected: true,
        features: features,
        debugInfo: 'Fast-path shake detection',
      );
      _lastClassification = shakeResult;
      _classificationController.add(shakeResult);
      debugPrint('[DetektorML] ⚠️ SHAKE detected (fast-path): $features');
      return;
    }

    // Stage 2: ML Forest Classification
    final rawResult = _ActivityForest.predict(features);

    // Stage 3: Temporal Smoothing
    final smoothed = _smoother.smooth(rawResult);

    // Stage 4: Confidence Gate
    final finalResult = smoothed.confidence >= _minConfidenceThreshold
        ? smoothed
        : ActivityClassification(
            activity: DetectedActivity.unknown,
            confidence: smoothed.confidence,
            debugInfo:
                'Low confidence: ${smoothed.confidence.toStringAsFixed(2)}',
          );

    // Analyze Gait Quality Index (GQI)
    final stepTime = _lastStepTimeForGait;
    _lastStepTimeForGait = null;
    _lastGaitQuality = _gaitAnalyzer.analyze(
      features: features,
      stepTimestamp: stepTime,
    );

    _lastClassification = finalResult;
    _classificationController.add(finalResult);

    debugPrint(
        '[DetektorML] ${finalResult.toString()} | ${features.toString()} | GQI=${_lastGaitQuality.overall.toStringAsFixed(1)}');
  }

  /// Fast-path shake detection: cek tanda-tanda paling jelas tanpa perlu
  /// menjalankan seluruh forest untuk performa lebih baik.
  bool _fastShakeCheck(SignalFeatures f) {
    // Kriteria: SEMUA kondisi ini harus terpenuhi untuk shake
    // 1. Energi di band frekuensi tinggi > band langkah
    // 2. Kurtosis tinggi (spikes abrupt)
    // 3. Peak-to-peak besar tapi bukan lari biasa
    final highFreqDominant = f.shakeBandEnergy > f.stepBandEnergy * 1.8;
    final abruptSpikes = f.kurtosis > 5.5;
    final highAmplitude = f.peakToPeak > 12.0;
    final tooFastFrequency = f.dominantFreqHz > 5.0;

    // Shake jika frekuensi tinggi dominan DAN ada spikes abrupt
    if (highFreqDominant && abruptSpikes) return true;

    // Shake jika amplitudo besar DAN frekuensi sangat tinggi
    if (highAmplitude && tooFastFrequency) return true;

    // Shake: ZCR jauh di atas normal berjalan/berlari
    if (f.zcr > 100 && f.variance > 5.0) return true;

    return false;
  }

  /// Validasi apakah step dari pedometer boleh dihitung.
  /// Panggil ini di background service sebelum menambah langkah.
  bool validatePedometerStep({required DateTime stepTime}) {
    // Cek apakah aktivitas saat ini membolehkan step counting
    if (!_lastClassification.activity.allowsStepCounting &&
        _lastClassification.activity != DetectedActivity.unknown) {
      debugPrint(
          '[DetektorML] Step rejected: activity=${_lastClassification.activity.label}');
      return false;
    }

    // Cek shake state: jika baru saja terdeteksi shake, tolak step
    if (_lastClassification.isShakeDetected) {
      debugPrint('[DetektorML] Step rejected: shake in progress');
      return false;
    }

    // Validasi ritme langkah
    final rhythmOk = _rhythmValidator.validateStep(stepTime);
    if (!rhythmOk) {
      debugPrint(
          '[DetektorML] Step rejected: rhythm too fast (possible shake)');
      return false;
    }

    _lastStepTimeForGait = stepTime;
    return true;
  }

  /// Dapatkan max speed yang masuk akal berdasarkan aktivitas terdeteksi
  double getMaxReasonableSpeedKmh() {
    switch (currentActivity) {
      case DetectedActivity.cycling:
        return 80.0;
      case DetectedActivity.running:
        return 40.0;
      case DetectedActivity.walking:
        return 12.0;
      case DetectedActivity.stationary:
        return 3.0;
      default:
        return 50.0;
    }
  }
}
