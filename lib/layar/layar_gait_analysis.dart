// ============================================================
// LAYAR ANALISIS GAIT — Gait Quality Index Dashboard
// ============================================================
// Menampilkan analisis kualitas langkah kaki secara real-time
// berbasis GQI (4 dimensi) + Cadence Coach.
//
// Referensi Ilmiah:
//  • Del Din et al. (2022). JMIR mHealth — Smartphone Gait Analysis
//  • Tudor-Locke et al. (2011). Int. J. Behav. Nutr. — Cadence & Intensity
//  • Frontiers Aging Neuroscience (2023) — Gait sebagai Biomarker Penuaan
//  • WHO PA Guidelines (2020) — 150+ min/week moderate intensity
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../inti/tema/design_tokens.dart';
import 'dart:math' as math;
import '../inti/ml/gait_quality_index.dart';
import '../inti/ml/filter_sinyal.dart';
import '../inti/tema/ikon_mapper.dart';
import '../penyedia/penyedia_aktivitas.dart';
import '../komponen/kutipan_sumber.dart';
import '../widget/nubi_mascot.dart';
import 'layar_referensi.dart';

class GaitAnalysisScreen extends StatefulWidget {
  const GaitAnalysisScreen({super.key});

  @override
  State<GaitAnalysisScreen> createState() => _GaitAnalysisScreenState();
}

