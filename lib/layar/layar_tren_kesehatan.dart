// ============================================================
// LAYAR TREN KESEHATAN LONGITUDINAL
// Health Trajectory — Pemantauan Jangka Panjang
// ============================================================
// Visualisasi tren composite health score 30 hari menggunakan
// regresi linier untuk prediksi dan deteksi pola.
//
// Referensi Ilmiah:
//  • Shan Z et al. (2015). Sleep & T2D Risk. Diabetes Care.
//    https://doi.org/10.2337/dc14-2073
//  • Lancet (2019). Health effects of dietary risks (GBD 2017).
//    https://doi.org/10.1016/S0140-6736(19)30041-8
//  • Tudor-Locke et al. (2011). Step counts & health outcomes.
//    Int. J. Behav. Nutr. doi:10.1186/1479-5868-8-79
//  • WHO PA Guidelines (2020) — target aktivitas mingguan
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../inti/tema/design_tokens.dart';
import 'dart:math' as math;
import '../inti/ml/gait_quality_index.dart';
import '../penyedia/penyedia_aktivitas.dart';
import '../komponen/kutipan_sumber.dart';
import '../widget/nubi_mascot.dart';
import 'layar_referensi.dart';

class HealthTrajectoryScreen extends StatefulWidget {
  const HealthTrajectoryScreen({super.key});

  @override
  State<HealthTrajectoryScreen> createState() => _HealthTrajectoryScreenState();
}

class _HealthTrajectoryScreenState extends State<HealthTrajectoryScreen> {
  final HealthTrajectoryAnalyzer _analyzer = HealthTrajectoryAnalyzer();
  List<HealthTrajectoryPoint> _points = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final ap = context.read<ActivityProvider>();
    final pts = (ap as dynamic).healthTrajectoryPoints ?? [];
    _analyzer.clear();
    for (final p in pts) {
      _analyzer.addPoint(p);
    }

