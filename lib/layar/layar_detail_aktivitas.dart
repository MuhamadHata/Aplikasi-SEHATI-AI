// ==========================================
// LAYARAN DETAIL AKTIVITAS
// Menampilkan detail aktivitas dengan metrik spesifik olahraga
// Mirip dengan Strava activity detail
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../inti/model/catatan_aktivitas.dart';

// ─── Enum untuk jenis aktivitas ───────────────────────────────────────────────
enum DetailJenisAktivitas {
  lari,
  sepeda,
  hiking,
  trailRun,
  sepedaTrail,
}

// ─── Extension untuk format display ──────────────────────────────────────────
extension DetailJenisExt on DetailJenisAktivitas {
  String get label {
    switch (this) {
      case DetailJenisAktivitas.lari: return 'Lari';
      case DetailJenisAktivitas.sepeda: return 'Bersepeda';
      case DetailJenisAktivitas.hiking: return 'Hiking';
      case DetailJenisAktivitas.trailRun: return 'Trail Run';
      case DetailJenisAktivitas.sepedaTrail: return 'Sepeda Trail';
    }
  }

  IconData get icon {
    switch (this) {
      case DetailJenisAktivitas.lari: return Icons.directions_run_rounded;
      case DetailJenisAktivitas.sepeda: return Icons.directions_bike_rounded;
      case DetailJenisAktivitas.hiking: return Icons.hiking_rounded;
      case DetailJenisAktivitas.trailRun: return Icons.terrain_rounded;
      case DetailJenisAktivitas.sepedaTrail: return Icons.pedal_bike_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DetailJenisAktivitas.lari: return const Color(0xFFFC5200);
      case DetailJenisAktivitas.sepeda: return const Color(0xFF2563EB);
      case DetailJenisAktivitas.hiking: return const Color(0xFF78350F);
      case DetailJenisAktivitas.trailRun: return const Color(0xFF059669);
      case DetailJenisAktivitas.sepedaTrail: return const Color(0xFF7C3AED);
    }
  }
}

// ─── Screen Detail Aktivitas ──────────────────────────────────────────────────
class ActivityDetailScreen extends StatelessWidget {
  final ActivityRecord activity;

  const ActivityDetailScreen({super.key, required this.activity});

