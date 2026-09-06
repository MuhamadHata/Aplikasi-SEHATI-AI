import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../penyedia/penyedia_aktivitas.dart';
import '../../inti/model/catatan_aktivitas.dart';

class MonthlyHealthScreen extends StatelessWidget {
  const MonthlyHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final summaries = provider.monthlySummaries;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Calculate averages
    final avgCalIn = summaries.isEmpty
        ? 0
        : summaries.map((s) => s.caloriesConsumed).reduce((a, b) => a + b) ~/
            summaries.length;
    final avgCalBurned = summaries.isEmpty
        ? 0
        : summaries.map((s) => s.caloriesBurned).reduce((a, b) => a + b) ~/
            summaries.length;
    final avgWater = summaries.isEmpty
        ? 0.0
        : summaries.map((s) => s.waterGlasses).reduce((a, b) => a + b) /
            summaries.length;
    final avgSteps = summaries.isEmpty
        ? 0
        : summaries.map((s) => s.steps).reduce((a, b) => a + b) ~/
            summaries.length;

    // Health score (0-100)
    final waterScore = (avgWater / 8).clamp(0.0, 1.0);
    final stepsScore = (avgSteps / 10000).clamp(0.0, 1.0);
    final calScore =
        avgCalBurned > 0 ? (avgCalBurned / 300).clamp(0.0, 1.0) : 0.0;
    final healthScore =
        ((waterScore + stepsScore + calScore) / 3 * 100).round();

