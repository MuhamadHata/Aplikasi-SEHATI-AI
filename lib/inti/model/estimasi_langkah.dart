class StepIntensityPreset {
  final String id;
  final String label;
  final double met;
  final int stepsPerMinute;
  final String description;
  final String citation;

  const StepIntensityPreset({
    required this.id,
    required this.label,
    required this.met,
    required this.stepsPerMinute,
    this.description = '',
    this.citation = '',
  });
}

/// Komprehensif: rumus MET untuk estimasi kalori dari aktivitas fisik.
///
/// RUMUS:
///   kkal = MET × Berat (kg) × Durasi (jam)
///
/// MET (Metabolic Equivalent of Task) adalah unit yang menggambarkan
/// intensitas relatif aktivitas fisik. Nilai MET 1.0 = duduk diam.
///
/// Kutipan:
/// - WHO Physical Activity Guidelines, 2020
/// - Ainsworth BE et al., Compendium of Physical Activities, 2011
/// - Kemenkes RI, Pedoman Aktivitas Fisik Indonesia, 2020
class StepCalorieEstimator {
  static const String metFormula =
      'kkal = MET × Berat(kg) × Waktu(jam)';

  static const String metExplanation =
      'MET (Metabolic Equivalent of Task) adalah rasio laju metabolisme '
      'saat beraktivitas dibanding istirahat. Contoh: MET 3.8 artinya '
      'tubuh membakar 3.8× lebih banyak energi daripada saat diam. '
      'Rumus ini divalidasi oleh WHO untuk estimasi pengeluaran energi '
      'aktivitas fisik pada populasi umum.';

  static const List<String> formulaCitations = [
    'WHO Physical Activity Guidelines, 2020',
    'Ainsworth et al., Compendium of PA, 2011',
    'Kemenkes RI, Pedoman AktFisik, 2020',
  ];

  static const presets = <StepIntensityPreset>[
    StepIntensityPreset(
      id: 'walk_easy',
      label: 'Jalan santai',
      met: 2.8,
      stepsPerMinute: 90,
      description: 'Berjalan pelan ~3–4 km/jam, tanpa beban berat. '
          'Cocok untuk pemula, lansia, atau pemulihan pasca olahraga.',
      citation: 'MET 2.8 – Ainsworth et al., 2011',
    ),
    StepIntensityPreset(
      id: 'walk_brisk',
      label: 'Jalan cepat',
      met: 3.8,
      stepsPerMinute: 110,
      description: 'Berjalan cepat ~5–6 km/jam, terasa agak ngos-ngosan. '
          'WHO merekomendasikan minimal 150 mnt/minggu jenis ini untuk '
          'kesehatan kardiovaskular.',
      citation: 'MET 3.8 – Ainsworth et al., 2011 | WHO PA Guidelines, 2020',
    ),
    StepIntensityPreset(
      id: 'run_light',
      label: 'Lari ringan',
      met: 7.0,
      stepsPerMinute: 160,
      description: 'Lari ringan ~8 km/jam. Aktivitas aerobik intensitas '
          'tinggi yang sangat efektif membakar kalori & meningkatkan '
          'kapasitas jantung-paru.',
      citation: 'MET 7.0 – Ainsworth et al., 2011',
    ),
  ];

  /// Approximation using MET:
  /// kcal = MET * weightKg * hours
  static int estimateStepsForCalories({
    required int caloriesKcal,
    required double weightKg,
    required StepIntensityPreset preset,
  }) {
    if (caloriesKcal <= 0 || weightKg <= 0) return 0;
    final steps =
        caloriesKcal * 60.0 * preset.stepsPerMinute / (preset.met * weightKg);
    return steps.round().clamp(0, 200000);
  }

  static int estimateCaloriesForSteps({
    required int steps,
    required double weightKg,
    required StepIntensityPreset preset,
  }) {
    if (steps <= 0 || weightKg <= 0) return 0;
    final hours = steps / (preset.stepsPerMinute * 60.0);
    final kcal = preset.met * weightKg * hours;
    return kcal.round().clamp(0, 20000);
  }

  /// Estimasi menit yang dibutuhkan untuk membakar [caloriesKcal] kkal
  static int estimateMinutesForCalories({
    required int caloriesKcal,
    required double weightKg,
    required StepIntensityPreset preset,
  }) {
    if (caloriesKcal <= 0 || weightKg <= 0) return 0;
    final hours = caloriesKcal / (preset.met * weightKg);
    return (hours * 60).round().clamp(0, 9999);
  }
}
