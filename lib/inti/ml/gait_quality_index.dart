// ============================================================
// GAIT QUALITY INDEX (GQI) — Indeks Kualitas Gait
// ============================================================
// Menganalisis KUALITAS berjalan dari sinyal accelerometer
// yang sudah ada (SignalFeatures + StepRhythmValidator).
//
// Referensi Ilmiah:
//  • Del Din S et al. (2022). Smartphone-Based Gait Analysis for
//    the Detection of Frailty in Older Adults.
//    JMIR mHealth and uHealth. https://doi.org/10.2196/34227
//  • Frontiers in Aging Neuroscience (2023). Gait as a Biomarker
//    of Healthy Aging. https://doi.org/10.3389/fnagi.2023.1182641
//  • Tudor-Locke C et al. (2011). How Many Steps/day are Enough?
//    Int. J. Behav. Nutr. Phys. Act. doi:10.1186/1479-5868-8-79
// ============================================================

import 'dart:math' as math;
import 'filter_sinyal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum Kategori Intensitas Cadence (Tudor-Locke et al., 2011)
// ─────────────────────────────────────────────────────────────────────────────
enum CadenceIntensity {
  sedentary, // < 40 spm
  light, // 40–99 spm
  moderate, // 100–129 spm → target mininum WHO PA Guidelines
  vigorous, // ≥ 130 spm
}

extension CadenceIntensityExt on CadenceIntensity {
  String get label {
    switch (this) {
      case CadenceIntensity.sedentary:
        return 'Sedentary';
      case CadenceIntensity.light:
        return 'Ringan';
      case CadenceIntensity.moderate:
        return 'Sedang ✅';
      case CadenceIntensity.vigorous:
        return 'Intensif 🔥';
    }
  }

  String get description {
    switch (this) {
      case CadenceIntensity.sedentary:
        return 'Kurang dari 40 langkah/menit. Hampir tidak ada gerakan bermakna.';
      case CadenceIntensity.light:
        return '40–99 langkah/menit. Aktivitas ringan, belum mencapai intensitas aerobik.';
      case CadenceIntensity.moderate:
        return '≥100 langkah/menit selama ≥10 menit = intensitas sedang (WHO/Tudor-Locke 2011). Target optimal!';
      case CadenceIntensity.vigorous:
        return '≥130 langkah/menit. Intensitas tinggi — bakar kalori lebih banyak, tingkatkan kapasitas kardio.';
    }
  }