    setState(() {
      _points = List.from(_analyzer.dataPoints);
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ap = context.watch<ActivityProvider>();
    final userName = ap.userName;
    final trend = _analyzer.trend;
    final insight = _analyzer.generateInsight(userName: userName);
    final hasPrediction = _analyzer.hasEnoughData;
    final in7Days = hasPrediction
        ? _analyzer.predictAt(DateTime.now().add(const Duration(days: 7)))
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text(
          'Tren Kesehatan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Referensi',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReferencesScreen(
                  title: 'Referensi: Tren Kesehatan',
                  tags: ['sleep', 'activity', 'aging', 'gait'],
                ),
              ),
            ),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Trend Indicator ──────────────────────────────────────
                _TrendBanner(trend: trend, insight: insight, theme: theme),
                const SizedBox(height: 16),

                // ── Nubi Trend Reaction Bubble ────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: NubiMascot(
                          pose: trend == TrajectoryTrend.improving
                              ? NubiPose.success
                              : trend == TrajectoryTrend.declining
                                  ? NubiPose.doctor
                                  : trend == TrajectoryTrend.stable
                                      ? NubiPose.study
                                      : NubiPose.meditate,
                          size: 55,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: theme.dividerColor.withOpacity(0.12)),
                        ),
                        child: Text(
                          trend == TrajectoryTrend.improving
                              ? 'Yey! Tren kesehatanmu secara keseluruhan meningkat pesat! Pertahankan konsistensi ini ya! 🎉'
                              : trend == TrajectoryTrend.declining
                                  ? 'Oh tidak! Tren kesehatan kompositmu sedang menurun. Jaga pola tidur dan kurangi stres ya. ⚠️'
                                  : trend == TrajectoryTrend.stable
                                      ? 'Kondisimu stabil dan terjaga baik. Yuk tingkatkan langkah dan kualitas tidurmu agar lebih prima! 📊'
                                      : 'Halo! Nubi sedang menganalisis datamu. Gunakan aplikasi minimal 7 hari untuk melihat prediksimu! ⏳',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Composite Score Chart ─────────────────────────────────
                _TrajectoryChart(points: _points, theme: theme),
                const SizedBox(height: 16),

                // ── 7-day Prediction ──────────────────────────────────────
                if (hasPrediction && in7Days != null)
                  _PredictionCard(
                    in7Days: in7Days,
                    slope: _analyzer.dailySlope,
                    theme: theme,
                  ),
                const SizedBox(height: 16),

                // ── 30-hari Statistics ────────────────────────────────────
                _StatisticsGrid(points: _points, theme: theme),
                const SizedBox(height: 16),

                // ── Komponen Breakdown ─────────────────────────────────────
                _ComponentBreakdown(points: _points, theme: theme),
                const SizedBox(height: 16),

                // ── Minimum Data Notice ───────────────────────────────────
                if (!_analyzer.hasEnoughData)
                  _InsufficientDataCard(
                      daysRecorded: _points.length, theme: theme),
                const SizedBox(height: 16),

                const CitationWidget(
                  sources: [
                    'Tudor-Locke C et al., Int. J. Behav. Nutr., 2011',
                    'Diabetes Care — Shan Z et al., 2015',
                    'The Lancet — Afshin A et al., 2019',
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
// Widget: Trend Banner
// ─────────────────────────────────────────────────────────────────────────────
class _TrendBanner extends StatelessWidget {
  final TrajectoryTrend trend;
  final String insight;
  final ThemeData theme;

  const _TrendBanner({
    required this.trend,
    required this.insight,
    required this.theme,
  });

  Color _trendColor() {
    switch (trend) {
      case TrajectoryTrend.improving:
        return AppColors.success;
      case TrajectoryTrend.declining:
        return AppColors.error;
      case TrajectoryTrend.stable:
        return AppColors.warning;
      case TrajectoryTrend.insufficient:
        return theme.colorScheme.outline;
    }
  }

  String _trendEmoji() {
    switch (trend) {
      case TrajectoryTrend.improving:
        return '📈';
      case TrajectoryTrend.declining:
        return '📉';
      case TrajectoryTrend.stable:
        return '📊';
      case TrajectoryTrend.insufficient:
        return '⏳';
    }
  }

  String _trendTitle() {
    switch (trend) {
      case TrajectoryTrend.improving:
        return 'Tren Membaik';
      case TrajectoryTrend.declining:
        return 'Perlu Perhatian';
      case TrajectoryTrend.stable:
        return 'Tren Stabil';
      case TrajectoryTrend.insufficient:
        return 'Data Terbatas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _trendColor();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(_trendEmoji(), style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _trendTitle(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
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
// Widget: Trajectory Chart (Composite Score 30 hari)
// ─────────────────────────────────────────────────────────────────────────────
class _TrajectoryChart extends StatelessWidget {
  final List<HealthTrajectoryPoint> points;
  final ThemeData theme;

  const _TrajectoryChart({required this.points, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Skor Kesehatan Komposit (${points.length} hari)',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gabungan langkah, tidur, aging score, & stres',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _TrajectoryChartPainter(
                points: points,
                primaryColor: AppColors.primary,
                isDark: theme.brightness == Brightness.dark,
              ),
              size: const Size(double.infinity, 140),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                points.length >= 2 ? _formatDate(points.first.date) : '',
                style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
              Row(
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Komposit',
                      style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                ],
              ),
              Text(
                'Hari Ini',
                style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}';
  }
}

class _TrajectoryChartPainter extends CustomPainter {
  final List<HealthTrajectoryPoint> points;
  final Color primaryColor;
  final bool isDark;

  const _TrajectoryChartPainter({
    required this.points,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final values = points.map((p) => p.compositeScore).toList();
    final maxVal = values.reduce(math.max).clamp(1.0, 100.0);
    final minVal = (values.reduce(math.min) - 10).clamp(0.0, 90.0);
    final range = (maxVal - minVal).clamp(5.0, 100.0);

    // Grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.30),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Line paint
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - (size.height * (values[i] - minVal) / range);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Smooth bezier
        final prevX = size.width * (i - 1) / (points.length - 1);
        final prevY =
            size.height - (size.height * (values[i - 1] - minVal) / range);
        final cpX1 = prevX + (x - prevX) / 2;
        path.cubicTo(cpX1, prevY, cpX1, y, x, y);
        fillPath.cubicTo(cpX1, prevY, cpX1, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Last point dot
    if (points.isNotEmpty) {
      final lastX = size.width;
      final lastY =
          size.height - (size.height * (values.last - minVal) / range);
      canvas.drawCircle(
        Offset(lastX, lastY),
        6,
        Paint()..color = primaryColor,
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        3,
        Paint()..color = Colors.white,
      );
    }

    // Y axis labels (0, 50, 100)
    final textStyle = TextStyle(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
      fontSize: 9,
    );
    for (final val in [100.0, 50.0, 0.0]) {
      final y = size.height - (size.height * (val - minVal) / range);
      if (y < 0 || y > size.height) continue;
      final tp = TextPainter(
        text: TextSpan(text: '${val.toInt()}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - 6));
    }
  }

  @override
  bool shouldRepaint(_TrajectoryChartPainter old) =>
      old.points != points || old.primaryColor != primaryColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: 7-day Prediction Card
// ─────────────────────────────────────────────────────────────────────────────
class _PredictionCard extends StatelessWidget {
  final double in7Days;
  final double slope;
  final ThemeData theme;

  const _PredictionCard({
    required this.in7Days,
    required this.slope,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = slope >= 0;
    final color = isPositive ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔮 Prediksi 7 Hari ke Depan',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Berdasarkan regresi linier dari data ${isPositive ? 7 : 7} hari terakhir',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPositive
                      ? 'Jika tren berlanjut, skor Anda akan ${slope > 0 ? 'naik' : 'stabil'}.'
                      : '⚠️ Tren menurun. Tingkatkan aktivitas, tidur, & kurangi stres.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                in7Days.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: 13,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isPositive ? '▲ Naik' : '▼ Turun',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Statistics Grid
// ─────────────────────────────────────────────────────────────────────────────
class _StatisticsGrid extends StatelessWidget {
  final List<HealthTrajectoryPoint> points;
  final ThemeData theme;

  const _StatisticsGrid({required this.points, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final avgSteps = points.isEmpty
        ? 0
        : points.map((p) => p.steps).reduce((a, b) => a + b) ~/ points.length;
    final avgSleep = points.isEmpty
        ? 0.0
        : points.map((p) => p.sleepHours).reduce((a, b) => a + b) /
            points.length;
    final avgComposite = points.isEmpty
        ? 0.0
        : points.map((p) => p.compositeScore).reduce((a, b) => a + b) /
            points.length;
    final daysActive = points.where((p) => p.steps >= 7500).length;

    final stats = [
      _StatItem(
          label: 'Rata-rata Langkah',
          value: '$avgSteps',
          unit: 'spm',
          icon: Icons.health_and_safety_rounded),
      _StatItem(
          label: 'Rata-rata Tidur',
          value: avgSleep.toStringAsFixed(1),
          unit: 'jam',
          icon: Icons.health_and_safety_rounded),
      _StatItem(
          label: 'Skor Komposit',
          value: avgComposite.toStringAsFixed(0),
          unit: '/100',
          icon: Icons.health_and_safety_rounded),
      _StatItem(
          label: 'Hari Aktif', value: '$daysActive', unit: 'hari', icon: Icons.health_and_safety_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Statistik 30 Hari',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          childAspectRatio: 1.7,
          physics: const NeverScrollableScrollPhysics(),
          children: stats.map((s) => _StatCard(item: s, theme: theme)).toList(),
        ),
      ],
    );
  }
}

class _StatItem {
  final String label, value, unit;
  final IconData icon;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.unit,
      required this.icon});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  final ThemeData theme;

  const _StatCard({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 2),
                child: Text(
                  item.unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Komponen Breakdown
// ─────────────────────────────────────────────────────────────────────────────
class _ComponentBreakdown extends StatelessWidget {
  final List<HealthTrajectoryPoint> points;
  final ThemeData theme;

  const _ComponentBreakdown({required this.points, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final avgStepScore = points
            .map((p) => (p.steps / 10000 * 100).clamp(0.0, 100.0))
            .reduce((a, b) => a + b) /
        points.length;
    final avgSleepScore = points
            .map((p) => p.sleepHours >= 7
                ? 100.0
                : (p.sleepHours / 7 * 100).clamp(0.0, 100.0))
            .reduce((a, b) => a + b) /
        points.length;
    final stressScore =
        points.where((p) => p.stressManaged).length / points.length * 100;

    // Hidrasi rata-rata
    final avgHydration = points.any((p) => p.waterTarget > 0)
        ? points
                .map((p) => p.waterTarget > 0
                    ? (p.waterGlasses / p.waterTarget * 100).clamp(0.0, 100.0)
                    : 50.0)
                .reduce((a, b) => a + b) /
            points.length
        : 50.0;

    // Aging score rata-rata
    final avgAging =
        points.map((p) => p.agingScore).reduce((a, b) => a + b) / points.length;

    final components = [
      _CompItem(
          label: 'Aktivitas Fisik',
          score: avgStepScore,
          desc: 'Target ≥10.000 langkah/hari (WHO 2020) — bobot 30%',
          color: AppColors.primary,
          icon: Icons.health_and_safety_rounded),
      _CompItem(
          label: 'Kualitas Tidur',
          score: avgSleepScore,
          desc:
              '≤6 jam tidur meningkatkan risiko DM 37% (Shan 2015) — bobot 15%',
          color: const Color(0xFF8B5CF6),
          icon: Icons.health_and_safety_rounded),
      _CompItem(
          label: 'Hidrasi (Air Minum)',
          score: avgHydration,
          desc:
              'Target 8 gelas/hari — EFSA Water Intake Guidelines — bobot 10%',
          color: const Color(0xFF29B6F6),
          icon: Icons.health_and_safety_rounded),
      _CompItem(
          label: 'Skor Gaya Hidup',
          score: avgAging,
          desc: 'CERDIK: Cek BMI, aktivitas, pola makan, tidur — bobot 15%',
          color: const Color(0xFF4CAF50),
          icon: Icons.health_and_safety_rounded),
      _CompItem(
          label: 'Manajemen Stres',
          score: stressScore,
          desc: 'Stres kronik +23% risiko jantung (Lancet 2012) — bobot 5%',
          color: const Color(0xFFF59E0B),
          icon: Icons.health_and_safety_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚖️ Komponen Kesehatan Komposit',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rata-rata 30 hari — berdasarkan bukti ilmiah',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 14),
          ...components.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CompBar(item: c, theme: theme),
              )),
        ],
      ),
    );
  }
}

class _CompItem {
  final String label, desc;
  final IconData icon;
  final double score;
  final Color color;
  const _CompItem({
    required this.label,
    required this.score,
    required this.desc,
    required this.color,
    required this.icon,
  });
}

class _CompBar extends StatelessWidget {
  final _CompItem item;
  final ThemeData theme;

  const _CompBar({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    final score = item.score.clamp(0.0, 100.0);
    final scoreLabel = score >= 80
        ? 'Baik'
        : score >= 60
            ? 'Cukup'
            : score >= 40
                ? 'Perlu Ditingkatkan'
                : 'Rendah';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(item.icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${score.toStringAsFixed(0)}  $scoreLabel',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: item.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 9,
            backgroundColor: item.color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation(item.color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.desc,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Insufficient Data
// ─────────────────────────────────────────────────────────────────────────────
class _InsufficientDataCard extends StatelessWidget {
  final int daysRecorded;
  final ThemeData theme;

  const _InsufficientDataCard(
      {required this.daysRecorded, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Text('📅', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data terbatas ($daysRecorded dari 7 hari minimum). '
              'Gunakan aplikasi setiap hari untuk mengaktifkan analisis prediksi tren dan regresi linier.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}