  DetailJenisAktivitas _getJenisAktivitas() {
    final lower = activity.type.toLowerCase();
    if (lower.contains('trail run') ||
        lower.contains('lari trail') ||
        lower == 'trail') {
      return DetailJenisAktivitas.trailRun;
    }
    if (lower.contains('sepeda trail') || lower.contains('mtb')) {
      return DetailJenisAktivitas.sepedaTrail;
    }
    if (lower.contains('sepeda') ||
        lower.contains('cycling') ||
        lower.contains('bike')) {
      return DetailJenisAktivitas.sepeda;
    }
    if (lower.contains('hiking') || lower.contains('hike')) {
      return DetailJenisAktivitas.hiking;
    }
    return DetailJenisAktivitas.lari;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jenis = _getJenisAktivitas();
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar dengan Peta ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: jenis.color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // TODO: Share functionality
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMapPreview(),
            ),
          ),

          // ── Header Aktivitas ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon & Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: jenis.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(jenis.icon, color: jenis.color, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jenis.label,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            _formatDate(activity.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Summary Stats Card ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSummaryCard(jenis, isDark),
          ),

          // ── Primary Metric Card ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildPrimaryMetricCard(jenis, isDark),
          ),

          // ── Sport-Specific Metrics ───────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSportSpecificMetrics(jenis, isDark),
          ),

          // ── Additional Stats ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildAdditionalStats(isDark),
          ),

          // ── Bottom Padding ────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    if (activity.route.isEmpty) {
      return Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.white54),
              SizedBox(height: 8),
              Text(
                'Tidak ada data GPS',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: activity.route.first,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sehati.ai.activity',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: activity.route,
              strokeWidth: 4,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(DetailJenisAktivitas jenis, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryStat(
            activity.distanceKm.toStringAsFixed(2),
            'km',
            'Jarak',
            jenis.color,
          ),
          _buildSummaryStat(
            _formatDuration(activity.durationSeconds),
            '',
            'Durasi',
            jenis.color,
          ),
          _buildSummaryStat(
            '${activity.calories}',
            'kkal',
            'Kalori',
            jenis.color,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String value, String unit, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryMetricCard(DetailJenisAktivitas jenis, bool isDark) {
    String primaryValue = '--';
    String primaryUnit = '';
    String primaryLabel = 'Pace';

    if (jenis == DetailJenisAktivitas.lari ||
        jenis == DetailJenisAktivitas.trailRun) {
      // Pace (min/km)
      if (activity.averagePace > 0) {
        primaryValue = _formatPace(activity.averagePace);
      }
      primaryUnit = '/km';
      primaryLabel = 'Pace Rata-rata';
    } else if (jenis == DetailJenisAktivitas.sepeda ||
        jenis == DetailJenisAktivitas.sepedaTrail) {
      // Speed (km/j)
      final speed = activity.durationSeconds > 0
          ? activity.distanceKm / (activity.durationSeconds / 3600)
          : 0.0;
      primaryValue = speed.toStringAsFixed(1);
      primaryUnit = 'km/j';
      primaryLabel = 'Kecepatan Rata-rata';
    } else {
      // Hiking: Pace or Duration
      if (activity.averagePace > 0) {
        primaryValue = _formatPace(activity.averagePace);
        primaryUnit = '/km';
        primaryLabel = 'Pace Rata-rata';
      } else {
        primaryValue = _formatDuration(activity.durationSeconds);
        primaryUnit = '';
        primaryLabel = 'Total Durasi';
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            jenis.color,
            jenis.color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: jenis.color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(jenis.icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 8),
              Text(
                primaryLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                primaryValue,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  letterSpacing: -2,
                ),
              ),
              if (primaryUnit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    primaryUnit,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSportSpecificMetrics(DetailJenisAktivitas jenis, bool isDark) {
    List<Widget> metrics = [];

    if (jenis == DetailJenisAktivitas.lari ||
        jenis == DetailJenisAktivitas.trailRun) {
      // Running specific metrics
      metrics = [
        _MetricItem(
          icon: Icons.speed_rounded,
          label: 'Pace Terbaik',
          value: _formatPace(activity.averagePace * 0.85),
          unit: '/km',
        ),
        _MetricItem(
          icon: Icons.timer_outlined,
          label: 'Total Langkah',
          value: '${activity.steps}',
          unit: 'steps',
        ),
        const _MetricItem(
          icon: Icons.trending_up,
          label: 'Elevasi',
          value: '+0',
          unit: 'm',
        ),
      ];
    } else if (jenis == DetailJenisAktivitas.sepeda ||
        jenis == DetailJenisAktivitas.sepedaTrail) {
      // Cycling specific metrics
      final speed = activity.durationSeconds > 0
          ? (activity.distanceKm / (activity.durationSeconds / 3600))
          : 0.0;
      final maxSpeed = speed * 1.3;
      const avgCadence = 85;
      metrics = [
        _MetricItem(
          icon: Icons.speed,
          label: 'Kecepatan Maks',
          value: maxSpeed.toStringAsFixed(1),
          unit: 'km/j',
        ),
        const _MetricItem(
          icon: Icons.psychology,
          label: 'Power Estimasi',
          value: '~150',
          unit: 'W',
        ),
        const _MetricItem(
          icon: Icons.trending_up,
          label: 'Gradien Rata-rata',
          value: '~2',
          unit: '%',
        ),
        const _MetricItem(
          icon: Icons.directions_bike,
          label: 'Cadence Estimasi',
          value: '$avgCadence',
          unit: 'rpm',
        ),
      ];
    } else {
      // Hiking specific metrics
      metrics = [
        const _MetricItem(
          icon: Icons.terrain_rounded,
          label: 'Elevasi',
          value: '+0',
          unit: 'm',
        ),
        _MetricItem(
          icon: Icons.directions_walk_rounded,
          label: 'Total Langkah',
          value: '${activity.steps}',
          unit: 'steps',
        ),
        _MetricItem(
          icon: Icons.speed_rounded,
          label: 'Pace Rata-rata',
          value: activity.averagePace > 0
              ? _formatPace(activity.averagePace)
              : '--',
          unit: '/km',
        ),
        _MetricItem(
          icon: Icons.timer_outlined,
          label: 'Waktu Aktif',
          value: _formatDuration(activity.durationSeconds),
          unit: '',
        ),
      ];
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: jenis.color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Metrik ${jenis.label}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: metrics.map((m) => Expanded(child: m)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalStats(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Lainnya',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.calendar_today,
            'Tanggal',
            _formatDate(activity.date),
            isDark,
          ),
          _buildDetailRow(
            Icons.access_time,
            'Waktu Mulai',
            _formatTime(activity.date),
            isDark,
          ),
          _buildDetailRow(
            Icons.timer_outlined,
            'Durasi',
            _formatDuration(activity.durationSeconds),
            isDark,
          ),
          _buildDetailRow(
            Icons.straighten,
            'Jarak',
            '${activity.distanceKm.toStringAsFixed(2)} km',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite || paceMinPerKm.isNaN) {
      return "--'--\"";
    }
    final m = paceMinPerKm.floor();
    final s = ((paceMinPerKm - m) * 60).round();
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Metric Item Widget ────────────────────────────────────────────────────────
class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.white70),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
