// ============================================================
// FILTER SINYAL — Signal Processing untuk Activity Recognition
// ============================================================
// Berisi:
//  • ButterworthLowPassFilter  — hapus noise frekuensi tinggi (goyang HP)
//  • MovingAverage             — smoothing adaptif
//  • SignalFeatures            — ekstraksi 12 fitur per window
//  • ShakeSignature            — pendeteksi signature goyang HP
//
// Referensi Ilmiah:
//  • Lara OD & Labrador MA (2021). Human Activity Recognition Using
//    Accelerometer. MDPI Sensors. https://doi.org/10.3390/s21093304
//  • Ainsworth BE et al. (2011). Compendium of Physical Activities.
//    Med. Sci. Sports Exerc. https://doi.org/10.1249/MSS.0b013e31821ece12
//  • Tudor-Locke C et al. (2011). How Many Steps/day are Enough?
//    Int. J. Behav. Nutr. https://doi.org/10.1186/1479-5868-8-79
// ============================================================

import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// Butterworth Low-Pass Filter (orde 2, implementasi biquad IIR)
// Membuang frekuensi > cutoffHz. Goyang HP biasanya > 5 Hz,
// langkah kaki biasanya 1–3 Hz → cutoff 4 Hz sangat efektif.
// ─────────────────────────────────────────────────────────────────────────────
class ButterworthLowPassFilter {
  final double _b0, _b1, _b2, _a1, _a2;
  double _x1 = 0, _x2 = 0; // input delay
  double _y1 = 0, _y2 = 0; // output delay

  /// [sampleRateHz] frekuensi sampling sensor (biasanya 50 Hz di Android)
  /// [cutoffHz]     frekuensi potong (4.0 untuk langkah, 8.0 untuk lari)
  ButterworthLowPassFilter({
    required double sampleRateHz,
    required double cutoffHz,
  })  : _b0 = _coeff(sampleRateHz, cutoffHz)[0],
        _b1 = _coeff(sampleRateHz, cutoffHz)[1],
        _b2 = _coeff(sampleRateHz, cutoffHz)[2],
        _a1 = _coeff(sampleRateHz, cutoffHz)[3],
        _a2 = _coeff(sampleRateHz, cutoffHz)[4];