class _GaitAnalysisScreenState extends State<GaitAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  GaitQualityResult _result = GaitQualityResult.empty;
  CadenceCoach? _coach;
  bool _isSimulating = false;

  // Riwayat GQI untuk mini chart (last 10)
  final List<double> _gqiHistory = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initCoach());
  }

  void _initCoach() {
    final ap = context.read<ActivityProvider>();
    _coach = CadenceCoach(
      ageYears: ap.age,
      bmi: ap.bmi,
      fitnessLevel: _mapFitnessLevel(ap.workoutLevel),
    );
  }

  String _mapFitnessLevel(String? level) {
    if (level == null) return 'menengah';
    if (level.toLowerCase().contains('pemula') ||
        level.toLowerCase().contains('beginner')) {
      return 'pemula';
    }
    if (level.toLowerCase().contains('lanjut') ||
        level.toLowerCase().contains('advanced')) {
      return 'lanjut';
    }
    return 'menengah';
  }

  void _simulateGait() async {
    if (_isSimulating) return;
    setState(() => _isSimulating = true);

    final analyzer = GaitQualityAnalyzer();

    // Simulasi 5 window analisis (menggunakan fitur dummy untuk demo)
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      // Simulasi fitur sinyal berjalan normal 100 spm
      final fakeFeatures = SignalFeatures(
        mean: 9.8,
        stdDev: 1.2 + (i * 0.1),
        rms: 10.2,
        variance: 1.44,
        zcr: 40.0 + (i * 2),
        peakToPeak: 4.8,
        dominantFreqHz: 1.7, // ~100 spm = 1.67 Hz
        stepBandEnergy: 0.65,
        shakeBandEnergy: 0.08,
        kurtosis: 3.2,
        skewness: 0.1,
        spectralEntropy: 0.35,
      );

      final now = DateTime.now();
      final result = analyzer.analyze(
        features: fakeFeatures,
        stepTimestamp: now,
      );

      setState(() {
        _result = result;
        _gqiHistory.add(result.overall);
        if (_gqiHistory.length > 10) _gqiHistory.removeAt(0);
      });
    }

    setState(() => _isSimulating = false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final ap = context.watch<ActivityProvider>();
    final result = _isSimulating ? _result : (ap as dynamic).lastGaitQuality ?? 0;
    final coach = _coach ?? CadenceCoach(ageYears: ap.age, bmi: ap.bmi);
    final cadenceSpm = result.actualCadenceSpm;
    final coachStatus = coach.evaluate(cadenceSpm);
    final statusColorValue =
        CadenceCoach.statusColor[coachStatus] ?? 0xFF94A3B8;
    final statusColor = Color(statusColorValue);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text(
          'Gait Quality Index',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Sumber Ilmiah',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReferencesScreen(
                  title: 'Referensi: Analisis Gait',
                  tags: ['gait', 'steps', 'cadence', 'aging'],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Intro ──────────────────────────────────────────────────────────
          _InfoCard(theme: theme),
          const SizedBox(height: 16),

          // ── GQI Meter (Circular) ───────────────────────────────────────────
          _GqiCircularMeter(
            score: result.overall,
            label: result.healthLabel,
            pulseAnimation: _pulseAnimation,
            ext: ext,
          ),
          const SizedBox(height: 16),

          // ── Nubi Reaction Bubble ──────────────────────────────────────────
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: NubiMascot(
                    pose: result.overall >= 75
                        ? NubiPose.success
                        : result.overall >= 55
                            ? NubiPose.wave
                            : result.overall > 0
                                ? NubiPose.doctor
                                : NubiPose.meditate,
                    size: 55,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    result.overall >= 85
                        ? 'Wah, kualitas berjalanmu luar biasa! Ritme dan langkahmu sangat mantap. Nubi bangga! 🌟'
                        : result.overall >= 70
                            ? 'Langkahmu sudah baik dan stabil! Pertahankan ritme berjalan sehat ini ya! 👍'
                            : result.overall >= 55
                                ? 'Ayo percepat sedikit langkahmu! Kejar target cadence spm optimalmu bersama Nubi! ↗️'
                                : result.overall > 0
                                    ? 'Aktivitas terdeteksi, tapi ritme langkahmu kurang teratur. Yuk ikuti panduan coach! ⚠️'
                                    : 'Halo! Nubi siap menemanimu berjalan sehat hari ini. Yuk mulai bergerak! 🚶‍♂️',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 4 Dimensi GQI ─────────────────────────────────────────────────
          Text(
            '📐 4 Dimensi Kualitas Gait',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _DimensionGrid(result: result, theme: theme),
          const SizedBox(height: 16),

          // ── Cadence Coach ──────────────────────────────────────────────────
          _CadenceCoachCard(
            result: result,
            coach: coach,
            coachStatus: coachStatus,
            statusColor: statusColor,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // ── Feedback Message ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💬 Umpan Balik',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.feedbackMessage,
                  style: TextStyle(
                    height: 1.5,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Mini History Chart ─────────────────────────────────────────────
          if (_gqiHistory.length >= 2) ...[
            _MiniLineChart(values: _gqiHistory, theme: theme),
            const SizedBox(height: 16),
          ],

          // ── Demo Button ────────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _isSimulating ? null : _simulateGait,
            icon: _isSimulating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.directions_walk_rounded),
            label: Text(
                _isSimulating ? 'Menganalisis...' : 'Simulasi Analisis Gait'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          const CitationWidget(
            sources: [
              'Del Din S et al., JMIR mHealth, 2022',
              'Tudor-Locke C et al., Int. J. Behav. Nutr., 2011',
              'Frontiers Aging Neuroscience, 2023',
              'WHO PA Guidelines, 2020',
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Info Card
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final ThemeData theme;
  const _InfoCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_walk_rounded, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gait Quality Index (GQI)',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analisis kualitas berjalan real-time dari sensor accelerometer. '
                  'Gait yang teratur adalah biomarker kesehatan dan risiko penuaan. '
                  '(Del Din et al., JMIR 2022)',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: GQI Circular Meter
// ─────────────────────────────────────────────────────────────────────────────
class _GqiCircularMeter extends StatelessWidget {
  final double score;
  final String label;
  final Animation<double> pulseAnimation;
  final AppThemeExtension? ext;

  const _GqiCircularMeter({
    required this.score,
    required this.label,
    required this.pulseAnimation,
    this.ext,
  });

  Color _scoreColor(double s) {
    if (s >= 75) return AppColors.success;
    if (s >= 55) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);

    return Center(
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (_, child) => Transform.scale(
          scale: score > 0 ? pulseAnimation.value : 1.0,
          child: child,
        ),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.04),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: 4 Dimension Grid
// ─────────────────────────────────────────────────────────────────────────────
class _DimensionGrid extends StatelessWidget {
  final GaitQualityResult result;
  final ThemeData theme;

  const _DimensionGrid({required this.result, required this.theme});

  @override
  Widget build(BuildContext context) {
    final dims = [
      _DimData(
        label: 'Stride Regularity',
        value: result.strideRegularity,
        icon: Icons.health_and_safety_rounded,
        hint: 'CV interval langkah\n(Del Din 2022)',
        color: const Color(0xFF8B5CF6),
      ),
      _DimData(
        label: 'Step Efficiency',
        value: result.stepEfficiency,
        icon: Icons.bolt_rounded,
        hint: 'Energi band langkah\n(Ainsworth 2011)',
        color: const Color(0xFFF59E0B),
      ),
      _DimData(
        label: 'Gait Stability',
        value: result.gaitStability,
        icon: Icons.bar_chart_rounded,
        hint: 'Inv. Spectral Entropy\n(MDPI Sensors 2021)',
        color: const Color(0xFF06B6D4),
      ),
      _DimData(
        label: 'Cadence Quality',
        value: result.cadenceQuality,
        icon: Icons.health_and_safety_rounded,
        hint: 'vs target ≥100 spm\n(Tudor-Locke 2011)',
        color: AppColors.primary,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: dims.map((d) => _DimCard(data: d, theme: theme)).toList(),
    );
  }
}

class _DimData {
  final String label, hint;
  final IconData icon;
  final double value;
  final Color color;

  const _DimData({
    required this.label,
    required this.value,
    required this.icon,
    required this.hint,
    required this.color,
  });
}

class _DimCard extends StatelessWidget {
  final _DimData data;
  final ThemeData theme;

  const _DimCard({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: data.color,
                  height: 1,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: 11,
                  color: data.color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.value / 100,
              minHeight: 5,
              backgroundColor: data.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(data.color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.hint,
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Cadence Coach Card
// ─────────────────────────────────────────────────────────────────────────────
class _CadenceCoachCard extends StatelessWidget {
  final GaitQualityResult result;
  final CadenceCoach coach;
  final CadenceStatus coachStatus;
  final Color statusColor;
  final ThemeData theme;

  const _CadenceCoachCard({
    required this.result,
    required this.coach,
    required this.coachStatus,
    required this.statusColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final actualSpm = result.actualCadenceSpm;
    final targetSpm = coach.targetCadenceSpm;
    final progress =
        actualSpm > 0 ? (actualSpm / targetSpm).clamp(0.0, 1.2) : 0.0;
    final intensity = result.intensityCategory;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(IkonMapper.dariEmoji(intensity.emoji), size: 20, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cadence Coach',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      intensity.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Actual cadence badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${actualSpm.toStringAsFixed(0)} spm',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar: actual vs target
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cadence Anda',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          'Target: ${targetSpm.toStringAsFixed(0)} spm',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: statusColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Coach message
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              coach.coachMessage(actualSpm),
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '📖 Tudor-Locke et al., 2011: cadence ≥100 spm = intensitas sedang (WHO moderate intensity)',
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Mini Line Chart (GQI History)
// ─────────────────────────────────────────────────────────────────────────────
class _MiniLineChart extends StatelessWidget {
  final List<double> values;
  final ThemeData theme;

  const _MiniLineChart({required this.values, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Tren GQI Session Ini',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _LineChartPainter(
                values: values,
                color: AppColors.primary,
              ),
              size: const Size(double.infinity, 80),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Awal',
                  style: TextStyle(
                      fontSize: 9,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              Text('Sekarang',
                  style: TextStyle(
                      fontSize: 9,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _LineChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final maxVal = values.reduce(math.max).clamp(1.0, 100.0);
    final minVal = values.reduce(math.min).clamp(0.0, 99.0);
    final range = (maxVal - minVal).clamp(5.0, 100.0);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (size.height * (values[i] - minVal) / range);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Dot at last point
    if (values.isNotEmpty) {
      final lastX = size.width.toDouble();
      final lastY =
          size.height - (size.height * (values.last - minVal) / range);
      canvas.drawCircle(
        Offset(lastX, lastY),
        5,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values || old.color != color;
}

// Import untuk SignalFeatures — tersedia dari filter_sinyal.dart via gait_quality_index.dart
