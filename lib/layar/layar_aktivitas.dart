import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../penyedia/penyedia_aktivitas.dart';
import '../../inti/model/catatan_aktivitas.dart';
import '../inti/layanan/layanan_rute_cerdas.dart';

const LatLng _defaultCenter = LatLng(-6.2088, 106.8456);

enum JenisAktivitas {
  lari,
  sepeda,
  hiking,
  trailRun,
  sepedaTrail,
}

extension JenisAktivitasExt on JenisAktivitas {
  String get label {
    switch (this) {
      case JenisAktivitas.lari: return 'Lari';
      case JenisAktivitas.sepeda: return 'Bersepeda';
      case JenisAktivitas.hiking: return 'Hiking';
      case JenisAktivitas.trailRun: return 'Trail Run';
      case JenisAktivitas.sepedaTrail: return 'Sepeda Trail';
    }
  }

  IconData get icon {
    switch (this) {
      case JenisAktivitas.lari: return Icons.directions_run_rounded;
      case JenisAktivitas.sepeda: return Icons.directions_bike_rounded;
      case JenisAktivitas.hiking: return Icons.hiking_rounded;
      case JenisAktivitas.trailRun: return Icons.terrain_rounded;
      case JenisAktivitas.sepedaTrail: return Icons.pedal_bike_rounded;
    }
  }

  Color get color {
    switch (this) {
      case JenisAktivitas.lari: return const Color(0xFFFC5200);
      case JenisAktivitas.sepeda: return const Color(0xFF2563EB);
      case JenisAktivitas.hiking: return const Color(0xFF78350F);
      case JenisAktivitas.trailRun: return const Color(0xFF059669);
      case JenisAktivitas.sepedaTrail: return const Color(0xFF7C3AED);
    }
  }

  String get subtitle {
    switch (this) {
      case JenisAktivitas.lari: return 'Jalur aspal & perkotaan';
      case JenisAktivitas.sepeda: return 'Jalan raya & lintasan datar';
      case JenisAktivitas.hiking: return 'Gunung & jalur alam terbuka';
      case JenisAktivitas.trailRun: return 'Jalur alam & perbukitan';
      case JenisAktivitas.sepedaTrail: return 'Off-road & medan menantang';
    }
  }

  bool get isCycling =>
      this == JenisAktivitas.sepeda || this == JenisAktivitas.sepedaTrail;

  bool get isHikingOrTrail =>
      this == JenisAktivitas.hiking ||
      this == JenisAktivitas.trailRun ||
      this == JenisAktivitas.sepedaTrail;

  bool get requiresGps => true;

  double get met {
    switch (this) {
      case JenisAktivitas.lari: return 9.0;
      case JenisAktivitas.sepeda: return 7.5;
      case JenisAktivitas.hiking: return 6.0;
      case JenisAktivitas.trailRun: return 10.5;
      case JenisAktivitas.sepedaTrail: return 9.5;
    }
  }

