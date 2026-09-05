class LifestyleAgingInputs {
  final String smokingStatus;
  final int moderateActivityMinutesPerWeek;
  final int sugaryDrinksPerWeek;
  final double bmi;
  final bool sleepAdequate;
  final bool stressManaged;

  const LifestyleAgingInputs({
    required this.smokingStatus,
    required this.moderateActivityMinutesPerWeek,
    required this.sugaryDrinksPerWeek,
    required this.bmi,
    required this.sleepAdequate,
    required this.stressManaged,
  });
}

class LifestyleAgingResult {
  final int score; // 0..100 (higher = better)
  final List<String> deductions;

  const LifestyleAgingResult({required this.score, required this.deductions});
}

class LifestyleAgingScore {
  /// Transparent heuristic score (not biological age):
  /// starts at 100, subtracts penalties from CERDIK-aligned factors.
  static LifestyleAgingResult calculate(LifestyleAgingInputs inps) {
    var score = 100;
    final deductions = <String>[];

    if (inps.smokingStatus == 'merokok') {
      score -= 25;
      deductions.add('-25: merokok aktif');
    } else if (inps.smokingStatus == 'terpapar_asap') {
      score -= 12;
      deductions.add('-12: sering terpapar asap rokok');
    }

    if (inps.moderateActivityMinutesPerWeek < 150) {
      score -= 15;
      deductions.add('-15: aktivitas fisik < 150 menit/minggu');
    }

    if (inps.sugaryDrinksPerWeek >= 7) {
      score -= 15;
      deductions.add('-15: minuman manis ≥ 1x/hari');
    } else if (inps.sugaryDrinksPerWeek >= 3) {
      score -= 8;
      deductions.add('-8: minuman manis 3-6x/minggu');
    }

    if (inps.bmi >= 30) {
      score -= 15;
      deductions.add('-15: BMI obesitas (≥ 30)');
    } else if (inps.bmi >= 25) {
      score -= 8;
      deductions.add('-8: BMI overweight (25-29.9)');
    }

    if (!inps.sleepAdequate) {
      score -= 10;
      deductions.add('-10: istirahat kurang');
    }

    if (!inps.stressManaged) {
      score -= 10;
      deductions.add('-10: stres tidak terkelola');
    }

    if (score < 0) score = 0;
    if (score > 100) score = 100;
    return LifestyleAgingResult(score: score, deductions: deductions);
  }
}
