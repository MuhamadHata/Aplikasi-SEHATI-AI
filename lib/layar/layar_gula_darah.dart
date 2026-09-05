// ============================================================
// LAYAR: PEMANTAUAN KADAR GULA DARAH & GLYCEMIC ADVISOR
// SEHATI-AI Health Ecosystem
// Standar Medis: PERKENI 2021, ADA 2024, WHO
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../inti/tema/design_tokens.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../inti/tema/ikon_mapper.dart';
import '../penyedia/penyedia_aktivitas.dart';
import '../penyedia/penyedia_gula_darah.dart';
import '../inti/model/catatan_gula_darah.dart';
import '../widget/nubi_mascot.dart';
import '../komponen/kutipan_sumber.dart';
import 'layar_referensi.dart';

class BloodGlucoseScreen extends StatefulWidget {
  const BloodGlucoseScreen({super.key});

  @override
  State<BloodGlucoseScreen> createState() => _BloodGlucoseScreenState();
}

class _BloodGlucoseScreenState extends State<BloodGlucoseScreen> {
  int _rentangHari = 7; // 7 atau 30 hari
  KondisiPengukuran? _filterKondisi; // null = semua
  bool _tampilkanEdukasiFaktor = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ext = theme.extension<AppThemeExtension>();
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Kadar Gula Darah',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Referensi Medis',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReferencesScreen(
                    title: 'Referensi: Glukosa & Metabolisme',
                    tags: ['diabetes', 'sugar', 'activity', 'sleep'],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Catat Angka',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        onPressed: () => _bukaModalInputAngka(context),
      ),
      body: Consumer<BloodGlucoseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final latest = provider.catatanTerbaru;
          final logs = provider.filterByKondisi(_filterKondisi);

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger reload / re-fetch
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                // ── 1. Hero Card: Status Pengukuran Terakhir ────────────────
                if (latest != null)
                  _buildHeroCard(context, latest, isDark, primary)
                else
                  _buildEmptyHeroCard(context, isDark, primary),

                const SizedBox(height: 16),

                // ── 2. Quick Metrics Row (3-in-1 Summary) ────────────────────
                _buildQuickMetricsRow(context, provider, isDark, ext),

                const SizedBox(height: 20),

                // ── 3. Grafik Fluktuasi Glukosa Interaktif (fl_chart) ────────
                _buildChartCard(context, provider, isDark, primary),

                const SizedBox(height: 20),

                // ── 4. Panel Edukasi Faktor yang Memengaruhi Gula Darah ──────
                _buildEducationSection(context, isDark, primary),

                const SizedBox(height: 20),

                // ── 5. Seksi Nubi AI Advisor ────────────────────────────────
                _buildAiAdvisorCard(context, provider, isDark, primary),

                const SizedBox(height: 24),

                // ── 6. Header Riwayat & Filter Kondisi ───────────────────────
                _buildHistoryHeader(context, provider, isDark, primary),

                const SizedBox(height: 12),

                // ── 7. Daftar Riwayat Log ────────────────────────────────────
                if (logs.isEmpty)
                  _buildEmptyHistory(isDark)
                else
                  ...logs.map((item) => _buildHistoryItemCard(
                        context,
                        item,
                        provider,
                        isDark,
                      )),

                const SizedBox(height: 16),

