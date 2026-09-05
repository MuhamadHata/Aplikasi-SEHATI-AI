import 'package:flutter/material.dart';
import '''../../inti/tema/ikon_mapper.dart''';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../penyedia/penyedia_aktivitas.dart';
import '../../inti/model/catatan_aktivitas.dart';
import 'layar_detail_aktivitas.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  int _selectedTab = 0; // 0: Daily, 1: All Records

  Map<String, List<ActivityRecord>> _groupByDate(List<ActivityRecord> history) {
    final Map<String, List<ActivityRecord>> grouped = {};
    for (final record in history) {
      final dateKey = DateFormat('yyyy-MM-dd', 'id_ID').format(record.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final history = provider.history;
    final groupedByDate = _groupByDate(history);

    // Merge dates from history, daily summaries, and today
    final allDatesSet = <String>{...groupedByDate.keys};
    for (final s in provider.dailySummaries) {
      allDatesSet.add(s.date);
    }
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (provider.steps > 0 ||
        provider.waterGlasses > 0 ||
        provider.calorieConsumed > 0 ||
        history.isNotEmpty) {
      allDatesSet.add(todayStr);
    }

    final sortedDates = allDatesSet.toList()..sort((a, b) => b.compareTo(a));
    final hasAnyData = sortedDates.isNotEmpty || history.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Riwayat Aktivitas',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ) ??
              const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
        ),
      ),
      body: !hasAnyData
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 42,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Belum Ada Riwayat Aktivitas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mulai bergerak, minum air, atau lakukan olahraga untuk mulai merekam progres harian Anda!',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Mulai Aktivitas',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Tab buttons
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Per Hari (${sortedDates.length})',
                          isActive: _selectedTab == 0,
                          onPressed: () => setState(() => _selectedTab = 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TabButton(
                          label: 'Semua Catatan (${history.length})',
                          isActive: _selectedTab == 1,
                          onPressed: () => setState(() => _selectedTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedTab == 0
                      ? ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedDates.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final dateKey = sortedDates[index];
                            final items = groupedByDate[dateKey] ?? [];
                            return _DailyCard(records: items, dateKey: dateKey);
                          },
                        )
                      : (history.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada catatan olahraga GPS tersimpan.',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: history.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final record = history[index];
                                return _HistoryCard(record: record);
                              },
                            )),
                ),
              ],
            ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatefulWidget {
  final List<ActivityRecord> records;
  final String dateKey;

  const _DailyCard({required this.records, required this.dateKey});

  @override
  State<_DailyCard> createState() => _DailyCardState();
}

