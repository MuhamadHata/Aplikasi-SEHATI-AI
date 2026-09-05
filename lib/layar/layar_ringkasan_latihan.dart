import 'package:flutter/material.dart';
import '''../../inti/tema/ikon_mapper.dart''';
import 'package:provider/provider.dart';
import '../../inti/model/catatan_aktivitas.dart';
import '../../penyedia/penyedia_aktivitas.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> workoutData;
  final int totalDurationSeconds;
  final List<ExerciseSetRecord> sessionHistory;
  final double totalCalories;

  const WorkoutSummaryScreen({
    super.key,
    required this.workoutData,
    required this.totalDurationSeconds,
    this.sessionHistory = const [],
    this.totalCalories = 0.0,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  String _selectedFeeling = 'Pas';

  int _parseCalories(dynamic cal) {
    if (cal == null) return 0;
    if (cal is num) return cal.toInt();
    if (cal is String) return double.tryParse(cal)?.toInt() ?? 0;
    return 0;
  }

  void _finishAndSave() {
    final provider = context.read<ActivityProvider>();
    // Use MET-calculated calories if available, otherwise fall back to AI estimate
    final cal = widget.totalCalories > 0
        ? widget.totalCalories.round()
        : _parseCalories(widget.workoutData['caloriesBurned']);
    final session = ActivityRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'Latihan AI',
      date: DateTime.now(),
      durationSeconds: widget.totalDurationSeconds,
      distanceKm: 0.0,
      calories: cal,
      steps: 0,
      averagePace: 0.0,
      route: [],
    );
    provider.saveActivitySession(session);
    Navigator.of(context)
        .popUntil((route) => route.settings.name == '/home' || route.isFirst);
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '00:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final bgColor = theme.scaffoldBackgroundColor;

    final int exerciseCount =
        (widget.workoutData['exercises'] as List?)?.length ?? 0;
    final double calories = widget.totalCalories > 0
        ? widget.totalCalories
        : _parseCalories(widget.workoutData['caloriesBurned']).toDouble();
    final String timeStr = _formatDuration(widget.totalDurationSeconds);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primary.withValues(alpha: 0.15),
                          bgColor,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.fitness_center_rounded,
                          size: 100, color: primary.withValues(alpha: 0.15)),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(Icons.share_outlined, color: onSurface),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Share screenshot...')));
                      },
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 40,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bagus! Latihan\nAnda selesai!',
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w900,
                            color: onSurface,
                            height: 1.2,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.workoutData['title'] ??
                              'Program Latihan SEHATI-AI',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetricCol(
                            context, 'Latihan', exerciseCount.toString()),
                        _buildMetricCol(
                            context, 'Kalori', calories.toStringAsFixed(1)),
                        _buildMetricCol(context, 'Waktu', timeStr),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bagaimana perasaan Anda',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukan Anda akan membantu kami memberikan latihan yang lebih cocok untuk Anda',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeelingOption(context, 'Terlalu sulit', '😖',
                            Colors.red.withValues(alpha: 0.2)),
                        _buildFeelingOption(context, 'Pas', '😀', Colors.amber),
                        _buildFeelingOption(context, 'Terlalu mudah', '😌',
                            Colors.blue.withValues(alpha: 0.2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── Set History ──────────────────────────────────────────────
            if (widget.sessionHistory.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'History Set',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.sessionHistory.length} set',
                              style: TextStyle(
                                  color: primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Group sets by exercise
                      ...() {
                        // Build grouped list
                        final Map<String, List<ExerciseSetRecord>> grouped = {};
                        for (final s in widget.sessionHistory) {
                          final key = s.exerciseName;
                          grouped.putIfAbsent(key, () => []).add(s);
                        }
                        return grouped.entries.map((entry) {
                          final exSets = entry.value;
                          final nameId = exSets.first.exerciseNameId.isNotEmpty
                              ? exSets.first.exerciseNameId
                              : entry.key;
                          final totalCal = exSets.fold<double>(
                              0, (sum, s) => sum + s.caloriesBurned);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: theme.dividerColor
                                      .withValues(alpha: 0.12)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nameId,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: onSurface,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '≈ ${totalCal.toStringAsFixed(1)} kal',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFFF6B35),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: exSets.map((s) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34D399)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded,
                                              size: 12,
                                              color: Color(0xFF34D399)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Set ${s.setNumber}: ${s.displayMetric}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF34D399),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      }(),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: ElevatedButton(
            onPressed: _finishAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Lanjut',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 27,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildFeelingOption(
      BuildContext context, String label, String emoji, Color iconColor) {
    final theme = Theme.of(context);
    final isSelected = _selectedFeeling == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFeeling = label),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected
                  ? iconColor
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : theme.dividerColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(IkonMapper.dariEmoji(emoji), size: 35, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.textTheme.bodyMedium?.color,
            ),
          )
        ],
      ),
    );
  }
}