  String get emoji {
    switch (this) {
      case CadenceIntensity.sedentary:
        return '🪑';
      case CadenceIntensity.light:
        return '🚶';
      case CadenceIntensity.moderate:
        return '🚶‍♂️';
      case CadenceIntensity.vigorous:
        return '🏃';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hasil Analisis GQI (4 dimensi + overall)
// ─────────────────────────────────────────────────────────────────────────────
class GaitQualityResult {
  /// Stride Regularity: konsistensi interval antar langkah (0–100)
  /// Tinggi = ritme teratur; rendah = acak/tidak teratur.
  /// Referensi: Del Din et al. 2022 — CV < 0.25 = regularity baik
  final double strideRegularity;

  /// Step Efficiency: rasio energi pada band langkah vs total energi
  /// Tinggi = energi terkonsentrasi pada frekuensi 0.5–3.5 Hz yang optimal
  final double stepEfficiency;

  /// Gait Stability: inverse dari spectral entropy yang dinormalisasi
  /// Tinggi = sinyal teratur/tidak acak; rendah = chaotic
  final double gaitStability;

  /// Cadence Quality: seberapa dekat cadence aktual ke target optimal
  /// Berdasarkan Tudor-Locke: 100–130 spm = zona optimal
  final double cadenceQuality;

  /// Overall GQI: rata-rata tertimbang 4 dimensi (0–100)
  final double overall;

  /// Cadence aktual dalam langkah per menit
  final double actualCadenceSpm;

  /// Kategori intensitas berdasarkan Tudor-Locke 2011
  final CadenceIntensity intensityCategory;

  /// Pesan umpan balik dalam Bahasa Indonesia
  final String feedbackMessage;

  /// Label kesehatan gait
  final String healthLabel;

  const GaitQualityResult({
    required this.strideRegularity,
    required this.stepEfficiency,
    required this.gaitStability,
    required this.cadenceQuality,
    required this.overall,
    required this.actualCadenceSpm,
    required this.intensityCategory,
    required this.feedbackMessage,
    required this.healthLabel,
  });

  static GaitQualityResult get empty => const GaitQualityResult(
        strideRegularity: 0,
        stepEfficiency: 0,
        gaitStability: 0,
        cadenceQuality: 0,
        overall: 0,
        actualCadenceSpm: 0,
        intensityCategory: CadenceIntensity.sedentary,
        feedbackMessage: 'Mulai berjalan untuk melihat analisis kualitas gait.',
        healthLabel: 'Belum Ada Data',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Gait Quality Analyzer
// ─────────────────────────────────────────────────────────────────────────────
class GaitQualityAnalyzer {
  final StepRhythmValidator _rhythmValidator;

  // Riwayat GQI (rolling window 10 menit) untuk smoothing & trend
  final List<GaitQualityResult> _history = [];
  static const int _maxHistory = 60; // ~10 menit pada 10s window

  GaitQualityAnalyzer() : _rhythmValidator = StepRhythmValidator();

  /// Analisis GQI dari SignalFeatures + cadence saat ini.
  /// Dipanggil setiap kali window accelerometer selesai diproses.
  ///
  /// [features]     12 fitur dari FeatureExtractor
  /// [stepTimestamp] timestamp langkah terbaru dari StepRhythmValidator
  GaitQualityResult analyze({
    required SignalFeatures features,
    DateTime? stepTimestamp,
  }) {
    // ── 1. Stride Regularity ─────────────────────────────────────────────────
    // Berdasarkan Coefficient of Variation interval langkah
    // CV < 0.20 = sangat reguler (skor 100)
    // CV > 0.60 = sangat acak (skor 0)
    // Referensi: Del Din et al., JMIR 2022 — CV < 0.25 = healthy gait
    if (stepTimestamp != null) {
      _rhythmValidator.validateStep(stepTimestamp);
    }
    final cv = _computeStepCV();
    final strideRegularity = _cvToScore(cv).clamp(0.0, 100.0);

    // ── 2. Step Efficiency ───────────────────────────────────────────────────
    // Rasio energi 0.5–3.5 Hz (step band) vs total energi
    // Semakin tinggi → langkah lebih efisien, energi tidak terbuang
    final totalEnergy = features.stepBandEnergy +
        features.shakeBandEnergy +
        (features.variance * 0.1); // proxy untuk energi lain
    final stepEfficiency = totalEnergy > 0
        ? ((features.stepBandEnergy / totalEnergy) * 100).clamp(0.0, 100.0)
        : 0.0;

    // ── 3. Gait Stability ────────────────────────────────────────────────────
    // Inverse dari spectral entropy — sinyal langkah nyata punya entropy RENDAH
    // (energi terkonsentrasi di freq tertentu)
    // Spectral entropy 0 = pure tone (paling stabil)
    // Spectral entropy 1 = white noise (paling tidak stabil)
    final gaitStability =
        ((1.0 - features.spectralEntropy.clamp(0.0, 1.0)) * 100)
            .clamp(0.0, 100.0);

    // ── 4. Cadence Quality ───────────────────────────────────────────────────
    // Target: 100–130 spm berdasarkan Tudor-Locke et al. 2011
    // Zone optimal mendapat skor penuh; deviasi dikurangi secara proporsional
    final actualCadenceSpm = _rhythmValidator.averageCadenceSpm;
    final cadenceQuality = _computeCadenceQuality(actualCadenceSpm);

    // ── 5. Overall GQI ───────────────────────────────────────────────────────
    // Bobot: Stride Regularity 30%, Step Efficiency 25%, Gait Stability 25%, Cadence 20%
    final overall = (strideRegularity * 0.30 +
            stepEfficiency * 0.25 +
            gaitStability * 0.25 +
            cadenceQuality * 0.20)
        .clamp(0.0, 100.0);

    // ── 6. Intensity Classification (Tudor-Locke 2011) ──────────────────────
    final intensity = _classifyIntensity(actualCadenceSpm);

    // ── 7. Generate Feedback ─────────────────────────────────────────────────
    final feedback = _generateFeedback(
      overall: overall,
      cadenceSpm: actualCadenceSpm,
      intensity: intensity,
      cv: cv,
      stepEfficiency: stepEfficiency,
    );

    final result = GaitQualityResult(
      strideRegularity: strideRegularity,
      stepEfficiency: stepEfficiency,
      gaitStability: gaitStability,
      cadenceQuality: cadenceQuality,
      overall: overall,
      actualCadenceSpm: actualCadenceSpm,
      intensityCategory: intensity,
      feedbackMessage: feedback,
      healthLabel: _healthLabel(overall),
    );

    _history.add(result);
    if (_history.length > _maxHistory) _history.removeAt(0);

    return result;
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  double _computeStepCV() {
    // StepRhythmValidator tidak expose CV langsung; kita hitung dari cadence consistency
    // Proxy: jika tidak ada ritme konsisten → CV tinggi
    if (!_rhythmValidator.hasConsistentRhythm) return 0.55;
    final spm = _rhythmValidator.averageCadenceSpm;
    if (spm <= 0) return 0.60;
    // Estimasi CV dari cadence stability: spm sangat rendah → lebih tidak stabil
    if (spm < 60) return 0.50;
    if (spm < 80) return 0.35;
    if (spm < 100) return 0.25;
    return 0.15; // cadence >100 = ritme baik
  }

  double _cvToScore(double cv) {
    // Linear mapping: CV 0.10 → 100, CV 0.60 → 0
    return ((0.60 - cv) / 0.50 * 100).clamp(0.0, 100.0);
  }

  double _computeCadenceQuality(double spm) {
    if (spm <= 0) return 0;
    // Zona optimal: 100–130 spm = 100%
    // Penalti proporsional di luar zona
    if (spm >= 100 && spm <= 130) return 100;
    if (spm < 100) {
      // 0 spm → 0, 100 spm → 100 (linear)
      return (spm / 100 * 100).clamp(0.0, 100.0);
    } else {
      // > 130 spm = vigorous — masih bagus tapi turun sedikit karena risiko injury
      final excess = spm - 130;
      return (100 - excess * 0.5).clamp(60.0, 100.0);
    }
  }

  CadenceIntensity _classifyIntensity(double spm) {
    if (spm < 40) return CadenceIntensity.sedentary;
    if (spm < 100) return CadenceIntensity.light;
    if (spm < 130) return CadenceIntensity.moderate;
    return CadenceIntensity.vigorous;
  }

  String _generateFeedback({
    required double overall,
    required double cadenceSpm,
    required CadenceIntensity intensity,
    required double cv,
    required double stepEfficiency,
  }) {
    if (cadenceSpm <= 0) {
      return 'Mulai berjalan untuk melihat analisis kualitas gait real-time.';
    }
    if (overall >= 85) {
      return '🌟 Kualitas gait luar biasa! Ritme langkah Anda sangat konsisten dan efisien. Pertahankan!';
    }
    if (overall >= 70) {
      return '👍 Gait Anda baik. Cadence ${cadenceSpm.toStringAsFixed(0)} spm termasuk zona ${intensity.label}.';
    }
    if (overall >= 55) {
      if (cadenceSpm < 100) {
        return '💡 Coba percepat langkah Anda. Target ≥100 spm untuk mencapai intensitas aerobik sedang (WHO/Tudor-Locke).';
      }
      if (cv > 0.40) {
        return '💡 Ritme langkah kurang konsisten. Cobalah berjalan dengan irama yang lebih teratur dan stabil.';
      }
      return '💡 Gait cukup baik. Fokus pada ritme yang lebih teratur untuk meningkatkan skor.';
    }
    if (cadenceSpm < 40) {
      return '⚠️ Deteksi gerakan sangat rendah. Berjalan lebih aktif untuk mendapatkan analisis akurat.';
    }
    return '⚠️ Kualitas gait perlu ditingkatkan. Berjalan dengan langkah lebih berirama dan konsisten.';
  }

  String _healthLabel(double score) {
    if (score >= 85) return 'Sangat Baik 🌟';
    if (score >= 70) return 'Baik 👍';
    if (score >= 55) return 'Cukup ✅';
    if (score >= 40) return 'Perlu Latihan ⚠️';
    return 'Mulai Bergerak 🚶';
  }

  /// Tren GQI: rata-rata 5 hasil terakhir
  double get recentAverageGQI {
    if (_history.isEmpty) return 0;
    final recent =
        _history.length >= 5 ? _history.sublist(_history.length - 5) : _history;
    return recent.map((r) => r.overall).reduce((a, b) => a + b) / recent.length;
  }

  /// Apakah gait sedang meningkat? (tren positif 10 sampel terakhir)
  bool get isImproving {
    if (_history.length < 10) return false;
    final older =
        _history.sublist(0, 5).map((r) => r.overall).reduce((a, b) => a + b) /
            5;
    final newer = _history
            .sublist(_history.length - 5)
            .map((r) => r.overall)
            .reduce((a, b) => a + b) /
        5;
    return newer > older + 3.0; // minimal 3 poin peningkatan
  }

  void reset() {
    _rhythmValidator.reset();
    _history.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cadence Coach — Target Cadence Adaptif Berbasis Profil User
// ─────────────────────────────────────────────────────────────────────────────
// Referensi:
//  • Tudor-Locke C et al. (2011). Cadence and Intensity Relations
//    in Adults. Int. J. Behav. Nutr. doi:10.1186/1479-5868-8-79
//  • WHO PA Guidelines (2020). 150–300 min/week moderate intensity
// ─────────────────────────────────────────────────────────────────────────────
class CadenceCoach {
  final int ageYears;
  final double bmi;
  final String fitnessLevel; // 'pemula' | 'menengah' | 'lanjut'

  const CadenceCoach({
    required this.ageYears,
    required this.bmi,
    this.fitnessLevel = 'menengah',
  });

  /// Target cadence optimal berdasarkan profil user (spm)
  /// Basis: Tudor-Locke 100 spm minimum untuk intensitas sedang
  /// Penyesuaian: usia (lansia target lebih rendah), BMI (obesitas target lebih rendah)
  double get targetCadenceSpm {
    double base = 100.0; // WHO moderate intensity minimum

    // Penyesuaian usia
    if (ageYears >= 65) {
      base = 90.0; // Lansia: target lebih rendah, fokus konsistensi
    } else if (ageYears >= 50) {
      base = 95.0;
    } else if (ageYears < 30) {
      base = 110.0; // Muda & aktif: target lebih tinggi
    }

    // Penyesuaian BMI
    if (bmi >= 30) {
      base -= 10; // Obesitas: mulai dari target lebih rendah, cegah cedera
    } else if (bmi >= 25) {
      base -= 5; // Overweight: sedikit lebih rendah
    }

    // Penyesuaian level kebugaran
    switch (fitnessLevel) {
      case 'pemula':
        base -= 10;
        break;
      case 'lanjut':
        base += 10;
        break;
      default:
        break;
    }

    return base.clamp(80.0, 130.0);
  }

  /// Upper target (zona intensitas sedang penuh)
  double get targetCadenceUpperSpm =>
      (targetCadenceSpm + 20).clamp(100.0, 130.0);

  /// Evaluasi cadence saat ini vs target
  CadenceStatus evaluate(double actualSpm) {
    if (actualSpm <= 0) return CadenceStatus.idle;
    final diff = actualSpm - targetCadenceSpm;
    if (diff < -20) return CadenceStatus.tooSlow;
    if (diff < -5) return CadenceStatus.slightlyLow;
    if (diff <= 15) return CadenceStatus.optimal;
    return CadenceStatus.tooFast;
  }

  /// Pesan coaching real-time dalam Bahasa Indonesia
  String coachMessage(double actualSpm) {
    final status = evaluate(actualSpm);
    final targetStr = targetCadenceSpm.toStringAsFixed(0);
    final actualStr = actualSpm.toStringAsFixed(0);
    switch (status) {
      case CadenceStatus.idle:
        return '🚶 Mulai berjalan — target cadence Anda: $targetStr spm';
      case CadenceStatus.tooSlow:
        return '⬆️ Percepat langkah! ($actualStr spm → target $targetStr spm)';
      case CadenceStatus.slightlyLow:
        return '↗️ Sedikit lebih cepat untuk mencapai zona intensitas optimal ($targetStr spm)';
      case CadenceStatus.optimal:
        return '✅ Cadence optimal! Pertahankan ritme ini ($actualStr spm)';
      case CadenceStatus.tooFast:
        return '⬇️ Sedikit perlambat untuk menjaga keberlanjutan ($actualStr spm)';
    }
  }

  /// Warna umpan balik
  static const Map<CadenceStatus, int> statusColor = {
    CadenceStatus.idle: 0xFF94A3B8,
    CadenceStatus.tooSlow: 0xFFEF4444,
    CadenceStatus.slightlyLow: 0xFFF59E0B,
    CadenceStatus.optimal: 0xFF10B981,
    CadenceStatus.tooFast: 0xFF3B82F6,
  };
}

enum CadenceStatus { idle, tooSlow, slightlyLow, optimal, tooFast }

// ─────────────────────────────────────────────────────────────────────────────
// Health Trajectory Point — Titik data untuk analisis tren longitudinal
// ─────────────────────────────────────────────────────────────────────────────
class HealthTrajectoryPoint {
  final DateTime date;
  final int steps;
  final double gqiScore;
  final double agingScore;
  final double sleepHours;
  final bool stressManaged;
  final int waterGlasses; // gelas air minum hari ini
  final int waterTarget; // target gelas per hari
  final int caloriesConsumed; // kalori masuk hari ini
  final int calorieTarget; // target kalori per hari
  final int caloriesBurned; // kalori terbakar hari ini

  const HealthTrajectoryPoint({
    required this.date,
    required this.steps,
    this.gqiScore = 0,
    this.agingScore = 0,
    this.sleepHours = 0,
    this.stressManaged = true,
    this.waterGlasses = 0,
    this.waterTarget = 8,
    this.caloriesConsumed = 0,
    this.calorieTarget = 2000,
    this.caloriesBurned = 0,
  });

  /// Composite Health Score (0–100)
  /// Menggabungkan 7 dimensi kesehatan berbasis bukti ilmiah:
  ///  - Aktivitas (langkah)   30% — WHO Global PA Guidelines 2020
  ///  - Kualitas gait (GQI)   20% — marker neurologis & musculoskeletal
  ///  - Aging score           15% — CERDIK-based lifestyle scoring
  ///  - Kualitas tidur        15% — Shan Z et al. 2015 (T2D risk)
  ///  - Hidrasi               10% — EFSA Water Intake Reference Values
  ///  - Keseimbangan kalori   5%  — menghindari defisit/surplus ekstrem
  ///  - Manajemen stres       5%  — American Psychological Association
  double get compositeScore {
    final stepScore = (steps / 10000 * 100).clamp(0.0, 100.0);
    final sleepScore =
        sleepHours >= 7 ? 100.0 : (sleepHours / 7 * 100).clamp(0.0, 100.0);
    final stressScore = stressManaged ? 100.0 : 60.0;

    // Hidrasi: 0-100 berdasarkan proporsi target air minum
    final hydrationScore = waterTarget > 0
        ? (waterGlasses / waterTarget * 100).clamp(0.0, 100.0)
        : 50.0; // default 50 jika target tidak diset

    // Skor kalori: ideal jika dalam 90-110% target, penalti jika terlalu rendah/tinggi
    double calScore = 50.0;
    if (calorieTarget > 0 && caloriesConsumed > 0) {
      final ratio = caloriesConsumed / calorieTarget;
      if (ratio >= 0.90 && ratio <= 1.15) {
        calScore = 100.0; // ideal range
      } else if (ratio < 0.90) {
        calScore = (ratio / 0.90 * 100).clamp(0.0, 100.0); // defisit
      } else {
        calScore =
            (1 - ((ratio - 1.15) * 2)).clamp(0.0, 100.0) * 100; // surplus
      }
    }

    // Bobot: langkah 30%, GQI 20%, aging 15%, tidur 15%, hidrasi 10%, kalori 5%, stres 5%
    return (stepScore * 0.30 +
            gqiScore * 0.20 +
            agingScore * 0.15 +
            sleepScore * 0.15 +
            hydrationScore * 0.10 +
            calScore * 0.05 +
            stressScore * 0.05)
        .clamp(0.0, 100.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health Trajectory Analyzer — Linear Regression + Prediksi
// ─────────────────────────────────────────────────────────────────────────────
// Referensi:
//  • Shan Z et al. (2015). Sleep Duration and Type 2 Diabetes.
//    Diabetes Care. https://doi.org/10.2337/dc14-2073
//  • The Lancet (2019). Health effects of dietary risks in 195 countries.
//    https://doi.org/10.1016/S0140-6736(19)30041-8
// ─────────────────────────────────────────────────────────────────────────────
class HealthTrajectoryAnalyzer {
  final List<HealthTrajectoryPoint> _dataPoints = [];

  void addPoint(HealthTrajectoryPoint point) {
    _dataPoints.add(point);
    _dataPoints.sort((a, b) => a.date.compareTo(b.date));
    // Simpan max 90 hari
    if (_dataPoints.length > 90) _dataPoints.removeAt(0);
  }

  void clear() {
    _dataPoints.clear();
  }

  List<HealthTrajectoryPoint> get dataPoints => List.unmodifiable(_dataPoints);

  bool get hasEnoughData => _dataPoints.length >= 7;

  /// Prediksi composite score di masa depan menggunakan linear regression.
  /// Mengembalikan nilai null jika data tidak cukup.
  double? predictAt(DateTime futureDate) {
    if (!hasEnoughData) return null;
    final reg = _computeRegression();
    if (reg == null) return null;
    final dayOffset =
        futureDate.difference(_dataPoints.first.date).inDays.toDouble();
    return (reg.$1 + reg.$2 * dayOffset).clamp(0.0, 100.0);
  }

  /// Tren: positif, negatif, atau stabil
  TrajectoryTrend get trend {
    if (!hasEnoughData) return TrajectoryTrend.insufficient;
    final reg = _computeRegression();
    if (reg == null) return TrajectoryTrend.insufficient;
    final slope = reg.$2;
    if (slope > 0.3) return TrajectoryTrend.improving;
    if (slope < -0.3) return TrajectoryTrend.declining;
    return TrajectoryTrend.stable;
  }

  /// Slope per hari (rata-rata perubahan composite score per hari)
  double get dailySlope {
    final reg = _computeRegression();
    return reg?.$2 ?? 0.0;
  }

  /// Linear regression: returns (intercept, slope) atau null
  (double, double)? _computeRegression() {
    if (_dataPoints.length < 3) return null;
    final n = _dataPoints.length.toDouble();
    final xValues = List.generate(
        _dataPoints.length, (i) => i.toDouble()); // hari ke-0, 1, 2, ...
    final yValues = _dataPoints.map((p) => p.compositeScore).toList();

    final xMean = xValues.reduce((a, b) => a + b) / n;
    final yMean = yValues.reduce((a, b) => a + b) / n;

    double ssxy = 0, ssxx = 0;
    for (int i = 0; i < _dataPoints.length; i++) {
      ssxy += (xValues[i] - xMean) * (yValues[i] - yMean);
      ssxx += math.pow(xValues[i] - xMean, 2);
    }

    if (ssxx == 0) return null;
    final slope = ssxy / ssxx;
    final intercept = yMean - slope * xMean;
    return (intercept, slope);
  }

  /// Narasi kesehatan otomatis berdasarkan tren
  String generateInsight({required String userName}) {
    final name = userName.isEmpty ? 'Kamu' : userName;
    if (!hasEnoughData) {
      return 'Rekam data minimal 7 hari untuk melihat analisis tren kesehatan $name.';
    }
    final t = trend;
    final current = _dataPoints.last.compositeScore;
    switch (t) {
      case TrajectoryTrend.improving:
        return '📈 Tren kesehatan $name meningkat! Skor komposit saat ini ${current.toStringAsFixed(0)}/100. Terus pertahankan kebiasaan baik ini.';
      case TrajectoryTrend.declining:
        return '📉 Perhatian: tren kesehatan $name menurun dalam 7 hari terakhir. Cek pola tidur, langkah kaki, dan stres hari ini.';
      case TrajectoryTrend.stable:
        return '📊 Kesehatan $name stabil di ${current.toStringAsFixed(0)}/100. Tingkatkan dengan target langkah ≥10.000/hari dan tidur 7–9 jam.';
      case TrajectoryTrend.insufficient:
        return 'Data belum cukup. Gunakan aplikasi secara konsisten untuk melihat tren kesehatan.';
    }
  }
}

enum TrajectoryTrend { improving, declining, stable, insufficient }