                // ── 8. Kutipan Standar Medis ─────────────────────────────────
                const Center(
                  child: CitationWidget(
                    sources: [
                      'PERKENI Pedoman DM Tipe 2, 2021',
                      'ADA Standards of Care, 2024',
                      'WHO Diabetes Guideline, 2023',
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── 1. Hero Card Status Terkini ──────────────────────────────────────────

  Widget _buildHeroCard(
    BuildContext context,
    CatatanGulaDarah latest,
    bool isDark,
    Color primary,
  ) {
    final statusColor = latest.status.warna;
    final statusBg = latest.status.warnaBg;
    final timeStr =
        DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(latest.waktu);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row atas: Status Badge & Waktu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? statusColor.withValues(alpha: 0.2) : statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(latest.status.icon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      latest.status.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${latest.kondisi.iconEmoji} ${latest.kondisi.label}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Nilai Besar
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                latest.nilai.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'mg/dL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              // Icon status lingkaran
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    latest.kondisi.iconEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Saran Singkat Sesuai Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  latest.saranSingkat,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHeroCard(BuildContext context, bool isDark, Color primary) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.bloodtype_outlined, size: 44, color: AppColors.accent),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Catatan Gula Darah',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mulai catat angka hasil tes gula darah puasa atau setelah makan untuk melihat analisis & grafik tren.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Input Angka Sekarang',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () => _bukaModalInputAngka(context),
          ),
        ],
      ),
    );
  }

  // ─── 2. Quick Metrics Row (3-in-1 Summary) ────────────────────────────────

  Widget _buildQuickMetricsRow(
    BuildContext context,
    BloodGlucoseProvider provider,
    bool isDark,
    AppThemeExtension? ext,
  ) {
    return Row(
      children: [
        // Rata-rata 7 Hari
        Expanded(
          child: _MetricTile(
            label: 'Rata-rata',
            value: provider.rataRataTotal > 0
                ? provider.rataRataTotal.toStringAsFixed(0)
                : '-',
            unit: 'mg/dL',
            icon: Icons.show_chart_rounded,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        // Time in Range (TIR)
        Expanded(
          child: _MetricTile(
            label: 'Time in Range',
            value: '${provider.persentaseTimeInRange}%',
            unit: '70-140 mg/dL',
            icon: Icons.track_changes_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        // Min - Max
        Expanded(
          child: _MetricTile(
            label: 'Rentang Min-Max',
            value: provider.nilaiTertinggi > 0
                ? '${provider.nilaiTerendah.toStringAsFixed(0)}-${provider.nilaiTertinggi.toStringAsFixed(0)}'
                : '-',
            unit: 'mg/dL',
            icon: Icons.swap_vert_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ─── 3. Grafik Fluktuasi Glukosa Interaktif (fl_chart) ────────────────────

  Widget _buildChartCard(
    BuildContext context,
    BloodGlucoseProvider provider,
    bool isDark,
    Color primary,
  ) {
    final listData = _rentangHari == 7
        ? provider.catatan7HariTerakhir
        : provider.catatan30HariTerakhir;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Grafik + Filter Periode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tren Fluktuasi Gula Darah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Zona Hijau: Target Normal (70 - 140 mg/dL)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Segmented Button 7 Hari / 30 Hari
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _PeriodFilterButton(
                      label: '7 Hari',
                      isActive: _rentangHari == 7,
                      isDark: isDark,
                      primary: primary,
                      onTap: () => setState(() => _rentangHari = 7),
                    ),
                    _PeriodFilterButton(
                      label: '30 Hari',
                      isActive: _rentangHari == 30,
                      isDark: isDark,
                      primary: primary,
                      onTap: () => setState(() => _rentangHari = 30),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Render Grafik LineChart
          SizedBox(
            height: 200,
            child: listData.isEmpty
                ? Center(
                    child: Text(
                      'Belum cukup data untuk rentang waktu ini',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : _buildLineChart(listData, isDark, primary),
          ),

          const SizedBox(height: 14),

          // Legend Status
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(
                  color: const Color(0xFF10B981), label: 'Normal (<140)'),
              _LegendItem(
                  color: const Color(0xFFF59E0B), label: 'Waspada (140-199)'),
              _LegendItem(
                  color: const Color(0xFFEF4444), label: 'Tinggi (≥200)'),
              _LegendItem(
                  color: const Color(0xFF0284C7), label: 'Rendah (<70)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<CatatanGulaDarah> dataList,
    bool isDark,
    Color primary,
  ) {
    final spots = <FlSpot>[];
    for (int i = 0; i < dataList.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataList[i].nilai));
    }

    double minY = 50;
    double maxY = 250;
    for (final it in dataList) {
      if (it.nilai < minY) minY = (it.nilai - 10).clamp(30, 200);
      if (it.nilai > maxY) maxY = (it.nilai + 20);
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: (dataList.length - 1).toDouble().clamp(1.0, 100.0),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 40,
          getDrawingHorizontalLine: (val) {
            // Garis batas target normal 70 dan 140
            if (val == 70 || val == 140) {
              return FlLine(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                strokeWidth: 1.5,
                dashArray: [5, 4],
              );
            }
            return FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (dataList.length / 4).clamp(1.0, 10.0),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= dataList.length) return const SizedBox();
                final dt = dataList[idx].waktu;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('d/M').format(dt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF334155) : const Color(0xFF0F172A),
            tooltipBorder: BorderSide(
              color: primary.withValues(alpha: 0.3),
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                if (idx < 0 || idx >= dataList.length) return null;
                final item = dataList[idx];
                final dateStr =
                    DateFormat('d MMM HH:mm', 'id_ID').format(item.waktu);
                return LineTooltipItem(
                  '${item.kondisi.shortLabel}: ${spot.y.toStringAsFixed(0)} mg/dL\n',
                  TextStyle(
                    color: item.status.warna,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: '$dateStr • ${item.status.label}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final item = dataList[index];
                return FlDotCirclePainter(
                  radius: 4.5,
                  color: item.status.warna,
                  strokeWidth: 2,
                  strokeColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.25),
                  primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. Panel Edukasi: Faktor yang Memengaruhi Gula Darah ─────────────────

  Widget _buildEducationSection(
    BuildContext context,
    bool isDark,
    Color primary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _tampilkanEdukasiFaktor,
          onExpansionChanged: (v) =>
              setState(() => _tampilkanEdukasiFaktor = v),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.biotech_outlined, size: 20, color: primary),
          ),
          title: Text(
            'Faktor yang Memengaruhi Gula Darah',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            'Pelajari pengaruh makanan, olahraga, tidur & stres',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: FaktorPengaruhItem.daftarPilihan.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(IkonMapper.dariEmoji(item.emoji), size: 22, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.isPenaik
                                          ? const Color(0xFFEF4444)
                                              .withValues(alpha: 0.1)
                                          : const Color(0xFF10B981)
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.isPenaik
                                          ? 'Menaikkan Glukosa'
                                          : 'Menurunkan/Stabil',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: item.isPenaik
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.deskripsi,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 5. Seksi Nubi AI Glycemic Advisor ────────────────────────────────────

  Widget _buildAiAdvisorCard(
    BuildContext context,
    BloodGlucoseProvider provider,
    bool isDark,
    Color primary,
  ) {
    final ap = context.read<ActivityProvider>();
    final userName = ap.userName;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF0FDF4), const Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: NubiMascot(
                  pose:
                      provider.isAiAnalyzing ? NubiPose.study : NubiPose.doctor,
                  size: 54,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nubi AI Glycemic Advisor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Analisis korelasi angka glukosa & gaya hidup',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tombol Trigger Analisis
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: provider.isAiAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                provider.isAiAnalyzing
                    ? 'Nubi sedang menganalisis...'
                    : 'Analisis Pola Glukosa AI',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              onPressed: provider.isAiAnalyzing
                  ? null
                  : () async {
                      final res =
                          await provider.generateAiAnalysis(userName: userName);
                      if (context.mounted && res.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Analisis Nubi AI berhasil diperbarui!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
            ),
          ),

          // Output Hasil AI jika sudah ada
          if (provider.aiInsight != null && provider.aiInsight!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded,
                          size: 18, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Text(
                        'Hasil Analisis & Rekomendasi Nubi',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    provider.aiInsight!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 6. Header Riwayat & Filter ───────────────────────────────────────────

  Widget _buildHistoryHeader(
    BuildContext context,
    BloodGlucoseProvider provider,
    bool isDark,
    Color primary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Pencatatan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              '${provider.daftarCatatan.length} Catatan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Filter Chips Baris Horizontal
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChipItem(
                label: 'Semua',
                isSelected: _filterKondisi == null,
                onTap: () => setState(() => _filterKondisi = null),
                isDark: isDark,
                primary: primary,
              ),
              const SizedBox(width: 8),
              _FilterChipItem(
                label: '🌅 Puasa (GDP)',
                isSelected: _filterKondisi == KondisiPengukuran.puasa,
                onTap: () =>
                    setState(() => _filterKondisi = KondisiPengukuran.puasa),
                isDark: isDark,
                primary: primary,
              ),
              const SizedBox(width: 8),
              _FilterChipItem(
                label: '🍱 Setelah Makan (GD2PP)',
                isSelected: _filterKondisi == KondisiPengukuran.setelahMakan,
                onTap: () => setState(
                    () => _filterKondisi = KondisiPengukuran.setelahMakan),
                isDark: isDark,
                primary: primary,
              ),
              const SizedBox(width: 8),
              _FilterChipItem(
                label: 'Sebelum Makan',
                isSelected: _filterKondisi == KondisiPengukuran.sebelumMakan,
                onTap: () => setState(
                    () => _filterKondisi = KondisiPengukuran.sebelumMakan),
                isDark: isDark,
                primary: primary,
              ),
              const SizedBox(width: 8),
              _FilterChipItem(
                label: '🌙 Sebelum Tidur',
                isSelected: _filterKondisi == KondisiPengukuran.sebelumTidur,
                onTap: () => setState(
                    () => _filterKondisi = KondisiPengukuran.sebelumTidur),
                isDark: isDark,
                primary: primary,
              ),
              const SizedBox(width: 8),
              _FilterChipItem(
                label: 'Sewaktu (GDS)',
                isSelected: _filterKondisi == KondisiPengukuran.sewaktu,
                onTap: () =>
                    setState(() => _filterKondisi = KondisiPengukuran.sewaktu),
                isDark: isDark,
                primary: primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 7. Card Riwayat Log Item ─────────────────────────────────────────────

  Widget _buildHistoryItemCard(
    BuildContext context,
    CatatanGulaDarah item,
    BloodGlucoseProvider provider,
    bool isDark,
  ) {
    final statusColor = item.status.warna;
    final timeStr = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(item.waktu);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lingkaran Status Warna
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 8),
              // Kondisi
              Text(
                '${item.kondisi.iconEmoji} ${item.kondisi.label}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Opsi menu (hapus)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                onSelected: (val) {
                  if (val == 'hapus') {
                    _konfirmasiHapus(context, item, provider);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'hapus',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Hapus Catatan',
                            style: TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Nilai & Waktu
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                item.nilai.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'mg/dL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          // Faktor-faktor yang dialami
          if (item.faktorPengaruh.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.faktorPengaruh.map((key) {
                final f = FaktorPengaruhItem.cariByKey(key);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${f?.emoji ?? "📌"} ${f?.label ?? key}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Catatan pengguna jika ada
          if (item.catatan != null && item.catatan!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan: "${item.catatan}"',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_rounded,
                size: 44,
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            Text(
              'Tidak ada catatan untuk filter ini',
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MODAL INPUT ANGKA LENGKAP ────────────────────────────────────────────

  void _bukaModalInputAngka(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => _ModalInputAngkaSheet(),
    );
  }

  void _konfirmasiHapus(
    BuildContext context,
    CatatanGulaDarah item,
    BloodGlucoseProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan ${item.kondisi.label} (${item.nilai.toStringAsFixed(0)} mg/dL)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.hapusCatatan(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET SHEET: INPUT ANGKA
// ─────────────────────────────────────────────────────────────────────────────

class _ModalInputAngkaSheet extends StatefulWidget {
  @override
  State<_ModalInputAngkaSheet> createState() => _ModalInputAngkaSheetState();
}

class _ModalInputAngkaSheetState extends State<_ModalInputAngkaSheet> {
  final TextEditingController _nilaiCtrl = TextEditingController(text: '100');
  final TextEditingController _catatanCtrl = TextEditingController();

  KondisiPengukuran _kondisi = KondisiPengukuran.puasa;
  final Set<String> _faktorTerpilih = {};
  final DateTime _waktu = DateTime.now();

  @override
  void dispose() {
    _nilaiCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  double get _currentNilai => double.tryParse(_nilaiCtrl.text) ?? 100.0;

  void _tambahNilai(double delta) {
    final current = _currentNilai;
    final baru = (current + delta).clamp(30.0, 500.0);
    _nilaiCtrl.text = baru.toStringAsFixed(0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final currentStatus =
        CatatanGulaDarah.evaluasiStatus(_currentNilai, _kondisi);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Judul Modal
            Row(
              children: [
                const Icon(Icons.bloodtype_outlined, size: 22, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Catat Kadar Gula Darah',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 1. Pilih Kondisi Pengukuran ────────────────────────────────
            Text(
              'Kondisi Saat Pengukuran:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: KondisiPengukuran.values.map((k) {
                  final isSelected = _kondisi == k;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${k.iconEmoji} ${k.label}'),
                      selected: isSelected,
                      selectedColor: primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? Colors.white70
                                : const Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _kondisi = k);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. Input Angka & Stepper Cepat ─────────────────────────────
            Text(
              'Hasil Pengukuran (mg/dL):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentStatus.warna.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Tombol Kurang
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: primary.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: () => _tambahNilai(-5),
                  ),
                  const SizedBox(width: 8),
                  // Kolom Input Angka
                  Expanded(
                    child: TextField(
                      controller: _nilaiCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        suffixText: 'mg/dL',
                        suffixStyle: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Tambah
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: primary.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _tambahNilai(5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Quick Preset Chips (90, 110, 130, 160)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [90, 110, 130, 160, 200].map((preset) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text('$preset'),
                    labelStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700),
                    onPressed: () {
                      _nilaiCtrl.text = preset.toString();
                      setState(() {});
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Status Real-Time Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: currentStatus.warna.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: currentStatus.warna.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(currentStatus.icon,
                      color: currentStatus.warna, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: ${currentStatus.label}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: currentStatus.warna,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 3. Faktor Pengaruh Yang Dialami ────────────────────────────
            Text(
              'Faktor yang Sedang Memengaruhi (Opsional):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: FaktorPengaruhItem.daftarPilihan.map((item) {
                final isSelected = _faktorTerpilih.contains(item.key);
                return FilterChip(
                  label: Text('${item.emoji} ${item.label}'),
                  selected: isSelected,
                  selectedColor: primary.withValues(alpha: 0.2),
                  checkmarkColor: primary,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : primary)
                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                  ),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _faktorTerpilih.add(item.key);
                      } else {
                        _faktorTerpilih.remove(item.key);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── 4. Catatan Tambahan ────────────────────────────────────────
            TextField(
              controller: _catatanCtrl,
              decoration: InputDecoration(
                labelText: 'Catatan tambahan (misal: habis makan soto)',
                labelStyle: const TextStyle(fontSize: 12.5),
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── 5. Tombol Simpan ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final val = _currentNilai;
                  if (val <= 0) return;

                  final provider = context.read<BloodGlucoseProvider>();
                  await provider.tambahCatatan(
                    nilai: val,
                    kondisi: _kondisi,
                    faktorPengaruh: _faktorTerpilih.toList(),
                    waktu: _waktu,
                    catatan: _catatanCtrl.text,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Catatan ${_kondisi.label} (${val.toStringAsFixed(0)} mg/dL) berhasil disimpan!',
                        ),
                        backgroundColor: currentStatus.warna,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Simpan Catatan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widget: Metric Tile ─────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widget: Filter Period Button ────────────────────────────────────

class _PeriodFilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const _PeriodFilterButton({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              isActive ? (isDark ? primary : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : primary)
                : (isDark ? Colors.white54 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}

// ─── Helper Widget: Legend Item ─────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─── Helper Widget: Filter Chip Item ────────────────────────────────────────

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color primary;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primary
                : isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isDark
                    ? Colors.white70
                    : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