  String get primaryMetric {
    switch (this) {
      case JenisAktivitas.lari: return 'Pace';
      case JenisAktivitas.sepeda: return 'Kecepatan';
      case JenisAktivitas.hiking: return 'Elevasi';
      case JenisAktivitas.trailRun: return 'Pace';
      case JenisAktivitas.sepedaTrail: return 'Kecepatan';
    }
  }
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          'Aktivitas',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
            fontSize: 22,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Image.asset(
              'assets/images/logo_brin.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.history_rounded, color: primary, size: 26),
              tooltip: 'Riwayat Aktivitas',
              onPressed: () => Navigator.pushNamed(context, '/activity-history'),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicator: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                labelColor: Colors.white,
                unselectedLabelColor:
                    isDark ? Colors.white60 : const Color(0xFF64748B),
                labelPadding: EdgeInsets.zero,
                tabs: [
                  _buildNavTab(icon: Icons.flash_on_rounded, label: 'Aktivitas'),
                  _buildNavTab(emoji: '👟', label: 'Langkah'),
                  _buildNavTab(emoji: '💧', label: 'Air'),
                  _buildNavTab(emoji: '🍽️', label: 'Makanan'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _ActivityMapTab(isDark: isDark),
          const _StepCounterTab(),
          const _WaterTab(),
          const _FoodLogTab(),
        ],
      ),
    );
  }

  Widget _buildNavTab({IconData? icon, String? emoji, required String label}) {
    return Tab(
      height: 38,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, size: 14)
              else if (emoji != null)
                Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  fontSize: 11,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step Counter Tab (Image 4) ──────────────────────────────────────────────
class _StepCounterTab extends StatefulWidget {
  const _StepCounterTab();
  @override
  State<_StepCounterTab> createState() => _StepCounterTabState();
}

class _StepCounterTabState extends State<_StepCounterTab> {
  static const List<int> _stepPresets = [2000, 5000, 7000, 10000];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().requestActivityPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final steps = provider.steps;
        final stepTarget =
            provider.stepTarget > 0 ? provider.stepTarget : 10000;
        final progress = (steps / stepTarget).clamp(0.0, 1.0);
        final calFromSteps = (steps * 0.04).round();
        final distKm = (steps / 1400.0);
        final isResting = steps == 0 || provider.currentSpeedKmh < 0.5;
        final cadence = provider.currentSpeedKmh > 0.5
            ? (provider.currentSpeedKmh * 20).round().toString()
            : '--';

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // ── Main Step Circular Ring Card (Image 4) ──
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    // Hollow Progress Ring
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: CustomPaint(
                        painter: _StepRingPainter(
                          progress: progress,
                          primaryColor: const Color(0xFF0284C7),
                          isDark: isDark,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$steps',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                'langkah',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  isResting ? 'Istirahat' : 'Aktif Melangkah',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Target: $stepTarget langkah',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Divider
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    ),
                    const SizedBox(height: 18),

                    // 3 Stat Columns (Image 4)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Column 1: Kalori
                        Column(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(
                              '$calFromSteps kkal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kalori',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),

                        // Column 2: Jarak
                        Column(
                          children: [
                            const Text('〰️', style: TextStyle(fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(
                              '${distKm.toStringAsFixed(2)} km',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Jarak',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),

                        // Column 3: Cadence
                        Column(
                          children: [
                            const Text('🏃', style: TextStyle(fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(
                              '$cadence spm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cadence',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Target Harian Card (Image 4) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target Harian',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0284C7)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preset Buttons: 2K, 5K, 7K, 10K (Image 4)
                    Row(
                      children: _stepPresets.map((preset) {
                        final isSelected = preset == stepTarget;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () async {
                                await context
                                    .read<ActivityProvider>()
                                    .updateStepTarget(preset);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE0F2FE)
                                      : (isDark
                                          ? const Color(0xFF0F172A)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0284C7)
                                        : (isDark
                                            ? Colors.white12
                                            : const Color(0xFFCBD5E1)),
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(Icons.check_rounded,
                                            size: 16,
                                            color: Color(0xFF0284C7)),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        '${preset ~/ 1000}K',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          fontFamily: 'Poppins',
                                          color: isSelected
                                              ? const Color(0xFF0284C7)
                                              : (isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Navigation Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/gait-analysis'),
                      icon: const Icon(Icons.directions_walk_rounded, size: 18),
                      label: const Text('Gait Analysis',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/step-calculator'),
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: const Text('Kalkulator',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final bool isDark;

  const _StepRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;
    const strokeW = 18.0;

    // Background track
    final bgPaint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      const gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          Color(0xFF0284C7),
          Color(0xFF0EA5E9),
          Color(0xFF38BDF8),
        ],
      );

      final progressPaint = Paint()
        ..shader = gradient
            .createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      // Glowing tip dot
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      final dotPaint = Paint()..color = Colors.white;
      final glowPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6);
      canvas.drawCircle(Offset(tipX, tipY), 9, glowPaint);
      canvas.drawCircle(Offset(tipX, tipY), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StepRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

// ─── GPS Map Tab ────────────────────────────────────────────────────────────────
// ─── GPS Map Tab ────────────────────────────────────────────────────────────────
class RecommendedRoute {
  final String id;
  final String name;
  final String type;
  final double distanceKm;
  final int estMinutes;
  final String terrain;
  final int elevationGainM;
  final String difficulty;
  final String description;
  final List<LatLng> waypoints;
  final bool isTrackLoop;
  final int laps;
  final bool isSafeFromHighway;
  final String? warningBadge;

  const RecommendedRoute({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.estMinutes,
    required this.terrain,
    required this.elevationGainM,
    required this.difficulty,
    required this.description,
    required this.waypoints,
    this.isTrackLoop = false,
    this.laps = 1,
    this.isSafeFromHighway = true,
    this.warningBadge,
  });
}

class _ActivityMapTab extends StatefulWidget {
  final bool isDark;
  const _ActivityMapTab({required this.isDark});
  @override
  State<_ActivityMapTab> createState() => _ActivityMapTabState();
}

class _ActivityMapTabState extends State<_ActivityMapTab>
    with WidgetsBindingObserver {
  final fm.MapController _mapController = fm.MapController();
  JenisAktivitas _selectedJenis = JenisAktivitas.lari;
  RecommendedRoute? _selectedRoute;

  bool _locationLoading = false;
  String? _locationError;
  LatLng? _currentPos;
  StreamSubscription<Position>? _positionSub;
  double _userHeading = 0.0;
  bool _isLoadingRoute = false;
  int _selectedTrackLaps = 5; // Default 5 laps = 2.0 km untuk track lari lapangan

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  Future<void> _initLocation() async {
    if (!mounted) return;
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError =
                'Layanan lokasi dinonaktifkan.\nAktifkan GPS di pengaturan perangkat Anda.';
            _locationLoading = false;
          });
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationError =
                'Izin lokasi ditolak.\nBuka Pengaturan → Izin Aplikasi untuk mengaktifkannya.';
            _locationLoading = false;
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      );

      if (mounted) {
        final newPos = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentPos = newPos;
          if (pos.heading > 0) _userHeading = pos.heading;
          _locationLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentPos != null) {
            try {
              _mapController.move(newPos, 17);
            } catch (e) {
              debugPrint('MapController error: $e');
            }
          }
        });
      }

      // Start live stream to follow user like Google Maps
      _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen(
        (p) {
          if (!mounted) return;
          final updatedPos = LatLng(p.latitude, p.longitude);
          setState(() {
            _currentPos = updatedPos;
            if (p.heading > 0 && !p.heading.isNaN && !p.heading.isInfinite) {
              _userHeading = p.heading;
            }
          });
        },
        onError: (e) {
          debugPrint('Activity position stream error: $e');
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Gagal mendeteksi lokasi GPS: $e';
          _locationLoading = false;
        });
      }
    }
  }

  Future<void> _selectAndDisplayRoute(RecommendedRoute route) async {
    final origin = _currentPos ?? _defaultCenter;
    setState(() => _isLoadingRoute = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menghubungkan jalur rute GPS "${route.name}"...'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1A73E8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final List<LatLng> realWaypoints;
    if (route.isTrackLoop || route.id.startsWith('dest_')) {
      // Loop lapangan atletik 400m atau rute gunung asli: pertahankan koordinat presisi asli tanpa OSRM
      realWaypoints = route.waypoints;
    } else {
      final targets = route.waypoints.length > 1
          ? route.waypoints.sublist(1)
          : [
              LatLng(origin.latitude + 0.0035, origin.longitude + 0.0030),
              LatLng(origin.latitude + 0.0050, origin.longitude - 0.0015),
              origin,
            ];

      realWaypoints = await _fetchRealStreetRoute(
        start: origin,
        targetWaypoints: targets,
        isCycling: _selectedJenis.isCycling,
      );
    }

    final updated = RecommendedRoute(
      id: route.id,
      name: route.name,
      type: route.type,
      distanceKm: route.distanceKm,
      estMinutes: route.estMinutes,
      terrain: route.terrain,
      elevationGainM: route.elevationGainM,
      difficulty: route.difficulty,
      description: route.description,
      waypoints: realWaypoints,
      isTrackLoop: route.isTrackLoop,
      laps: route.laps,
      isSafeFromHighway: route.isSafeFromHighway,
      warningBadge: route.warningBadge,
    );

    if (mounted) {
      setState(() {
        _selectedRoute = updated;
        _isLoadingRoute = false;
      });

      if (realWaypoints.isNotEmpty) {
        try {
          final bounds = fm.LatLngBounds.fromPoints(realWaypoints);
          _mapController.fitCamera(
            fm.CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.fromLTRB(40, 100, 40, 180),
            ),
          );
        } catch (_) {
          _mapController.move(realWaypoints.first, 16.5);
        }
      }
    }
  }

  Future<List<LatLng>> _fetchRealStreetRoute({
    required LatLng start,
    required List<LatLng> targetWaypoints,
    required bool isCycling,
  }) async {
    try {
      final mode = isCycling ? 'bicycle' : 'foot';
      final allPoints = [start, ...targetWaypoints];
      final coordsStr = allPoints.map((p) => '${p.longitude},${p.latitude}').join(';');
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/$mode/$coordsStr?overview=full&geometries=geojson',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final coordsList = data['routes'][0]['geometry']['coordinates'] as List;
          final result = coordsList
              .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (result.length >= 2) return result;
        }
      }
    } catch (e) {
      debugPrint('OSRM routing fallback: $e');
    }

    return _generateGridStreetPath(start, targetWaypoints);
  }

  List<LatLng> _generateGridStreetPath(LatLng start, List<LatLng> targets) {
    final path = <LatLng>[start];
    var curr = start;
    for (final tgt in targets) {
      final latSteps = ((tgt.latitude - curr.latitude).abs() / 0.0003).ceil().clamp(2, 12);
      for (int i = 1; i <= latSteps; i++) {
        final f = i / latSteps;
        path.add(LatLng(curr.latitude + (tgt.latitude - curr.latitude) * f, curr.longitude));
      }
      final lngSteps = ((tgt.longitude - curr.longitude).abs() / 0.0003).ceil().clamp(2, 12);
      for (int i = 1; i <= lngSteps; i++) {
        final f = i / lngSteps;
        path.add(LatLng(tgt.latitude, curr.longitude + (tgt.longitude - curr.longitude) * f));
      }
      curr = tgt;
    }
    return path;
  }

  List<RecommendedRoute> _getNearbyRoutes(LatLng origin, JenisAktivitas jenis) {
    final lat = origin.latitude;
    final lng = origin.longitude;

    if (jenis == JenisAktivitas.lari) {
      final trackDist = double.parse((_selectedTrackLaps * 0.40).toStringAsFixed(1));
      final trackEstMin = (_selectedTrackLaps * 2.5).round();

      return [
        RecommendedRoute(
          id: 'route_track_400m',
          name: 'Loop Lapangan 400m ($_selectedTrackLaps Putaran)',
          type: 'Lari Lapangan',
          distanceKm: trackDist,
          estMinutes: trackEstMin,
          terrain: 'Lintasan Tartan / Rumput Lapangan',
          elevationGainM: 0,
          difficulty: 'Mudah',
          description:
              'Rute oval standar atletik 400m yang berputar di dalam lapangan. 100% aman, 0% risiko kendaraan, bebas jalan raya.',
          waypoints: SmartRouteService.generateAthleticTrackLoop(
            origin,
            laps: _selectedTrackLaps,
            headingDegrees: _userHeading,
          ),
          isTrackLoop: true,
          laps: _selectedTrackLaps,
          isSafeFromHighway: true,
        ),
        RecommendedRoute(
          id: 'route_safe_residential',
          name: 'Loop Pemukiman & Gang Santai',
          type: 'Lari Santai',
          distanceKm: 1.5,
          estMinutes: 10,
          terrain: 'Jalan Lingkungan & Paving Perumahan',
          elevationGainM: 5,
          difficulty: 'Mudah',
          description:
              'Rute santai melingkar di sekeliling blok perumahan dan jalan lingkungan terdekat. Terhindar dari jalan raya utama.',
          waypoints: [
            origin,
            LatLng(lat + 0.0012, lng + 0.0010),
            LatLng(lat + 0.0018, lng - 0.0006),
            LatLng(lat + 0.0008, lng - 0.0012),
            origin,
          ],
          isSafeFromHighway: true,
        ),
        RecommendedRoute(
          id: 'route_circuit_2',
          name: 'Sirkuit Interval Lingkungan 2.8K',
          type: 'Lari Tempo',
          distanceKm: 2.8,
          estMinutes: 18,
          terrain: 'Jalan Lingkungan Sekunder',
          elevationGainM: 15,
          difficulty: 'Menengah',
          description:
              'Lintasan melingkar jalan pemukiman sekunder minim kendaraan ramai, ideal untuk melatih ritme nafas.',
          waypoints: [
            origin,
            LatLng(lat + 0.0022, lng + 0.0018),
            LatLng(lat + 0.0032, lng + 0.0008),
            LatLng(lat + 0.0014, lng - 0.0012),
            origin,
          ],
          isSafeFromHighway: true,
        ),
        RecommendedRoute(
          id: 'route_endurance_3',
          name: 'Tantangan 5K Endurance',
          type: 'Lari Jarak Jauh',
          distanceKm: 5.1,
          estMinutes: 31,
          terrain: 'Kombinasi Aspal Halus & Tanjakan Ringan',
          elevationGainM: 42,
          difficulty: 'Menengah',
          description:
              'Target jarak 5K untuk pembakaran kalori optimal dan peningkatan stamina kardiovaskular.',
          waypoints: [
            origin,
            LatLng(lat - 0.0042, lng + 0.0048),
            LatLng(lat - 0.0088, lng + 0.0032),
            LatLng(lat - 0.0112, lng - 0.0024),
            LatLng(lat - 0.0048, lng - 0.0038),
            origin,
          ],
          isSafeFromHighway: false,
        ),
      ];
    }

    if (jenis.isCycling) {
      return [
        RecommendedRoute(
          id: 'route_loop_bike',
          name: 'Loop Sepeda Kota Santai',
          type: 'Sepeda',
          distanceKm: 4.2,
          estMinutes: 12,
          terrain: 'Aspal Halus & Jalur Sepeda',
          elevationGainM: 14,
          difficulty: 'Mudah',
          description:
              'Rute melingkar aman dan nyaman yang berawal serta berakhir tepat di posisi Anda saat ini.',
          waypoints: [
            origin,
            LatLng(lat + 0.0038, lng + 0.0032),
            LatLng(lat + 0.0058, lng - 0.0016),
            LatLng(lat + 0.0022, lng - 0.0038),
            origin,
          ],
          isSafeFromHighway: true,
        ),
        RecommendedRoute(
          id: 'route_circuit_bike',
          name: 'Sirkuit Akselerasi & Sprint',
          type: 'Sepeda',
          distanceKm: 6.5,
          estMinutes: 18,
          terrain: 'Jalan Raya & Lintasan Terbuka',
          elevationGainM: 26,
          difficulty: 'Menengah',
          description:
              'Lintasan terbuka minim persimpangan, ideal untuk melatih cadence gowes dan konsistensi kecepatan.',
          waypoints: [
            origin,
            LatLng(lat + 0.0068, lng + 0.0052),
            LatLng(lat + 0.0108, lng + 0.0032),
            LatLng(lat + 0.0042, lng - 0.0022),
            origin,
          ],
          isSafeFromHighway: false,
        ),
        RecommendedRoute(
          id: 'route_endurance_bike',
          name: 'Rute Gowes Jarak Jauh 10K',
          type: 'Sepeda',
          distanceKm: 10.2,
          estMinutes: 28,
          terrain: 'Kombinasi Aspal & Tanjakan Ringan',
          elevationGainM: 48,
          difficulty: 'Menengah',
          description:
              'Target jarak gowes 10K untuk pembakaran kalori maksimal dan latihan ketahanan kardiovaskular.',
          waypoints: [
            origin,
            LatLng(lat - 0.0052, lng + 0.0062),
            LatLng(lat - 0.0112, lng + 0.0042),
            LatLng(lat - 0.0142, lng - 0.0032),
            LatLng(lat - 0.0062, lng - 0.0052),
            origin,
          ],
          isSafeFromHighway: false,
        ),
      ];
    }

    // Untuk Hiking, Trail Run, Sepeda Trail:
    final hikingCheck = SmartRouteService.checkHikingAvailability(origin);

    if (hikingCheck.isHikingNearby && hikingCheck.nearestSpot != null) {
      final spot = hikingCheck.nearestSpot!;
      return [
        RecommendedRoute(
          id: 'route_trail_authentic',
          name: 'Jalur Pendakian ${spot.name}',
          type: jenis.label,
          distanceKm: 4.8,
          estMinutes: 80,
          terrain: spot.terrain,
          elevationGainM: (spot.elevationM * 0.35).round(),
          difficulty: spot.difficulty,
          description:
              '${spot.description}\n(Spot terverifikasi: ~${hikingCheck.distanceToNearestKm.toStringAsFixed(1)} km dari posisi Anda)',
          waypoints: [
            LatLng(spot.lat, spot.lng),
            LatLng(spot.lat + 0.0032, spot.lng + 0.0026),
            LatLng(spot.lat + 0.0064, spot.lng + 0.0040),
            LatLng(spot.lat + 0.0036, spot.lng - 0.0016),
            LatLng(spot.lat, spot.lng),
          ],
          isSafeFromHighway: true,
        ),
        RecommendedRoute(
          id: 'route_trail_ridge',
          name: 'Sirkuit Punggungan Alam & Tanjakan',
          type: jenis.label,
          distanceKm: 6.2,
          estMinutes: 110,
          terrain: 'Tanah Padat, Akar Pohon & Tanjakan',
          elevationGainM: (spot.elevationM * 0.55).round(),
          difficulty: 'Menantang',
          description:
              'Tantangan elevasi alami dengan kontur variatif di kawasan perbukitan hijau.',
          waypoints: [
            LatLng(spot.lat, spot.lng),
            LatLng(spot.lat + 0.0045, spot.lng - 0.0055),
            LatLng(spot.lat + 0.0085, spot.lng - 0.0090),
            LatLng(spot.lat + 0.0125, spot.lng - 0.0065),
            LatLng(spot.lat, spot.lng),
          ],
          isSafeFromHighway: true,
        ),
      ];
    } else {
      // Area Perkotaan / Pemukiman:
      // Jangan membuat rute fiktif di atas jalan perumahan.
      // List rute dikembalikan kosong sehingga antarmuka menampilkan opsi 'Buat Rute Sendiri'
      // dan daftar Pos Pendakian resmi terdekat.
      return const <RecommendedRoute>[];
    }
  }

  void _startTracking() {
    context.read<ActivityProvider>().startTracking(_selectedJenis.label);
  }

  void _pauseTracking() => context.read<ActivityProvider>().pauseTracking();
  void _resumeTracking() => context.read<ActivityProvider>().resumeTracking();

  Future<void> _showAutoPausePopup() async {
    final provider = context.read<ActivityProvider>();
    if (provider.isAutoPausePopupOpen) return;

    provider.pauseTracking();
    provider.setAutoPausePopupOpen(true);

    final action = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Aktivitas Terhenti?',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Kami mendeteksi Anda berhenti bergerak.\nIngin melanjutkan atau menyelesaikan sesi ini?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Selesai'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lanjut',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    provider.setAutoPausePopupOpen(false);
    if (!mounted) return;

    if (action == true) {
      provider.resumeTracking();
      return;
    }

    if (action == false) {
      await _stopTracking();
    }
  }

  Future<void> _stopTracking() async {
    final provider = context.read<ActivityProvider>();
    final distanceKm = provider.activeDistanceKm;
    final seconds = provider.activeSeconds;
    final calories = provider.activeCalories;
    final type = provider.activeType;
    final isCycling = _selectedJenis.isCycling;

    final paceStr = _formatPace(provider.averagePaceMinPerKm);
    final avgSpeedStr = '${provider.averageSpeedKmh.toStringAsFixed(1)} km/j';
    final maxSpeedStr = '${provider.maxSpeedKmh.toStringAsFixed(1)} km/j';
    final stepsStr = '${provider.activeEstimatedSteps}';

    await provider.stopTracking();

    if ((distanceKm > 0 || seconds >= 10) && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(_selectedJenis.icon, color: _selectedJenis.color, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sesi $type Selesai!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultRow('Jarak', '${distanceKm.toStringAsFixed(2)} km'),
              _ResultRow('Waktu', _formatTime(seconds)),
              _ResultRow('Kalori', '$calories kkal'),
              if (isCycling) ...[
                _ResultRow('Kecepatan Rata-rata', avgSpeedStr),
                _ResultRow('Kecepatan Maksimal', maxSpeedStr),
              ] else ...[
                _ResultRow('Pace Rata-rata', paceStr),
                _ResultRow('Estimasi Langkah', stepsStr),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedJenis.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  String _formatPace(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite || paceMinPerKm.isNaN) {
      return "--'--\"";
    }
    final m = paceMinPerKm.floor();
    final s = ((paceMinPerKm - m) * 60).round();
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  void _centerOnUser() {
    if (_currentPos != null) {
      _mapController.move(_currentPos!, 17);
    } else {
      _initLocation();
    }
  }

  void _showActivityPickerModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Pilih Aktivitas Olahraga',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sesuaikan olahraga untuk metrik dan kalkulasi akurat',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: JenisAktivitas.values.map((j) {
                    final isSelected = j == _selectedJenis;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? j.color.withValues(alpha: isDark ? 0.2 : 0.08)
                            : (isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? j.color
                              : (isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: j.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(j.icon, color: j.color, size: 24),
                        ),
                        title: Text(
                          j.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          j.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color: j.color, size: 24)
                            : Icon(Icons.circle_outlined,
                                color:
                                    isDark ? Colors.white24 : Colors.black26,
                                size: 22),
                        onTap: () {
                          setState(() {
                            _selectedJenis = j;
                            _selectedRoute = null;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Future<void> _startAreaScanAndShowRoutes(bool isDark) async {
    // Tampilkan dialog animasi pemindaian cerdas GPS & analisis lingkungan sekitar
    int scanStep = 0;
    Timer? scanTimer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            scanTimer ??= Timer.periodic(const Duration(milliseconds: 420), (t) {
              if (t.tick >= 4) {
                t.cancel();
                if (Navigator.canPop(dialogCtx)) {
                  Navigator.pop(dialogCtx);
                }
              } else {
                setDialogState(() {
                  scanStep = t.tick;
                });
              }
            });

            final stepTexts = [
              '📡 Mengunci koordinat GPS akurat...',
              '🏘️ Menganalisis lingkungan sekitar (pemukiman & gang)...',
              '🛡️ Menyaring jalan raya utama & memeriksa kontur alam...',
              '✨ Menyesuaikan opsi rute dengan posisi Anda...',
            ];

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(_selectedJenis.color),
                        ),
                      ),
                      Icon(
                        Icons.radar_rounded,
                        color: _selectedJenis.color,
                        size: 34,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Memindai Area Sekitar...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      stepTexts[scanStep.clamp(0, stepTexts.length - 1)],
                      key: ValueKey<int>(scanStep),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    scanTimer?.cancel();
    if (!mounted) return;

    _showRouteRecommendationModal(context, isDark);
  }

  void _showRouteRecommendationModal(BuildContext context, bool isDark) {
    final origin = _currentPos ?? _defaultCenter;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final routes = _getNearbyRoutes(origin, _selectedJenis);
            final isHikingType = _selectedJenis.isHikingOrTrail;
            final hikingStatus = isHikingType
                ? SmartRouteService.checkHikingAvailability(origin)
                : null;

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selectedJenis.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_selectedJenis.icon,
                            color: _selectedJenis.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilihan Rute ${_selectedJenis.label}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              _currentPos != null
                                  ? 'GPS Terkunci • Rute disesuaikan dengan lingkungan Anda'
                                  : 'GPS mencari posisi... • Menampilkan rute adaptif',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ─── KARTU UTAMA: BUAT RUTE SENDIRI SECARA BEBAS ─────────────
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                            : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3B82F6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
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
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.edit_road_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Buat Rute Sendiri',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '★ Pilihan Utama',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Bebas lewati gang & jalan mana pun',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark ? Colors.white70 : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'GPS akan menggambar garis jejak nyata secara live mengikuti ke mana pun langkah Anda bergerak tanpa batasan template jalur.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedRoute = null; // Reset template route to use pure free tracking
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Mode Rekam Rute Sendiri aktif! Tekan tombol Play (▶️) di bawah dan mulai melangkah.'),
                                  backgroundColor: Color(0xFF2563EB),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                            label: const Text(
                              'Gunakan Mode Rekam Bebas',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Pilihan Putaran Lap Khusus Mode Lari Lapangan ─────────────
                  if (_selectedJenis == JenisAktivitas.lari)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stadium_rounded,
                                  color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Mode Lapangan Atletik (400m Track)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '0% Jalan Raya',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rute oval berputar di dalam lapangan tanpa keluar ke jalan raya. Pilih putaran:',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final laps in [3, 5, 10, 12]) ...[
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                    child: InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          setState(() {
                                            _selectedTrackLaps = laps;
                                          });
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _selectedTrackLaps == laps
                                              ? const Color(0xFF10B981)
                                              : (isDark
                                                  ? Colors.white10
                                                  : Colors.black.withValues(alpha: 0.05)),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _selectedTrackLaps == laps
                                                ? const Color(0xFF10B981)
                                                : (isDark
                                                    ? Colors.white24
                                                    : Colors.black12),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              laps == 12 ? '12.5x' : '${laps}x',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
                                                color: _selectedTrackLaps == laps
                                                    ? Colors.white
                                                    : (isDark
                                                        ? Colors.white
                                                        : Colors.black87),
                                              ),
                                            ),
                                            Text(
                                              laps == 12
                                                  ? '5.0 km'
                                                  : '${(laps * 0.4).toStringAsFixed(1)} km',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                color: _selectedTrackLaps == laps
                                                    ? Colors.white70
                                                    : (isDark
                                                        ? Colors.white60
                                                        : Colors.black54),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                  // ─── Peringatan Area Perkotaan Khusus Hiking / Trail ──────────
                  if (isHikingType && hikingStatus != null && !hikingStatus.isHikingNearby)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_city_rounded,
                                  color: Color(0xFFD97706), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Deteksi Lokasi: Kawasan Pemukiman / Perkotaan',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Lokasi Anda berada di kawasan pemukiman (~${hikingStatus.distanceToNearestKm.toStringAsFixed(1)} km dari kaki ${hikingStatus.nearestSpot?.name ?? 'gunung'}).\n\nJalur pendakian alami tidak dapat dibuat di atas jalan perumahan. Untuk berolahraga di sekitar sini, gunakan Mode Rekam Rute Sendiri di atas. Jika ingin mendaki, Anda dapat melihat rute resmi di Basecamp berikut:',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF78350F),
                                height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _selectedRoute = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Mode Rekam Rute Sendiri aktif! Tekan Play (▶️) untuk mulai melangkah.'),
                                        backgroundColor: Color(0xFF2563EB),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_road_rounded, size: 15),
                                  label: const Text('Rekam Bebas di Sini',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white : const Color(0xFF92400E),
                                    side: BorderSide(
                                        color: const Color(0xFFD97706).withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _selectedJenis = JenisAktivitas.lari;
                                      _selectedRoute = null;
                                    });
                                    _showRouteRecommendationModal(context, isDark);
                                  },
                                  icon: const Icon(Icons.directions_run_rounded, size: 15),
                                  label: const Text('Ganti ke Mode Lari',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // ─── Header List Rute / Destinasi ─────────────────────────────
                  if (isHikingType && hikingStatus != null && !hikingStatus.isHikingNearby) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Destinasi Hiking Terdekat dari Posisi Anda:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: hikingStatus.nearestDestinations.length,
                        itemBuilder: (context, idx) {
                          final dest = hikingStatus.nearestDestinations[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dest.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '~${dest.distanceKm.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dest.region,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dest.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildMiniBadge(Icons.landscape_rounded, '+${dest.elevationM}m', isDark),
                                    const SizedBox(width: 6),
                                    _buildMiniBadge(Icons.terrain_rounded, dest.difficulty, isDark),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final mountainRoute = RecommendedRoute(
                                        id: 'dest_${dest.id}',
                                        name: 'Jalur ${dest.name}',
                                        type: 'Hiking Gunung',
                                        distanceKm: 5.2,
                                        estMinutes: 95,
                                        terrain: dest.terrain,
                                        elevationGainM: (dest.elevationM * 0.35).round(),
                                        difficulty: dest.difficulty,
                                        description:
                                            '${dest.description}\n(Jarak dari lokasi Anda: ~${dest.distanceKm.toStringAsFixed(1)} km)',
                                        waypoints: [
                                          LatLng(dest.lat, dest.lng),
                                          LatLng(dest.lat + 0.0035, dest.lng + 0.0028),
                                          LatLng(dest.lat + 0.0068, dest.lng + 0.0042),
                                          LatLng(dest.lat + 0.0032, dest.lng - 0.0018),
                                          LatLng(dest.lat, dest.lng),
                                        ],
                                        isSafeFromHighway: true,
                                      );
                                      Navigator.pop(ctx);
                                      _selectAndDisplayRoute(mountainRoute);
                                    },
                                    icon: const Icon(Icons.map_rounded, size: 16),
                                    label: const Text('Tampilkan Rute Gunung di Peta',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF78350F),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // ─── List Rute Normal (Lari / Sepeda / Hiking di Pegunungan) ─
                    Expanded(
                      child: ListView.builder(
                        itemCount: routes.length,
                        itemBuilder: (context, idx) {
                          final r = routes[idx];
                          final isCurrentActive = _selectedRoute?.id == r.id;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isCurrentActive
                                  ? const Color(0xFF0F52BA).withValues(alpha: isDark ? 0.2 : 0.08)
                                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrentActive
                                    ? const Color(0xFF0F52BA)
                                    : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                width: isCurrentActive ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.name,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (r.difficulty == 'Mudah'
                                                ? Colors.green
                                                : r.difficulty == 'Menengah'
                                                    ? Colors.orange
                                                    : Colors.red)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        r.difficulty,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: r.difficulty == 'Mudah'
                                              ? Colors.green
                                              : r.difficulty == 'Menengah'
                                                  ? Colors.orange
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Safety & Track Badges
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (r.isTrackLoop)
                                      _buildSafetyBadge(
                                        Icons.stadium_rounded,
                                        'Loop Lapangan 400m',
                                        const Color(0xFF10B981),
                                        isDark,
                                      ),
                                    if (r.isSafeFromHighway)
                                      _buildSafetyBadge(
                                        Icons.verified_user_rounded,
                                        'Bebas Jalan Raya',
                                        const Color(0xFF0284C7),
                                        isDark,
                                      )
                                    else
                                      _buildSafetyBadge(
                                        Icons.warning_rounded,
                                        'Jalan Raya & Tanjakan',
                                        const Color(0xFFF59E0B),
                                        isDark,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  r.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildMiniBadge(Icons.straighten_rounded, '${r.distanceKm} km', isDark),
                                    const SizedBox(width: 8),
                                    _buildMiniBadge(Icons.timer_outlined, '~${r.estMinutes} mnt', isDark),
                                    const SizedBox(width: 8),
                                    _buildMiniBadge(Icons.landscape_rounded, '+${r.elevationGainM}m', isDark),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _selectAndDisplayRoute(r);
                                    },
                                    icon: Icon(
                                      isCurrentActive ? Icons.check_circle_rounded : Icons.map_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isCurrentActive ? 'Rute Aktif di Peta' : 'Pilih & Tampilkan di Peta',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCurrentActive
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF0F52BA),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  Widget _buildSafetyBadge(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final dietRec = provider.dietActivityRecommendation;
    final isDark = widget.isDark;
    final primaryColor = _selectedJenis.color;

    final bool isTracking = provider.isTracking;
    final isCycling = _selectedJenis.isCycling;
    final route = isTracking ? provider.activeRoute : <LatLng>[];

    // Auto pause check (hanya untuk aktivitas berbasis GPS, >= 45 detik berhenti bergerak, dan belum dijeda)
    if (isTracking &&
        _selectedJenis.requiresGps &&
        !provider.isPaused &&
        provider.secondsSinceLastMove >= 45 &&
        !provider.isAutoPausePopupOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAutoPausePopup();
      });
    }

    return Column(
      children: [
        // Diet recommendation banner (jika ada)
        if (dietRec != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: primaryColor.withValues(alpha: 0.12),
            child: Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🥗 Diet Aktif: $dietRec',
                    style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

        // Map section
        Expanded(
          flex: isTracking ? 5 : 8,
          child: Stack(
            children: [
              // OpenStreetMap via flutter_map (selalu tampil)
                fm.FlutterMap(
                  mapController: _mapController,
                  options: fm.MapOptions(
                    initialCenter: _currentPos ?? _defaultCenter,
                    initialZoom: 17,
                    interactionOptions: const fm.InteractionOptions(
                      flags: fm.InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sehati.ai.activity',
                    ),
                    // Garis Rekomendasi Rute terpilih (Google Maps style road polyline)
                    if (_selectedRoute != null &&
                        _selectedRoute!.waypoints.length >= 2) ...[
                      fm.PolylineLayer(
                        polylines: [
                          // White outer casing for high contrast on streets
                          fm.Polyline(
                            points: _selectedRoute!.waypoints,
                            strokeWidth: 9,
                            color: Colors.white,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                          // Signature Google Maps vibrant navigation blue
                          fm.Polyline(
                            points: _selectedRoute!.waypoints,
                            strokeWidth: 5.5,
                            color: const Color(0xFF1A73E8),
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                        ],
                      ),
                      // Marker untuk titik mulai & akhir rekomendasi rute (Google Maps style)
                      fm.MarkerLayer(
                        markers: [
                          // Titik mulai (Green circle with play icon)
                          fm.Marker(
                            point: _selectedRoute!.waypoints.first,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          // Titik akhir jika > 1 titik (Red circle with flag icon)
                          if (_selectedRoute!.waypoints.length > 1)
                            fm.Marker(
                              point: _selectedRoute!.waypoints.last,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.flag_rounded,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    // Route polyline live tracking
                    if (route.length >= 2)
                      fm.PolylineLayer(
                        polylines: [
                          fm.Polyline(
                            points: route,
                            strokeWidth: 9,
                            color: Colors.white.withValues(alpha: 0.8),
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                          fm.Polyline(
                            points: route,
                            strokeWidth: 5.5,
                            color: primaryColor,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                        ],
                      ),
                    // Live User Location Marker (Google Maps directional pointer style!)
                    if (_currentPos != null)
                      fm.MarkerLayer(
                        markers: [
                          fm.Marker(
                            point: _currentPos!,
                            width: 64,
                            height: 64,
                            child: _GoogleMapsUserPointer(
                              color: primaryColor,
                              heading: _userHeading,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

              // Indikator memuat rute OSRM
              if (_isLoadingRoute)
                Positioned(
                  top: 14,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF1A73E8),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Menghubungkan jalur jalan raya GPS...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading overlay
              if (_locationLoading)
                Container(
                  color: Colors.black38,
                  child: const Center(child: CircularProgressIndicator()),
                ),

              // Floating GPS status banner jika ada kendala GPS
              if (_locationError != null)
                Positioned(
                  top: 14,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_off_rounded,
                            color: Colors.amber, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _locationError!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: _initLocation,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Coba Lagi',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Banner rute rekomendasi aktif di bagian atas peta
              if (_selectedRoute != null)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alt_route_rounded,
                            color: Color(0xFF2563EB), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedRoute!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_selectedRoute!.distanceKm} km • ${_selectedRoute!.terrain}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _selectedRoute = null),
                        ),
                      ],
                    ),
                  ),
                ),

              // Banner mode rekam mandiri jika tidak ada template rute terpilih
              if (_selectedRoute == null && !isTracking)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.94)
                          : Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.edit_road_rounded,
                              color: primaryColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Mode: Rekam Rute Sendiri (Bebas)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Tekan ▶️ lalu bergerak; GPS otomatis menggambar rute di gang/jalan Anda.',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Center-on-user FAB
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'center_activity_tab',
                  onPressed: _centerOnUser,
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                  elevation: 4,
                  child: Icon(
                    Icons.my_location,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Section:
        // Saat TIDAK MEREKAM -> Dock Kontrol Ala Strava (Aktivitas | Mulai Play | Rekomendasi Rute)
        // Saat MEREKAM -> Panel Metrik Live (Timer, Pace/Kecepatan, Langkah, Kalori, Tombol Jeda & Selesai)
        if (!isTracking)
          _buildStravaControlDock(context, isDark, provider)
        else
          _buildActiveMetricsHUD(context, isDark, provider, isCycling),
      ],
    );
  }

  Widget _buildStravaControlDock(
      BuildContext context, bool isDark, ActivityProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 1. KIRI: Pemilih Aktivitas (Expanded + Center -> simetris 50% sisi kiri)
            Expanded(
              child: Center(
                child: InkWell(
                  onTap: () => _showActivityPickerModal(context, isDark),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _selectedJenis.color.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                            border: Border.all(color: _selectedJenis.color, width: 2),
                          ),
                          child: Icon(_selectedJenis.icon,
                              color: _selectedJenis.color, size: 26),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedJenis.label,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_up_rounded,
                                size: 16,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. TENGAH: Tombol Mulai dengan Logo Play (Tepat 50% di Tengah Layar)
            GestureDetector(
              onTap: () {
                if (_selectedJenis.requiresGps &&
                    _locationError != null &&
                    _currentPos == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Mencari sinyal GPS untuk ${_selectedJenis.label}... Sesi dimulai.'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  _initLocation();
                }
                _startTracking();
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _selectedJenis.color,
                      _selectedJenis.color.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedJenis.color.withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // 3. KANAN: Pindai Rute Sekitar (Expanded + Center -> simetris 50% sisi kanan, jarak identik!)
            Expanded(
              child: Center(
                child: InkWell(
                  onTap: () => _startAreaScanAndShowRoutes(isDark),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF2563EB), width: 2),
                          ),
                          child: const Icon(Icons.radar_rounded,
                              color: Color(0xFF2563EB), size: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pindai Rute',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMetricsHUD(BuildContext context, bool isDark,
      ActivityProvider provider, bool isCycling) {
    final distanceKm = provider.activeDistanceKm;
    final seconds = provider.activeSeconds;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Activity Type indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _selectedJenis.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_selectedJenis.icon,
                          color: _selectedJenis.color, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedJenis.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: provider.isPaused ? Colors.amber : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      provider.isPaused ? 'Dijeda' : 'Merekam',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hero Timer Display (Hanya muncul saat tombol Mulai ditekan)
            Text(
              _formatTime(seconds),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Grid sesuai jenis aktivitas
            if (isCycling) ...[
              // SEPEDA & SEPEDA TRAIL: Jarak, Kecepatan Live, Kecepatan Avg, Max, Kalori
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(
                    emoji: '📍',
                    value: '${distanceKm.toStringAsFixed(2)} km',
                    label: 'Jarak',
                    isDark: isDark,
                  ),
                  _StatBox(
                    emoji: '🚴',
                    value:
                        '${provider.currentSpeedKmh.toStringAsFixed(1)} km/j',
                    label: 'Kecepatan Live',
                    isDark: isDark,
                  ),
                  _StatBox(
                    emoji: '⚡',
                    value:
                        '${provider.averageSpeedKmh.toStringAsFixed(1)} km/j',
                    label: 'Kecepatan Avg',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(
                    emoji: '🚀',
                    value: '${provider.maxSpeedKmh.toStringAsFixed(1)} km/j',
                    label: 'Kecepatan Max',
                    isDark: isDark,
                  ),
                  _StatBox(
                    emoji: '🔥',
                    value: '${provider.activeCalories} kkal',
                    label: 'Kalori',
                    isDark: isDark,
                  ),
                ],
              ),
            ] else ...[
              // LARI, TRAIL RUN & HIKING: Jarak, Pace Live, Pace Avg, Langkah, Kalori
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(
                    emoji: '📍',
                    value: '${distanceKm.toStringAsFixed(2)} km',
                    label: 'Jarak',
                    isDark: isDark,
                  ),
                  _StatBox(
                    emoji: '⚡',
                    value: _formatPace(provider.livePaceMinPerKm),
                    label: 'Pace Live',
                    isDark: isDark,
                  ),
                  _StatBox(
                    emoji: '⏱️',
                    value: _formatPace(provider.averagePaceMinPerKm),
                    label: 'Pace Avg',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(
                    emoji: '👟',
                    value: '${provider.activeEstimatedSteps}',
                    label: 'Langkah',
                    isDark: isDark,
                  ),
                  _StatBox(
                    emoji: '🔥',
                    value: '${provider.activeCalories} kkal',
                    label: 'Kalori',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),

              // Control Buttons: Jeda / Lanjut & Selesai
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.isPaused ? _resumeTracking : _pauseTracking,
                      icon: Icon(
                        provider.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        size: 22,
                      ),
                      label: Text(
                        provider.isPaused ? 'Lanjut' : 'Jeda',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        foregroundColor: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopTracking,
                      icon: const Icon(Icons.stop_rounded, size: 22),
                      label: const Text(
                        'Selesai',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}

// ─── Google Maps User Pointer with Live Heading & Navigation Cone ──────────────
class _GoogleMapsUserPointer extends StatefulWidget {
  final Color color;
  final double heading;
  const _GoogleMapsUserPointer({
    required this.color,
    this.heading = 0.0,
  });

  @override
  State<_GoogleMapsUserPointer> createState() => _GoogleMapsUserPointerState();
}

class _GoogleMapsUserPointerState extends State<_GoogleMapsUserPointer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat();
    _pulse = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeHeading = (widget.heading.isNaN || widget.heading.isInfinite)
        ? 0.0
        : widget.heading;
    final double radHeading = safeHeading * math.pi / 180;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Directional sight cone / beam (Google Maps signature navigation beam)
            Transform.rotate(
              angle: radHeading,
              child: const CustomPaint(
                size: Size(64, 64),
                painter: _DirectionBeamPainter(beamColor: Color(0xFF1A73E8)),
              ),
            ),
            // Pulsing accuracy halo
            Opacity(
              opacity: (1 - _pulse.value).clamp(0.0, 1.0) * 0.75,
              child: Container(
                width: 54 * _pulse.value,
                height: 54 * _pulse.value,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Accuracy ring
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
            ),
            // Central Navigation Pin with heading arrow
            Transform.rotate(
              angle: radHeading,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x661A73E8),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.navigation_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DirectionBeamPainter extends CustomPainter {
  final Color beamColor;
  const _DirectionBeamPainter({required this.beamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();
    const beamAngle = 35 * math.pi / 180;
    const beamLength = 30.0;

    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: beamLength),
      -math.pi / 2 - beamAngle,
      beamAngle * 2,
      false,
    );
    path.close();

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.85,
      colors: [
        beamColor.withValues(alpha: 0.4),
        beamColor.withValues(alpha: 0.0),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: beamLength))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DirectionBeamPainter oldDelegate) => false;
}

// ─── Stat Box ──────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final bool isDark;
  const _StatBox(
      {required this.emoji,
      required this.value,
      required this.label,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

// ─── Result Row ────────────────────────────────────────────────────────────────
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Water Tab (Animated Fluid & Rising Bubbles) ───────────────────────────────
class _WaterTab extends StatefulWidget {
  const _WaterTab();

  @override
  State<_WaterTab> createState() => _WaterTabState();
}

class _WaterTabState extends State<_WaterTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final consumed = provider.waterGlasses;
    final target = provider.waterTarget > 0 ? provider.waterTarget : 8;
    final progress = (consumed / target).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final consumedLiters = consumed * 0.25;
    final targetLiters = target * 0.25;

    String hydLevel;
    Color hydColor;
    if (progress < 0.35) {
      hydLevel = 'Butuh Minum Air';
      hydColor = const Color(0xFFEF4444);
    } else if (progress < 0.65) {
      hydLevel = 'Cukup Terhidrasi';
      hydColor = const Color(0xFFF59E0B);
    } else if (progress < 0.90) {
      hydLevel = 'Terhidrasi Baik';
      hydColor = const Color(0xFF10B981);
    } else {
      hydLevel = 'Sangat Terhidrasi';
      hydColor = const Color(0xFF0284C7);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ActivityProvider>().refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ── Speech Bubble Nubi (Image 3) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Image.asset(
                    'assets/images/maskot_nubi_drink.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.water_drop_rounded,
                        color: Color(0xFF0284C7),
                        size: 36),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0)),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Text(
                      'Yuk minum air! Tubuh butuh hidrasi agar tetap segar dan sehat. 💧',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Water Glass Card with Dynamic Waves & Floating Bubbles ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  // Animated Glass Graphic with smooth fill transition
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeInOutCubic,
                    builder: (context, animatedFill, _) {
                      return AnimatedBuilder(
                        animation: _waveCtrl,
                        builder: (_, __) {
                          return SizedBox(
                            width: 140,
                            height: 210,
                            child: CustomPaint(
                              painter: _WaterGlassPainter(
                                fillProgress: animatedFill,
                                wavePhase: _waveCtrl.value * 2 * math.pi,
                                bubbleProgress: _waveCtrl.value,
                                waterColor: const Color(0xFF0284C7),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Liters Number
                  Text(
                    '${consumedLiters.toStringAsFixed(2)} L',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                      color: Color(0xFF0284C7),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'dari ${targetLiters.toStringAsFixed(1)} L (~$target gelas)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: hydColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: hydColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: hydColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          hydLevel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: hydColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Quick Add / Remove Controls ──
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: consumed > 0
                        ? () => context.read<ActivityProvider>().removeWater()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      foregroundColor:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('− 250 ml',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final ap = context.read<ActivityProvider>();
                      if (!ap.canDrinkWaterNow) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Mode puasa aktif: catat minum saat waktu berbuka/sahur.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      ap.addWater();
                    },
                    icon: const Icon(Icons.water_drop_rounded, size: 20),
                    label: const Text('+ 250 ml (1 Gelas)',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () {
                      final ap = context.read<ActivityProvider>();
                      if (!ap.canDrinkWaterNow) return;
                      ap.addWater();
                      ap.addWater();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF0C4A6E)
                          : const Color(0xFFE0F2FE),
                      foregroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('+ 500 ml',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  final double fillProgress;
  final double wavePhase;
  final double bubbleProgress;
  final Color waterColor;

  const _WaterGlassPainter({
    required this.fillProgress,
    this.wavePhase = 0.0,
    this.bubbleProgress = 0.0,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glass outline path
    final glassPath = Path();
    glassPath.moveTo(w * 0.12, 0);
    glassPath.lineTo(w * 0.88, 0);
    glassPath.lineTo(w * 0.80, h * 0.92);
    glassPath.quadraticBezierTo(w * 0.78, h, w * 0.65, h);
    glassPath.lineTo(w * 0.35, h);
    glassPath.quadraticBezierTo(w * 0.22, h, w * 0.20, h * 0.92);
    glassPath.close();

    // Clip to glass interior
    canvas.save();
    canvas.clipPath(glassPath);

    // Glass interior backdrop
    final bgPaint = Paint()
      ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.30);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Dynamic Wave Fluid
    final waterHeight = h * fillProgress.clamp(0.0, 1.0);
    final waterTop = h - waterHeight;

    if (waterHeight > 0) {
      final waterPath = Path();
      waterPath.moveTo(0, waterTop);

      // Oscillating sine wave surface
      final waveAmp = (fillProgress >= 0.98 || fillProgress <= 0.02) ? 1.5 : 4.2;
      for (double x = 0; x <= w; x += 3) {
        final y = waterTop + math.sin((x / w * 2 * math.pi) + wavePhase) * waveAmp;
        waterPath.lineTo(x, y);
      }
      waterPath.lineTo(w, h);
      waterPath.lineTo(0, h);
      waterPath.close();

      const waterGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
          Color(0xFF0369A1),
        ],
      );
      final waterPaint = Paint()
        ..shader = waterGradient
            .createShader(Rect.fromLTWH(0, waterTop - 5, w, waterHeight + 10))
        ..style = PaintingStyle.fill;
      canvas.drawPath(waterPath, waterPaint);

      // Glowing surface ripple highlight
      final surfacePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final surfaceLine = Path();
      surfaceLine.moveTo(0, waterTop);
      for (double x = 0; x <= w; x += 3) {
        final y = waterTop + math.sin((x / w * 2 * math.pi) + wavePhase) * waveAmp;
        surfaceLine.lineTo(x, y);
      }
      canvas.drawPath(surfaceLine, surfacePaint);

      // Continuous animated floating bubbles
      final bubbleList = [
        (0.30, 0.70, 3.2, 1.0),
        (0.55, 0.45, 4.0, 1.2),
        (0.42, 0.85, 2.5, 0.8),
        (0.70, 0.60, 3.6, 1.4),
        (0.35, 0.30, 2.8, 0.9),
        (0.65, 0.75, 3.0, 1.1),
      ];

      for (int i = 0; i < bubbleList.length; i++) {
        final b = bubbleList[i];
        final speedFactor = b.$4;
        // Travel upwards towards waterTop
        final travel = ((bubbleProgress * speedFactor + b.$2) % 1.0);
        final bY = waterTop + (waterHeight * (1.0 - travel));
        final bX = (w * b.$1) + math.sin(travel * 3 * math.pi + i) * 3;
        final bRadius = b.$3;

        // Bubble fade near surface
        final alpha = (travel < 0.85 ? 0.35 : (1.0 - travel) * 2.3).clamp(0.0, 0.4);
        final bPaint = Paint()..color = Colors.white.withValues(alpha: alpha);
        canvas.drawCircle(Offset(bX, bY), bRadius, bPaint);

        // Tiny white reflection dot
        final shinePaint = Paint()..color = Colors.white.withValues(alpha: alpha * 1.5);
        canvas.drawCircle(Offset(bX - 0.8, bY - 0.8), bRadius * 0.35, shinePaint);
      }
    }

    // Glass reflection highlights (curved glass look)
    final reflectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final reflexPath = Path();
    reflexPath.moveTo(w * 0.18, h * 0.08);
    reflexPath.lineTo(w * 0.26, h * 0.08);
    reflexPath.lineTo(w * 0.28, h * 0.84);
    reflexPath.lineTo(w * 0.22, h * 0.84);
    reflexPath.close();
    canvas.drawPath(reflexPath, reflectionPaint);

    canvas.restore();

    // Glass border stroke
    final borderPaint = Paint()
      ..color = const Color(0xFFBAE6FD)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(glassPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterGlassPainter oldDelegate) =>
      oldDelegate.fillProgress != fillProgress ||
      oldDelegate.wavePhase != wavePhase ||
      oldDelegate.bubbleProgress != bubbleProgress ||
      oldDelegate.waterColor != waterColor;
}

// ─── Nutrition Summary Card ─────────────────────────────────────────────────────
class _NutritionSummaryCard extends StatelessWidget {
  final List<FoodLog> logs;
  final Color primaryColor;
  const _NutritionSummaryCard({required this.logs, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double totalProtein = 0, totalCarbs = 0, totalFat = 0;
    double totalFiber = 0, totalSugar = 0;
    int totalCalories = 0, totalCaffeine = 0;
    for (final log in logs) {
      totalCalories += log.calories;
      totalProtein  += log.protein;
      totalCarbs    += log.carbs;
      totalFat      += log.fat;
      totalFiber    += log.fiber;
      totalSugar    += log.sugarGrams;
      totalCaffeine += log.caffeineMg;
    }
    final calorieTarget = context.watch<ActivityProvider>().calorieTarget;
    final progress = calorieTarget > 0
        ? (totalCalories / calorieTarget).clamp(0.0, 1.0)
        : 0.0;
    final isOver = totalCalories > calorieTarget && calorieTarget > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOver
                ? [Colors.red.withValues(alpha: 0.12), Colors.orange.withValues(alpha: 0.08)]
                : [primaryColor.withValues(alpha: 0.10), primaryColor.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOver
                ? Colors.orange.withValues(alpha: 0.4)
                : primaryColor.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ringkasan Nutrisi Hari Ini',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (isOver)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('⚠️ Over',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isOver ? Colors.orange : primaryColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCalories${calorieTarget > 0 ? " / $calorieTarget" : ""} kkal',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOver ? Colors.orange : primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MacroSummaryItem(label: 'Protein', value: '${totalProtein.toStringAsFixed(1)}g',  color: Colors.indigo,  emoji: '💪'),
                _MacroSummaryItem(label: 'Karbo',   value: '${totalCarbs.toStringAsFixed(1)}g',    color: Colors.orange,  emoji: '🌾'),
                _MacroSummaryItem(label: 'Lemak',   value: '${totalFat.toStringAsFixed(1)}g',      color: Colors.pink,    emoji: '🫐'),
                _MacroSummaryItem(label: 'Serat',   value: '${totalFiber.toStringAsFixed(1)}g',    color: Colors.teal,    emoji: '🥦'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MacroSummaryItem(label: 'Gula',   value: '${totalSugar.toStringAsFixed(1)}g', color: Colors.purple, emoji: '🍬'),
                _MacroSummaryItem(label: 'Kafein', value: '${totalCaffeine}mg',                 color: Colors.brown,  emoji: '☕'),
                _MacroSummaryItem(label: 'Porsi',  value: '${logs.length}x',                   color: Colors.green,  emoji: '🍱'),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String emoji;
  const _MacroSummaryItem(
      {required this.label, required this.value, required this.color, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }
}

// ─── Inline Macro Badge ─────────────────────────────────────────────────────────
class _InlineMacro extends StatelessWidget {
  final String text;
  final Color color;
  const _InlineMacro(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Food Log Card ───────────────────────────────────────────────────────────────
class _FoodLogCard extends StatelessWidget {
  final FoodLog log;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FoodLogCard({
    required this.log,
    required this.primaryColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = log.photoPath != null && log.photoPath!.isNotEmpty;

    return Dismissible(
      key: ValueKey('${log.foodName}_${log.time}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.redAccent),
            SizedBox(height: 4),
            Text('Hapus',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Food Photo or Emoji
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: hasPhoto ? Colors.transparent : primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: hasPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(log.photoPath!),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(log.emoji, style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(log.emoji, style: const TextStyle(fontSize: 26)),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              log.foodName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasPhoto)
                            Icon(
                              Icons.photo_camera,
                              size: 14,
                              color: primaryColor.withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('⏰ ${log.time}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color)),
                          if (log.mealType != 'camilan') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getMealLabel(log.mealType),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (log.protein > 0 || log.carbs > 0 || log.fat > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (log.protein > 0)
                              _InlineMacro('💪 ${log.protein.toStringAsFixed(0)}g', Colors.indigo),
                            if (log.carbs > 0) ...[
                              const SizedBox(width: 6),
                              _InlineMacro('🌾 ${log.carbs.toStringAsFixed(0)}g', Colors.orange),
                            ],
                            if (log.fat > 0) ...[
                              const SizedBox(width: 6),
                              _InlineMacro('🫐 ${log.fat.toStringAsFixed(0)}g', Colors.pink),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${log.calories}',
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          fontFamily: 'Poppins'),
                    ),
                    Text('kkal',
                        style: TextStyle(
                            color: primaryColor.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMealLabel(String mealType) {
    switch (mealType) {
      case 'sarapan': return '🍳';
      case 'makan_siang': return '🍗';
      case 'makan_malam': return '🌙';
      default: return '🍪';
    }
  }
}

// ─── Food Log Tab ──────────────────────────────────────────────────────────────
class _FoodLogTab extends StatelessWidget {
  const _FoodLogTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final logs = provider.foodLogs;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return RefreshIndicator(
      onRefresh: () => context.read<ActivityProvider>().refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Header Row ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🍽️ Log Makanan',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                        color: Theme.of(context).textTheme.titleLarge?.color),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/food-scan'),
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Manual Entry Link ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: TextButton.icon(
                onPressed: () => _showManualEntryDialog(context),
                icon: Icon(Icons.edit_note, size: 18, color: primaryColor),
                label: Text('Catat Manual',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          // ── Nutrition Summary ──
          SliverToBoxAdapter(
            child: _NutritionSummaryCard(logs: logs, primaryColor: primaryColor),
          ),
          // ── Empty State or List ──
          if (logs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍽️', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada log makanan hari ini',
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/food-scan'),
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text('Scan Makanan'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showManualEntryDialog(context),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Catat Manual'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final log = logs[i];
                    return _FoodLogCard(
                      log: log,
                      primaryColor: primaryColor,
                      onTap: () => _showFoodDetail(context, log),
                      onDelete: () => _confirmDeleteDialog(context, log),
                    );
                  },
                  childCount: logs.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<void> _showManualEntryDialog(BuildContext context) async {
    final nameCtrl    = TextEditingController();
    final calCtrl     = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbCtrl    = TextEditingController();
    final fatCtrl     = TextEditingController();
    String selectedEmoji = '🍽️';
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const emojis = ['🍽️','🍚','🍗','🥗','🍜','🍔','🥤','🍎','🥛','🍌','🥩','🍕','🧋','🍩','🍱'];

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).padding.bottom +
                  16,
              left: 24, right: 24, top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).dividerColor,
                        borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('✏️ Catat Makanan Manual',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                          color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 16),
                  Text('Pilih Ikon',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: emojis.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final e = emojis[i];
                        final selected = e == selectedEmoji;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedEmoji = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: selected
                                  ? primaryColor.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? primaryColor
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nama Makanan / Minuman *',
                      hintText: 'Contoh: Nasi Goreng, Kopi Susu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: calCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kalori (kkal) *',
                      hintText: 'Contoh: 350',
                      suffixText: 'kkal',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Nutrisi (opsional)',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: proteinCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Protein (g)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: carbCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Karbo (g)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: fatCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Lemak (g)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final cal  = int.tryParse(calCtrl.text.trim()) ?? 0;
                        if (name.isEmpty || cal <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Isi nama makanan dan kalori terlebih dahulu.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        final protein = double.tryParse(proteinCtrl.text.trim()) ?? 0.0;
                        final carbs   = double.tryParse(carbCtrl.text.trim()) ?? 0.0;
                        final fat     = double.tryParse(fatCtrl.text.trim()) ?? 0.0;
                        final ap = ctx.read<ActivityProvider>();
                        final ok = ap.addFoodLog(name, cal,
                            emoji: selectedEmoji, protein: protein, carbs: carbs, fat: fat);
                        if (ok) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('✅ $name ($cal kkal) berhasil dicatat!'),
                            backgroundColor: Colors.green,
                          ));
                        }
                      },
                      child: const Text('✅ Simpan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _confirmDeleteDialog(BuildContext context, FoodLog log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Log?'),
        content: Text('Hapus "${log.foodName}" (${log.calories} kkal) dari log hari ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<ActivityProvider>().removeFoodLog(log);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showFoodDetail(BuildContext context, FoodLog log) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      log.emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      log.foodName,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${log.calories} kcal',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Informasi Nutrisi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMacroBox('${log.protein.toStringAsFixed(1)}g',
                          'Protein', Colors.indigo),
                      const SizedBox(width: 8),
                      _buildMacroBox('${log.carbs.toStringAsFixed(1)}g',
                          'Karbo', Colors.orange),
                      const SizedBox(width: 8),
                      _buildMacroBox('${log.fat.toStringAsFixed(1)}g', 'Lemak',
                          Colors.pink),
                      const SizedBox(width: 8),
                      _buildMacroBox('${log.fiber.toStringAsFixed(1)}g',
                          'Serat', Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE0F2FE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 24, color: isDark ? Colors.lightBlueAccent : Colors.blue[800]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detail & Waktu Konsumsi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.lightBlueAccent
                                      : Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailTextRow(context, 'Waktu', log.time),
                              _buildDetailTextRow(
                                  context, 'Gula', '${log.sugarGrams}g'),
                              _buildDetailTextRow(
                                  context, 'Kafein', '${log.caffeineMg}mg'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMacroBox(String value, String label, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color[700],
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color[800],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTextRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.8))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}