    String healthLabel;
    String healthIcon;
    Color healthColor;
    if (healthScore >= 75) {
      healthLabel = 'Kesehatan Sangat Baik';
      healthIcon = '💪';
      healthColor = const Color(0xFF10B981);
    } else if (healthScore >= 50) {
      healthLabel = 'Kesehatan Cukup Baik';
      healthIcon = '👍';
      healthColor = const Color(0xFFF59E0B);
    } else if (healthScore >= 25) {
      healthLabel = 'Perlu Ditingkatkan';
      healthIcon = '⚠️';
      healthColor = const Color(0xFFF97316);
    } else {
      healthLabel = 'Kurang Aktif';
      healthIcon = '😔';
      healthColor = const Color(0xFFEF4444);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).textTheme.titleLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laporan Bulanan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: summaries.isEmpty
          ? _EmptyState()
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Health Score Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              healthColor.withValues(alpha: 0.15),
                              healthColor.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: healthColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(healthIcon,
                                style: const TextStyle(fontSize: 48)),
                            const SizedBox(height: 8),
                            Text(
                              '$healthScore / 100',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: healthColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              healthLabel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: healthColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: healthScore / 100,
                                backgroundColor:
                                    healthColor.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation(healthColor),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Average Stats
                      const _SectionTitle('Rata-rata Harian'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _AvgCard(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Kalori\nMasuk',
                            value: '$avgCalIn kkal',
                            color: const Color(0xFFF97316),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 10),
                          _AvgCard(
                            icon: Icons.health_and_safety_rounded,
                            label: 'Kalori\nTerbakar',
                            value: '$avgCalBurned kkal',
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _AvgCard(
                            icon: Icons.water_drop_rounded,
                            label: 'Air\nMinum',
                            value: '${avgWater.toStringAsFixed(1)} gls',
                            color: const Color(0xFF3B82F6),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 10),
                          _AvgCard(
                            icon: Icons.directions_walk_rounded,
                            label: 'Langkah\nKaki',
                            value: NumberFormat('#,###').format(avgSteps),
                            color: primaryColor,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Calorie Bar Chart
                      const _SectionTitle('Kalori Masuk (30 Hari)'),
                      const SizedBox(height: 12),
                      _BarChartCard(
                        summaries: summaries,
                        valueSelector: (s) => s.caloriesConsumed.toDouble(),
                        barColor: const Color(0xFFF97316),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // Steps Line Chart
                      const _SectionTitle('Langkah Kaki (30 Hari)'),
                      const SizedBox(height: 12),
                      _LineChartCard(
                        summaries: summaries,
                        lineColor: primaryColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // Water Bar Chart
                      const _SectionTitle('Air Minum (30 Hari)'),
                      const SizedBox(height: 12),
                      _BarChartCard(
                        summaries: summaries,
                        valueSelector: (s) => s.waterGlasses.toDouble(),
                        barColor: const Color(0xFF3B82F6),
                        isDark: isDark,
                        maxY: 10,
                      ),
                      const SizedBox(height: 20),

                      // Achievement breakdown
                      const _SectionTitle('Detail Pencapaian Target'),
                      const SizedBox(height: 12),
                      _AchievRow(
                        icon: Icons.water_drop_rounded,
                        label: 'Target Air Minum',
                        currentText: '${avgWater.toStringAsFixed(1)} / 8 gls/hari',
                        percent: waterScore,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 10),
                      _AchievRow(
                        icon: Icons.directions_walk_rounded,
                        label: 'Target Langkah Kaki',
                        currentText: '${NumberFormat('#,###').format(avgSteps)} / 10.000/hari',
                        percent: stepsScore,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 10),
                      _AchievRow(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Target Kalori Terbakar',
                        currentText: '$avgCalBurned / 300 kkal/hari',
                        percent: calScore,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belum ada data bulanan',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lakukan aktivitas selama beberapa hari\nuntuk melihat laporan bulanan Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontFamily: 'Poppins',
        ),
      );
}

class _AvgCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _AvgCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  Icon(
                    Icons.trending_up_rounded,
                    size: 18,
                    color: color.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'Poppins',
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label.replaceAll('\n', ' '),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
}

class _BarChartCard extends StatelessWidget {
  final List<DailySummary> summaries;
  final double Function(DailySummary) valueSelector;
  final Color barColor;
  final bool isDark;
  final double? maxY;

  const _BarChartCard({
    required this.summaries,
    required this.valueSelector,
    required this.barColor,
    required this.isDark,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final data = summaries.reversed.toList();
    // Ensure we have at least some data or padding
    final values = data.map(valueSelector).toList();
    final maxVal =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY ?? (maxVal == 0 ? 10.0 : maxVal * 1.2);

    return Container(
      height: 200, // Increased height for better clarity
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
      ),
      child: BarChart(
        BarChartData(
          maxY: chartMaxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF334155) : Colors.white,
              tooltipBorder: BorderSide(color: barColor.withValues(alpha: 0.3)),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[groupIndex].date.substring(8)} \n',
                  TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: rod.toY.toStringAsFixed(0),
                      style: TextStyle(
                          color: barColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (val, meta) {
                  if (val == meta.max || val == 0) {
                    return const SizedBox.shrink();
                  }
                  String text;
                  if (val >= 1000) {
                    text = '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}k';
                  } else {
                    text = val.toInt().toString();
                  }
                  return Text(
                    text,
                    style: TextStyle(
                        fontSize: 10, color: Theme.of(context).hintColor),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < data.length) {
                    final step = (data.length / 5).ceil().clamp(1, 10);
                    final isFirst = idx == 0;
                    final isLast = idx == data.length - 1;
                    final isStep = idx % step == 0;
                    final tooCloseToLast = (data.length - 1 - idx) < (step * 0.7);

                    if (isFirst || (isStep && !tooCloseToLast) || isLast) {
                      final rawDate = data[idx].date;
                      final dateStr = rawDate.length >= 10
                          ? rawDate.substring(8)
                          : '${idx + 1}';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMaxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: valueSelector(data[i]),
                  color: barColor,
                  width: data.length > 20 ? 6 : 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: chartMaxY,
                    color: barColor.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  final List<DailySummary> summaries;
  final Color lineColor;
  final bool isDark;

  const _LineChartCard(
      {required this.summaries, required this.lineColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = summaries.reversed.toList();
    final values = data.map((s) => s.steps.toDouble()).toList();
    final maxSteps =
        values.isEmpty ? 10000.0 : values.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxSteps == 0 ? 10000.0 : maxSteps * 1.2;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
      ),
      child: LineChart(
        LineChartData(
          maxY: chartMaxY,
          minY: 0,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF334155) : Colors.white,
              getTooltipItems: (items) {
                return items.map((item) {
                  return LineTooltipItem(
                    '${NumberFormat('#,###').format(item.y)} langkah',
                    TextStyle(color: lineColor, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMaxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (val, meta) {
                  if (val == meta.max || val == 0) {
                    return const SizedBox.shrink();
                  }
                  if (val >= 1000) {
                    return Text('${(val / 1000).toStringAsFixed(1)}k',
                        style: TextStyle(
                            fontSize: 10, color: Theme.of(context).hintColor));
                  }
                  return Text(val.toInt().toString(),
                      style: TextStyle(
                          fontSize: 10, color: Theme.of(context).hintColor));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < data.length) {
                    final step = (data.length / 5).ceil().clamp(1, 10);
                    final isFirst = idx == 0;
                    final isLast = idx == data.length - 1;
                    final isStep = idx % step == 0;
                    final tooCloseToLast = (data.length - 1 - idx) < (step * 0.7);

                    if (isFirst || (isStep && !tooCloseToLast) || isLast) {
                      final rawDate = data[idx].date;
                      final dateStr = rawDate.length >= 10
                          ? rawDate.substring(8)
                          : '${idx + 1}';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(data.length, (i) {
                return FlSpot(i.toDouble(), data[i].steps.toDouble());
              }),
              isCurved: true,
              curveSmoothness: 0.35,
              color: lineColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: lineColor,
                ),
                checkToShowDot: (spot, barData) =>
                    spot.x % 5 == 0 || spot.x == barData.spots.length - 1,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: 0.3),
                    lineColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String currentText;
  final double percent;
  final Color color;

  const _AchievRow({
    required this.icon,
    required this.label,
    required this.currentText,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int pct = (percent * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.titleSmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