  static List<double> _coeff(double fs, double fc) {
    final wc = 2 * math.pi * fc / fs;
    final k = math.tan(wc / 2);
    final k2 = k * k;
    final sqrt2 = math.sqrt(2);
    final norm = 1 / (1 + sqrt2 * k + k2);
    final b0 = k2 * norm;
    final b1 = 2 * b0;
    final b2 = b0;
    final a1 = 2 * (k2 - 1) * norm;
    final a2 = (1 - sqrt2 * k + k2) * norm;
    return [b0, b1, b2, a1, a2];
  }

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }

  void reset() {
    _x1 = _x2 = _y1 = _y2 = 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Moving Average dengan circular buffer
// ─────────────────────────────────────────────────────────────────────────────
class MovingAverage {
  final int windowSize;
  final List<double> _buf;
  int _head = 0;
  double _sum = 0;
  int _count = 0;

  MovingAverage(this.windowSize) : _buf = List.filled(windowSize, 0.0);

  double add(double value) {
    _sum -= _buf[_head];
    _buf[_head] = value;
    _sum += value;
    _head = (_head + 1) % windowSize;
    if (_count < windowSize) _count++;
    return _sum / _count;
  }

  void reset() {
    for (int i = 0; i < windowSize; i++) {
      _buf[i] = 0;
    }
    _head = 0;
    _sum = 0;
    _count = 0;
  }

  bool get isFull => _count == windowSize;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ekstraksi Fitur Sinyal (12 fitur dari window accelerometer)
// ─────────────────────────────────────────────────────────────────────────────
class SignalFeatures {
  /// Mean magnitude
  final double mean;

  /// Standard deviation
  final double stdDev;

  /// Root Mean Square — energi sinyal
  final double rms;

  /// Variance — seberapa acak sinyal
  final double variance;

  /// Zero Crossing Rate — berapa kali sinyal menyeberangi mean (per detik)
  final double zcr;

  /// Peak-to-peak amplitude
  final double peakToPeak;

  /// Dominant frequency dari DFT sederhana (Hz)
  final double dominantFreqHz;

  /// Energi pada band langkah (0.5–3 Hz)
  final double stepBandEnergy;

  /// Energi pada band goyang (5–15 Hz)
  final double shakeBandEnergy;

  /// Kurtosis — ukuran "ketajaman" distribusi (tinggi = goyang abrupt)
  final double kurtosis;

  /// Skewness — asimetri distribusi
  final double skewness;

  /// Spectral entropy — seberapa tersebar frekuensi (tinggi = noise)
  final double spectralEntropy;

  const SignalFeatures({
    required this.mean,
    required this.stdDev,
    required this.rms,
    required this.variance,
    required this.zcr,
    required this.peakToPeak,
    required this.dominantFreqHz,
    required this.stepBandEnergy,
    required this.shakeBandEnergy,
    required this.kurtosis,
    required this.skewness,
    required this.spectralEntropy,
  });

  /// Apakah ini signature goyang HP (bukan langkah)
  bool get isShakePattern {
    // Goyang HP: energi shake tinggi, ZCR tidak ritmis, kurtosis tinggi
    return shakeBandEnergy > stepBandEnergy * 2.0 &&
        kurtosis > 5.0 &&
        dominantFreqHz > 4.0;
  }

  /// Apakah ada pola langkah yang valid
  bool get hasStepPattern {
    // Langkah kaki: dominan 1-3 Hz, step band energy lebih besar
    return dominantFreqHz >= 0.8 &&
        dominantFreqHz <= 3.5 &&
        stepBandEnergy > shakeBandEnergy &&
        variance > 0.2 &&
        variance < 15.0;
  }

  @override
  String toString() => 'SignalFeatures(mean=${mean.toStringAsFixed(2)}, '
      'var=${variance.toStringAsFixed(2)}, '
      'rms=${rms.toStringAsFixed(2)}, '
      'domFreq=${dominantFreqHz.toStringAsFixed(2)}Hz, '
      'stepE=${stepBandEnergy.toStringAsFixed(2)}, '
      'shakeE=${shakeBandEnergy.toStringAsFixed(2)}, '
      'kurt=${kurtosis.toStringAsFixed(2)}, '
      'isShake=$isShakePattern, hasStep=$hasStepPattern)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Extractor Fitur — proses list magnitude menjadi SignalFeatures
// ─────────────────────────────────────────────────────────────────────────────
class FeatureExtractor {
  final double sampleRateHz;

  const FeatureExtractor({this.sampleRateHz = 50.0});

  /// Ekstrak 12 fitur dari window magnitudes.
  /// [magnitudes] harus berisi minimal 20 sample.
  SignalFeatures? extract(List<double> magnitudes) {
    if (magnitudes.length < 20) return null;

    final n = magnitudes.length;

    // ── Mean ────────────────────────────────────────────────────────────────
    final mean = magnitudes.reduce((a, b) => a + b) / n;

    // ── Variance & StdDev ───────────────────────────────────────────────────
    final variance =
        magnitudes.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
            n;
    final stdDev = math.sqrt(variance);

    // ── RMS ─────────────────────────────────────────────────────────────────
    final rms =
        math.sqrt(magnitudes.map((x) => x * x).reduce((a, b) => a + b) / n);

    // ── Peak to Peak ────────────────────────────────────────────────────────
    final minVal = magnitudes.reduce(math.min);
    final maxVal = magnitudes.reduce(math.max);
    final peakToPeak = maxVal - minVal;

    // ── Zero Crossing Rate (relative to mean) ───────────────────────────────
    int crossings = 0;
    for (int i = 1; i < n; i++) {
      if ((magnitudes[i] - mean) * (magnitudes[i - 1] - mean) < 0) {
        crossings++;
      }
    }
    final zcr = crossings / (n / sampleRateHz); // crossings per second

    // ── Kurtosis & Skewness ─────────────────────────────────────────────────
    double moment3 = 0, moment4 = 0;
    for (final x in magnitudes) {
      final dev = x - mean;
      moment3 += math.pow(dev, 3).toDouble();
      moment4 += math.pow(dev, 4).toDouble();
    }
    moment3 /= n;
    moment4 /= n;
    final kurtosis = stdDev > 0 ? moment4 / math.pow(stdDev, 4) : 0.0;
    final skewness = stdDev > 0 ? moment3 / math.pow(stdDev, 3) : 0.0;

    // ── DFT (Discrete Fourier Transform) ────────────────────────────────────
    // Hanya hitung hingga Nyquist (sampleRateHz/2)
    final halfN = n ~/ 2;
    final freqResolution = sampleRateHz / n;

    // Normalisasi sinyal sebelum DFT
    final normalized =
        magnitudes.map((x) => x - mean).toList(); // remove DC component

    // Hitung magnitude spektrum via DFT
    final spectrum = <double>[];
    for (int k = 0; k < halfN; k++) {
      double re = 0, im = 0;
      for (int t = 0; t < n; t++) {
        final angle = 2 * math.pi * k * t / n;
        re += normalized[t] * math.cos(angle);
        im -= normalized[t] * math.sin(angle);
      }
      spectrum.add(math.sqrt(re * re + im * im) / n);
    }

    // ── Dominant Frequency ──────────────────────────────────────────────────
    int maxIdx = 0;
    double maxMag = 0;
    for (int i = 1; i < spectrum.length; i++) {
      if (spectrum[i] > maxMag) {
        maxMag = spectrum[i];
        maxIdx = i;
      }
    }
    final dominantFreqHz = maxIdx * freqResolution;

    // ── Band Energy ─────────────────────────────────────────────────────────
    double stepBandEnergy = 0; // 0.5 – 3.5 Hz (langkah kaki)
    double shakeBandEnergy = 0; // 5 – 15 Hz (goyang HP)
    double totalEnergy = 0;

    for (int i = 0; i < spectrum.length; i++) {
      final freq = i * freqResolution;
      final energy = spectrum[i] * spectrum[i];
      totalEnergy += energy;

      if (freq >= 0.5 && freq <= 3.5) {
        stepBandEnergy += energy;
      } else if (freq >= 5.0 && freq <= 15.0) {
        shakeBandEnergy += energy;
      }
    }

    // ── Spectral Entropy ────────────────────────────────────────────────────
    double spectralEntropy = 0;
    if (totalEnergy > 0) {
      for (final e in spectrum) {
        final p = (e * e) / totalEnergy;
        if (p > 0) spectralEntropy -= p * math.log(p);
      }
      // Normalize by log(N)
      spectralEntropy /= math.log(spectrum.length);
    }

    return SignalFeatures(
      mean: mean,
      stdDev: stdDev,
      rms: rms,
      variance: variance,
      zcr: zcr,
      peakToPeak: peakToPeak,
      dominantFreqHz: dominantFreqHz,
      stepBandEnergy: stepBandEnergy,
      shakeBandEnergy: shakeBandEnergy,
      kurtosis: kurtosis,
      skewness: skewness,
      spectralEntropy: spectralEntropy,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Rhythm Validator — validasi interval antar langkah
// Langkah nyata manusia: 400–1200 ms per langkah (50–150 langkah/menit)
//
// Referensi:
//  • Tudor-Locke C et al. (2011). Cadence ≥96 steps/min = moderate intensity.
//    Int. J. Behav. Nutr. Phys. Act. https://doi.org/10.1186/1479-5868-8-79
//  • Del Din S et al. (2022). Smartphone Gait Analysis for Frailty Detection.
//    JMIR mHealth. https://doi.org/10.2196/34227
// ─────────────────────────────────────────────────────────────────────────────
class StepRhythmValidator {
  final List<DateTime> _stepTimestamps = [];
  static const int _maxHistory = 20;

  // Batas interval langkah yang valid (ms) — dinaikkan untuk tolak burst goyang
  static const double _minIntervalMs =
      320.0; // ~187 langkah/menit max, lebih selektif
  /// Tambahkan timestamp langkah baru. Kembalikan true jika langkah valid.
  bool validateStep(DateTime timestamp) {
    if (_stepTimestamps.isEmpty) {
      _stepTimestamps.add(timestamp);
      return true;
    }

    final lastStep = _stepTimestamps.last;
    final intervalMs = timestamp.difference(lastStep).inMilliseconds.toDouble();

    // Tolak jika interval terlalu pendek (burst dari goyang) atau terlalu panjang
    if (intervalMs < _minIntervalMs) {
      return false; // Terlalu cepat → kemungkinan besar goyang HP
    }

    _stepTimestamps.add(timestamp);
    if (_stepTimestamps.length > _maxHistory) {
      _stepTimestamps.removeAt(0);
    }
    return true;
  }

  /// Hitung cadence rata-rata (langkah per menit)
  double get averageCadenceSpm {
    if (_stepTimestamps.length < 2) return 0;
    final totalMs = _stepTimestamps.last
        .difference(_stepTimestamps.first)
        .inMilliseconds
        .toDouble();
    if (totalMs <= 0) return 0;
    final steps = _stepTimestamps.length - 1;
    return (steps / totalMs) * 60000;
  }

  /// True jika ritme langkah konsisten (bukan goyang acak)
  bool get hasConsistentRhythm {
    if (_stepTimestamps.length < 4) return false;

    final intervals = <double>[];
    for (int i = 1; i < _stepTimestamps.length; i++) {
      intervals.add(_stepTimestamps[i]
          .difference(_stepTimestamps[i - 1])
          .inMilliseconds
          .toDouble());
    }

    final meanInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals
            .map((x) => math.pow(x - meanInterval, 2))
            .reduce((a, b) => a + b) /
        intervals.length;
    final cv = math.sqrt(variance) / meanInterval; // Coefficient of variation

    // CV < 0.35 = ritme konsisten (berjalan/berlari nyata) — diperketat dari 0.4
    // CV > 0.35 = acak/tidak ritmis (duduk sambil goyang HP)
    return cv < 0.35;
  }

  void reset() => _stepTimestamps.clear();
}