class _DailyCardState extends State<_DailyCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate daily totals from records
    int totalStepsFromRecords = 0;
    int totalCaloriesBurned = 0;

    for (final record in widget.records) {
      totalStepsFromRecords += record.steps;
      totalCaloriesBurned += record.calories;
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = widget.dateKey == todayStr;

    int stepsAchieved = totalStepsFromRecords;
    int waterAchieved = 0;
    int caloriesConsumed = 0;
    List<FoodLog> displayFoodLogs = [];
    int stepTarget = provider.stepTarget;
    int waterTarget = provider.waterTarget;
    int calorieTarget = provider.calorieTarget;

    if (isToday) {
      stepsAchieved = provider.steps;
      waterAchieved = provider.waterGlasses;
      caloriesConsumed = provider.calorieConsumed;
      totalCaloriesBurned = provider.caloriesBurned;
      displayFoodLogs = provider.foodLogs;
    } else {
      // Find summary for this date
      final summary = provider.dailySummaries.firstWhere(
        (s) => s.date == widget.dateKey,
        orElse: () => DailySummary(
            date: widget.dateKey,
            caloriesConsumed: 0,
            caloriesBurned: totalCaloriesBurned,
            steps: stepsAchieved,
            waterGlasses: 0,
            foodLogs: []),
      );
      stepsAchieved = summary.steps;
      waterAchieved = summary.waterGlasses;
      caloriesConsumed = summary.caloriesConsumed;
      totalCaloriesBurned = summary.caloriesBurned;
      displayFoodLogs = summary.foodLogs;
    }

    final dateObj = DateTime.parse(widget.dateKey);
    final dayFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final dayStr = dayFormat.format(dateObj);

    SleepRecord? sleepRecord;
    for (final s in provider.sleepLogs) {
      if (s.date == widget.dateKey) {
        sleepRecord = s;
        break;
      }
    }

    int targetsMet = 0;
    if (stepTarget > 0 && stepsAchieved >= stepTarget) targetsMet++;
    if (waterTarget > 0 && waterAchieved >= waterTarget) targetsMet++;
    if (calorieTarget > 0 && caloriesConsumed > 0 && caloriesConsumed <= calorieTarget) {
      targetsMet++;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isToday ? 'Hari Ini' : dayStr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Poppins',
                                        color: isToday
                                            ? Theme.of(context).primaryColor
                                            : null,
                                      ),
                                ),
                                if (targetsMet > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.green.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '$targetsMet/3 Target',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.records.length} aktivitas olahraga • $waterAchieved/$waterTarget gelas air',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bars for Targets
                  _TargetProgressRow(
                    label: 'Langkah',
                    icon: '👟',
                    achieved: stepsAchieved,
                    target: stepTarget,
                    unit: 'langkah',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  _TargetProgressRow(
                    label: 'Air Minum',
                    icon: '💧',
                    achieved: waterAchieved,
                    target: waterTarget,
                    unit: 'gelas',
                    color: Colors.cyan,
                  ),
                  const SizedBox(height: 10),
                  _TargetProgressRow(
                    label: 'Kalori Masuk',
                    icon: '🔥',
                    achieved: caloriesConsumed,
                    target: calorieTarget,
                    unit: 'kkal',
                    color: Colors.orange,
                  ),

                  if (_isExpanded) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Exercises Section
                    const _SectionHeader(
                        title: 'Olahraga', icon: Icons.fitness_center_rounded),
                    const SizedBox(height: 10),
                    if (widget.records.isEmpty)
                      const _EmptySection(
                          text: 'Tidak ada aktivitas olahraga tercatat')
                    else
                      Column(
                        children: widget.records
                            .map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _DailyRecordRow(
                                      record: r, isDark: isDark),
                                ))
                            .toList(),
                      ),

                    const SizedBox(height: 18),

                    // Food Section
                    const _SectionHeader(
                        title: 'Makanan & Minuman',
                        icon: Icons.restaurant_rounded),
                    const SizedBox(height: 10),
                    if (displayFoodLogs.isNotEmpty)
                      Column(
                        children: displayFoodLogs
                            .map((f) => _FoodLogRow(log: f, isDark: isDark))
                            .toList(),
                      )
                    else if (caloriesConsumed > 0)
                      _SummaryRow(
                        label: 'Total Asupan Kalori',
                        value: '$caloriesConsumed kkal',
                        icon: '🍽️',
                        isDark: isDark,
                      )
                    else
                      const _EmptySection(
                          text: 'Tidak ada data makanan tercatat'),

                    const SizedBox(height: 18),

                    // Sleep Section
                    const _SectionHeader(
                        title: 'Tidur & Pemulihan',
                        icon: Icons.bedtime_rounded),
                    const SizedBox(height: 10),
                    if (sleepRecord != null)
                      _SummaryRow(
                        label: 'Durasi Tidur',
                        value:
                            '${sleepRecord.durationLabel} (${sleepRecord.bedtimeLabel} - ${sleepRecord.wakeLabel})',
                        icon: '🌙',
                        isDark: isDark,
                      )
                    else
                      const _EmptySection(
                          text: 'Tidak ada data tidur tercatat'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetProgressRow extends StatelessWidget {
  final String label;
  final String icon;
  final int achieved;
  final int target;
  final String unit;
  final Color color;

  const _TargetProgressRow({
    required this.label,
    required this.icon,
    required this.achieved,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (achieved / target).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '$icon $label',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${NumberFormat('#,###').format(achieved)} / ${NumberFormat('#,###').format(target)} $unit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: progress >= 1.0
                    ? Colors.green
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _FoodLogRow extends StatelessWidget {
  final FoodLog log;
  final bool isDark;

  const _FoodLogRow({required this.log, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.3)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(IkonMapper.dariEmoji(log.emoji), size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.foodName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  log.time,
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            '${log.calories} kkal',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.orange),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final bool isDark;

  const _SummaryRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.3)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
      ),
    );
  }
}



class _DailyRecordRow extends StatelessWidget {
  final ActivityRecord record;
  final bool isDark;

  const _DailyRecordRow({
    required this.record,
    required this.isDark,
  });

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm', 'id_ID').format(dt);
  }

  String _getActivityLabel(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('lari trail')) return '🌲 Trail';
    if (lower.contains('lari')) return '🏃 Lari';
    if (lower.contains('sepeda')) return '🚴 Sepeda';
    if (lower.contains('renang') || lower.contains('swim')) return '🏊 Renang';
    if (lower.contains('gym')) return '🏋️ Gym';
    if (lower.contains('yoga')) return '🧘 Yoga';
    if (lower.contains('zumba')) return '💃 Zumba';
    if (lower.contains('pilates')) return '🤸 Pilates';
    if (lower.contains('crossfit')) return '🔥 CrossFit';
    if (lower.contains('lompat tali') || lower.contains('skipping')) return '🪢 Skipping';
    if (lower.contains('badminton')) return '🏸 Badminton';
    if (lower.contains('tennis')) return '🎾 Tennis';
    if (lower.contains('basket')) return '🏀 Basket';
    if (lower.contains('futsal')) return '⚽ Futsal';
    if (lower.contains('hiking')) return '🥾 Hiking';
    return '🚶 $type';
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id_ID');
    final isDistance = record.distanceKm > 0;
    final statSubtitle = isDistance
        ? '${record.distanceKm.toStringAsFixed(2)} km • ${formatter.format(record.steps)} langkah'
        : '${(record.durationSeconds / 60).round()} menit durasi';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailScreen(activity: record),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.3)
                : const Color(0xFFF8FAFC),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(record.date),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      _getActivityLabel(record.type),
                      style: Theme.of(context).textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${formatter.format(record.calories)} kkal',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).dividerColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final ActivityRecord record;
  const _HistoryCard({required this.record});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareActivity() async {
    setState(() => _isSharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/activity_${widget.record.id}.png';
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath)],
          text: 'Cek aktivitas saya di SEHATI-AI App!',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membagikan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  String _getTimeOfDay(DateTime dt) {
    if (dt.hour >= 5 && dt.hour < 11) return 'Pagi';
    if (dt.hour >= 11 && dt.hour < 14) return 'Siang';
    if (dt.hour >= 14 && dt.hour < 18) return 'Sore';
    return 'Malam';
  }

  String _formatPace(double paceMinPerKm) {
    if (paceMinPerKm <= 0) return '-';
    int minutes = paceMinPerKm.floor();
    int seconds = ((paceMinPerKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMMM yyyy \'pukul\' HH.mm', 'id_ID');
    final dateStr = dateFormat.format(widget.record.date);
    final timeOfDay = _getTimeOfDay(widget.record.date);
    final isAI = widget.record.type == 'Latihan AI';
    final formatter = NumberFormat('#,###', 'id_ID');

    String title;
    if (isAI) {
      title = 'Latihan AI $timeOfDay';
    } else {
      title = '${widget.record.type} $timeOfDay';
    }

    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Avatar + Name/Date)
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Text('A',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 21)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anda',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      Text(
                        '$dateStr • SEHATI-AI App',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
            ),
            const SizedBox(height: 12),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isAI && widget.record.distanceKm > 0)
                  Expanded(
                      child: _HistoryStatCol('Jarak',
                          '${widget.record.distanceKm.toStringAsFixed(2)} km')),
                if (!isAI && widget.record.steps > 0)
                  Expanded(
                      child: _HistoryStatCol(
                          'Langkah', formatter.format(widget.record.steps))),
                if (!isAI && widget.record.averagePace > 0)
                  Expanded(
                      child: _HistoryStatCol(
                          'Pace', _formatPace(widget.record.averagePace))),
                if (isAI || widget.record.distanceKm == 0)
                  Expanded(
                      child: _HistoryStatCol('Durasi',
                          '${(widget.record.durationSeconds / 60).round()} min')),
                Expanded(
                    child: _HistoryStatCol('Kalori',
                        '${formatter.format(widget.record.calories)} kkal')),
              ],
            ),
            const SizedBox(height: 16),

            // Banner / Kudos replica (Hide when sharing to make cleaner receipt)
            if (!_isSharing)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFE8E7FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🌟', style: TextStyle(fontSize: 21)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aktivitas yang luar biasa!',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ActivityDetailScreen(activity: widget.record),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side:
                            BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                      ),
                      child: const Text('Detail',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _shareActivity,
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 0),
                      ),
                      child: const Text('Bagikan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Map View
            if (!isAI)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: widget.record.route.isNotEmpty
                      ? _RouteMapView(route: widget.record.route)
                      : Container(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          child: Center(
                            child: Icon(Icons.map_rounded,
                                color: Theme.of(context).dividerColor,
                                size: 40),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryStatCol extends StatelessWidget {
  final String label;
  final String value;
  const _HistoryStatCol(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
        ),
      ],
    );
  }
}

// ─── Route Map View (flutter_map / OpenStreetMap) ─────────────────────────────
class _RouteMapView extends StatelessWidget {
  final List<LatLng> route;
  const _RouteMapView({required this.route});

  @override
  Widget build(BuildContext context) {
    if (route.isEmpty) return const SizedBox.shrink();
    final center = route[route.length ~/ 2];
    return fm.FlutterMap(
      options: fm.MapOptions(
        initialCenter: center,
        initialZoom: 15,
        interactionOptions: const fm.InteractionOptions(
          flags: fm.InteractiveFlag.none,
        ),
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sehati.ai',
        ),
        if (route.length >= 2)
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                points: route,
                strokeWidth: 5,
                color: Colors.deepOrange,
                borderStrokeWidth: 1,
                borderColor: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        if (route.isNotEmpty)
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                point: route.first,
                width: 20,
                height: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (route.length >= 2)
                fm.Marker(
                  point: route.last,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
