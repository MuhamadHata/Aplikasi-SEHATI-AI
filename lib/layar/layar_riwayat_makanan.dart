// ==========================================
// LAYARAN RIWAYAT MAKANAN
// Menampilkan history makanan dengan foto
// Mendukung filter dan continual learning
// ==========================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../inti/tema/design_tokens.dart';
import '../../inti/layanan/layanan_food_log.dart';
import '../../inti/model/model.dart';
import '../../penyedia/penyedia_aktivitas.dart';

class FoodHistoryScreen extends StatefulWidget {
  const FoodHistoryScreen({super.key});

  @override
  State<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String? _selectedMealFilter;
  bool _isLoading = true;
  List<FoodLogEntry> _foodLogs = [];
  Map<String, List<FoodLogEntry>> _groupedLogs = {};

  static const Map<String, String> _mealLabels = {
    'semua': 'Semua',
    'sarapan': '🍳 Sarapan',
    'makan_siang': '🍗 Makan Siang',
    'makan_malam': '🌙 Makan Malam',
    'camilan': '🍪 Camilan',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await FoodLogService.instance.getFoodLogs(
        startDate: _selectedDate,
        endDate: _selectedDate.add(const Duration(days: 1)),
        mealType: _selectedMealFilter == 'semua' ? null : _selectedMealFilter,
        limit: 100,
      );

      final grouped = <String, List<FoodLogEntry>>{
        'sarapan': [],
        'makan_siang': [],
        'makan_malam': [],
        'camilan': [],
      };

      for (final log in logs) {
        final meal = log.meal.toLowerCase();
        if (grouped.containsKey(meal)) {
          grouped[meal]!.add(log);
        } else {
          grouped['camilan']!.add(log);
        }
      }

      setState(() {
        _foodLogs = logs;
        _groupedLogs = grouped;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading food logs: $e');
      setState(() => _isLoading = false);
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadLogs();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Filter Makanan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _mealLabels.entries.map((entry) {
                    final isSelected = _selectedMealFilter == entry.key;
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedMealFilter = selected ? entry.key : 'semua';
                        });
                        Navigator.pop(ctx);
                        _loadLogs();
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Hari Ini';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Kemarin';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _calculateTotalCalories(List<FoodLogEntry> logs) {
    return logs.fold(0, (sum, log) => sum + log.cal);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalCal = _calculateTotalCalories(_foodLogs);
    final provider = context.watch<ActivityProvider>();
    final calorieTarget = provider.calorieTarget;
    final remaining = calorieTarget > 0 ? calorieTarget - totalCal : 0;
    final progress = calorieTarget > 0 ? (totalCal / calorieTarget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Makanan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Dataset Foto',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _FoodDatasetGallery(),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                tabs: const [
                  Tab(text: '📅 Harian'),
                  Tab(text: '📊 Ringkasan'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Date Selector & Calorie Summary ──────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Date Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => _changeDate(-1),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                          _loadLogs();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _selectedDate.day >= DateTime.now().day
                          ? null
                          : () => _changeDate(1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Calorie Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Kalori',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '$totalCal kkal',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Sisa',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '$remaining kkal',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: remaining >= 0
                                      ? const Color(0xFF10B981)
                                      : Colors.red,
                                ),
                              ),
                            ],
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
                          valueColor: AlwaysStoppedAnimation(
                            progress < 1.0
                                ? AppColors.primary
                                : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Target: $calorieTarget kkal',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Meal Type Filter Chips ────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _mealLabels.entries.map((entry) {
                final isSelected = _selectedMealFilter == entry.key ||
                    (_selectedMealFilter == null && entry.key == 'semua');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMealFilter = selected ? entry.key : 'semua';
                      });
                      _loadLogs();
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Food Logs List ────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _foodLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_outlined,
                              size: 64,
                              color: theme.hintColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada makanan yang dicatat',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan makanan untuk mencatat',
                              style: TextStyle(
                                color: theme.hintColor.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab Harian - List by meal type
                          _buildMealTypeList(theme, isDark),
                          // Tab Ringkasan - Stats overview
                          _buildSummaryView(theme, isDark),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeList(ThemeData theme, bool isDark) {
    final mealIcons = {
      'sarapan': '🍳',
      'makan_siang': '🍗',
      'makan_malam': '🌙',
      'camilan': '🍪',
    };

    final mealNames = {
      'sarapan': 'Sarapan',
      'makan_siang': 'Makan Siang',
      'makan_malam': 'Makan Malam',
      'camilan': 'Camilan',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _groupedLogs.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) {
        final mealType = entry.key;
        final logs = entry.value;
        final mealCal = _calculateTotalCalories(logs);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark
                        ? Colors.white
                        : Colors.black)
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        mealIcons[mealType] ?? '🍽️',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mealNames[mealType] ?? mealType,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$mealCal kkal',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Food Items
            ...logs.map((log) => _buildFoodItemCard(log, theme, isDark)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFoodItemCard(FoodLogEntry log, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => _showFoodDetail(log),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Food Photo
              if (log.photoPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(log.photoPath!),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(log.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(log.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              const SizedBox(width: 12),

              // Food Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (log.serving != null)
                      Text(
                        log.serving!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    if (log.ingredients != null && log.ingredients!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          log.ingredients!.take(3).join(', '),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Calories
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${log.cal}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'kkal',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    log.time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryView(ThemeData theme, bool isDark) {
    final totalProtein = _foodLogs.fold<double>(0, (sum, log) => sum + (log.protein ?? 0));
    final totalCarbs = _foodLogs.fold<double>(0, (sum, log) => sum + (log.carbs ?? 0));
    final totalFat = _foodLogs.fold<double>(0, (sum, log) => sum + (log.fat ?? 0));
    final totalFiber = _foodLogs.fold<double>(0, (sum, log) => sum + (log.fiber ?? 0));
    final totalSugar = _foodLogs.fold<double>(0, (sum, log) => sum + (log.sugarGrams ?? 0));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Nutrition Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Ringkasan Nutrisi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _buildNutritionRow('💪 Protein', totalProtein, 'g', Colors.red),
              _buildNutritionRow('🌾 Karbohidrat', totalCarbs, 'g', Colors.orange),
              _buildNutritionRow('🥑 Lemak', totalFat, 'g', Colors.yellow.shade700),
              _buildNutritionRow('🌿 Serat', totalFiber, 'g', Colors.green),
              _buildNutritionRow('🍬 Gula', totalSugar, 'g', Colors.pink),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dataset Contribution Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🤖', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dataset AI',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${_foodLogs.length} foto makanan tersimpan untuk pembelajaran AI',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final dataset = await FoodLogService.instance.exportTrainingDataset();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dataset siap: ${dataset.length} entri'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Dataset'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, double value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showFoodDetail(FoodLogEntry log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Photo
                    if (log.photoPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(log.photoPath!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Name & Emoji
                    Row(
                      children: [
                        Text(log.emoji, style: const TextStyle(fontSize: 40)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (log.category != null)
                                Text(
                                  log.category!,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Serving & Time
                    if (log.serving != null)
                      _buildDetailRow('🍽️', 'Porsi', log.serving!),
                    _buildDetailRow('⏰', 'Waktu', log.time),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Nutrition
                    const Text(
                      '📊 Informasi Nutrisi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNutritionCard(log),

                    // Ingredients
                    if (log.ingredients != null && log.ingredients!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        '🧾 Bahan-bahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: log.ingredients!.map((ing) {
                          return Chip(
                            label: Text(ing, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildDetailRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(FoodLogEntry log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildNutrientRow('🔥 Kalori', '${log.cal}', 'kkal', Colors.red),
          _buildNutrientRow('💪 Protein', '${log.protein?.toStringAsFixed(1) ?? '-'}', 'g', Colors.orange),
          _buildNutrientRow('🌾 Karbohidrat', '${log.carbs?.toStringAsFixed(1) ?? '-'}', 'g', Colors.amber),
          _buildNutrientRow('🥑 Lemak', '${log.fat?.toStringAsFixed(1) ?? '-'}', 'g', Colors.yellow.shade700),
          _buildNutrientRow('🌿 Serat', '${log.fiber?.toStringAsFixed(1) ?? '-'}', 'g', Colors.green),
          _buildNutrientRow('🍬 Gula', '${log.sugarGrams?.toStringAsFixed(1) ?? '-'}', 'g', Colors.pink),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Food Dataset Gallery ──────────────────────────────────────────────────────
// Menampilkan semua foto makanan yang tersimpan untuk continual learning
class _FoodDatasetGallery extends StatefulWidget {
  const _FoodDatasetGallery();

  @override
  State<_FoodDatasetGallery> createState() => _FoodDatasetGalleryState();
}

class _FoodDatasetGalleryState extends State<_FoodDatasetGallery> {
  List<FoodLogEntry> _logsWithPhotos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final logs = await FoodLogService.instance.getFoodLogs(limit: 200);
    final logsWithPhotos = logs.where((log) => log.photoPath != null).toList();
    setState(() {
      _logsWithPhotos = logsWithPhotos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Dataset Foto Makanan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logsWithPhotos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: theme.hintColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada foto makanan',
                        style: TextStyle(
                          color: theme.hintColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan makanan untuk menambahkan ke dataset',
                        style: TextStyle(
                          color: theme.hintColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _logsWithPhotos.length,
                  itemBuilder: (context, index) {
                    final log = _logsWithPhotos[index];
                    return GestureDetector(
                      onTap: () => _showPhotoDetail(log),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(log.photoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: Center(
                              child: Text(log.emoji, style: const TextStyle(fontSize: 32)),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showPhotoDetail(FoodLogEntry log) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.file(
                File(log.photoPath!),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${log.emoji} ${log.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('🔥 ${log.cal} kkal'),
                  Text('⏰ ${log.time}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
