// ─── layar_input_manual_makanan.dart ─────────────────────────────────────────
// Manual Food Search Screen — like Huawei Health food log
// Database: DatasetService (local JSON + Supabase)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../inti/tema/design_tokens.dart';
import 'package:provider/provider.dart';
import '../inti/layanan/layanan_dataset.dart';
import '../inti/tema/ikon_mapper.dart';
import '../penyedia/penyedia_aktivitas.dart';

class ManualFoodSearchScreen extends StatefulWidget {
  const ManualFoodSearchScreen({super.key});

  @override
  State<ManualFoodSearchScreen> createState() => _ManualFoodSearchScreenState();
}

class _ManualFoodSearchScreenState extends State<ManualFoodSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<_FoodEntry> _results = [];
  bool _loading = false;
  bool _initialized = false;

  static const List<_CategoryQuick> _quickCategories = [
    _CategoryQuick(emoji: '🍚', label: 'Nasi', query: 'nasi'),
    _CategoryQuick(emoji: '🍗', label: 'Ayam', query: 'ayam'),
    _CategoryQuick(emoji: '🥦', label: 'Sayur', query: 'sayur'),
    _CategoryQuick(emoji: '🍜', label: 'Mie', query: 'mie'),
    _CategoryQuick(emoji: '🥛', label: 'Susu', query: 'susu'),
    _CategoryQuick(emoji: '🍌', label: 'Buah', query: 'buah'),
    _CategoryQuick(emoji: '🍞', label: 'Roti', query: 'roti'),
    _CategoryQuick(emoji: '🥚', label: 'Telur', query: 'telur'),
    _CategoryQuick(emoji: '🥩', label: 'Daging', query: 'daging'),
    _CategoryQuick(emoji: '🫙', label: 'Tahu', query: 'tahu'),
  ];

  @override
  void initState() {
    super.initState();
    _initDataset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _initDataset() async {
    await DatasetService.instance.loadNutritionDataset();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    final names =
        await DatasetService.instance.search(q, maxResults: 30);
    final entries = <_FoodEntry>[];
    for (final name in names) {
      final data = await DatasetService.instance.findNutrition(name);
      if (data != null) {
        entries.add(_FoodEntry(
          name: (data['name'] as String?) ?? name,
          calories: (data['calories'] as num?)?.toInt() ?? 0,
          protein: (data['protein'] as num?)?.toDouble() ?? 0,
          carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
          fat: (data['fat'] as num?)?.toDouble() ?? 0,
          fiber: (data['fiber'] as num?)?.toDouble() ?? 0,
          sugarGrams: (data['sugar'] as num?)?.toDouble() ?? 0,
          category: (data['category'] as String?) ?? 'Umum',
          serving: (data['serving'] as String?) ?? '',
          emoji: _emojiForCategory((data['category'] as String?) ?? ''),
        ));
      }
    }
    if (mounted) {
      setState(() {
        _results = entries;
        _loading = false;
      });
    }
  }

  void _quickSearch(String q) {
    _searchCtrl.text = q;
    _onSearchChanged(q);
  }

  String _emojiForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('minuman')) return '🥤';
    if (c.contains('buah')) return '🍎';
    if (c.contains('sayur')) return '🥦';
    if (c.contains('daging') || c.contains('protein')) return '🥩';
    if (c.contains('nasi') || c.contains('karbohidrat') || c.contains('grain')) {
      return '🍚';
    }
    if (c.contains('kue') || c.contains('snack')) return '🍪';
    if (c.contains('seafood') || c.contains('ikan')) return '🐟';
    if (c.contains('telur')) return '🥚';
    if (c.contains('susu') || c.contains('dairy')) return '🥛';
    if (c.contains('mie') || c.contains('pasta')) return '🍜';
    return '🍽️';
  }

  void _openPortionDialog(_FoodEntry food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PortionSheet(food: food),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cari Makanan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? primary.withOpacity(0.25)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari makanan, contoh: nasi goreng...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color:
                              isDark ? Colors.white38 : const Color(0xFFCBD5E1),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() {
                          _results = [];
                          _loading = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.close_rounded,
                            size: 20,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: !_initialized
                ? Center(
                    child: CircularProgressIndicator(
                        color: primary, strokeWidth: 2.5))
                : _searchCtrl.text.trim().length < 2
                    ? _buildEmpty(isDark, primary)
                    : _loading
                        ? _buildLoadingList(isDark)
                        : _results.isEmpty
                            ? _buildNoResult(isDark)
                            : _buildResults(isDark, primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kategori Populer',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickCategories.map((cat) {
              return GestureDetector(
                onTap: () => _quickSearch(cat.query),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(IkonMapper.dariEmoji(cat.emoji), size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(cat.label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF334155))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Text('Tips Pencarian',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withOpacity(isDark ? 0.1 : 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withOpacity(0.2)),
            ),
            child: Text(
              'Ketik nama makanan untuk mencari dari database lebih dari 1.000 makanan Indonesia. Pilih makanan lalu masukkan porsi untuk menghitung kalori secara otomatis.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8,
      separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 14,
                        width: 140,
                        decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(7))),
                    const SizedBox(height: 6),
                    Container(
                        height: 11,
                        width: 80,
                        decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoResult(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white38 : Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Makanan tidak ditemukan',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? Colors.white70 : const Color(0xFF475569))),
          const SizedBox(height: 6),
          Text('Coba kata kunci lain atau nama yang lebih umum',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark, Color primary) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 58,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
      itemBuilder: (_, i) {
        final food = _results[i];
        return _FoodListTile(
          food: food,
          isDark: isDark,
          primary: primary,
          onTap: () => _openPortionDialog(food),
        );
      },
    );
  }
}

class _FoodListTile extends StatelessWidget {
  final _FoodEntry food;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const _FoodListTile({
    required this.food,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child:
                      Icon(IkonMapper.dariEmoji(food.emoji), size: 22, color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    food.calories > 0
                        ? '${food.calories} kkal / 100g'
                        : food.category,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_rounded, color: primary, size: 26),
          ],
        ),
      ),
    );
  }
}

class _PortionSheet extends StatefulWidget {
  final _FoodEntry food;
  const _PortionSheet({required this.food});

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  final TextEditingController _gramCtrl = TextEditingController(text: '100');
  double _grams = 100;
  String _mealType = 'Sarapan';

  static const List<String> _mealTypes = [
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Camilan'
  ];
  static const List<double> _quickPortions = [50, 100, 150, 200, 250, 300];

  double get _scaledCalories => widget.food.calories * _grams / 100;
  double get _scaledProtein => widget.food.protein * _grams / 100;
  double get _scaledCarbs => widget.food.carbs * _grams / 100;
  double get _scaledFat => widget.food.fat * _grams / 100;

  @override
  void dispose() {
    _gramCtrl.dispose();
    super.dispose();
  }

  void _updateGrams(String v) {
    final g = double.tryParse(v) ?? 0;
    setState(() => _grams = g.clamp(1, 2000));
  }

  void _log() {
    final ap = context.read<ActivityProvider>();
    final ok = ap.addFoodLog(
      widget.food.name,
      _scaledCalories.round(),
      emoji: widget.food.emoji,
      protein: _scaledProtein,
      carbs: _scaledCarbs,
      fat: _scaledFat,
      fiber: widget.food.fiber * _grams / 100,
      sugarGrams: widget.food.sugarGrams * _grams / 100,
      caffeineMg: 0,
    );

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gagal mencatat. Periksa mode puasa.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '✅ ${widget.food.name} (${_scaledCalories.round()} kkal) dicatat!'),
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 2),
    ));
    Navigator.of(context)
      ..pop()
      ..pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: Icon(IkonMapper.dariEmoji(widget.food.emoji), size: 28, color: Theme.of(context).colorScheme.primary)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.food.name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${widget.food.calories} kkal per 100g',
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Porsi Cepat (gram)',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF334155))),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickPortions.map((p) {
                    final sel = _grams == p;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _grams = p);
                        _gramCtrl.text = p.toStringAsFixed(0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel
                              ? primary
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel
                                  ? primary
                                  : (isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFE2E8F0))),
                        ),
                        child: Text('${p.toStringAsFixed(0)}g',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: sel
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF475569)))),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Atau masukkan gram',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF334155))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _gramCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _updateGrams,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: '100',
                    hintStyle: TextStyle(
                        color:
                            isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    suffix: Text('gram',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF94A3B8))),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withOpacity(isDark ? 0.15 : 0.08),
                      primary.withOpacity(isDark ? 0.05 : 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Kalori',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569))),
                        Text('${_scaledCalories.round()} kkal',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MacroItem(
                            label: 'Protein',
                            value: '${_scaledProtein.toStringAsFixed(1)}g',
                            color: const Color(0xFF3B82F6),
                            isDark: isDark),
                        _MacroItem(
                            label: 'Karbo',
                            value: '${_scaledCarbs.toStringAsFixed(1)}g',
                            color: const Color(0xFFF59E0B),
                            isDark: isDark),
                        _MacroItem(
                            label: 'Lemak',
                            value: '${_scaledFat.toStringAsFixed(1)}g',
                            color: const Color(0xFFEF4444),
                            isDark: isDark),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Jenis Makan',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF334155))),
              const SizedBox(height: 10),
              Row(
                children: _mealTypes.map((t) {
                  final sel = _mealType == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mealType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: sel
                              ? primary.withOpacity(0.15)
                              : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel
                                  ? primary
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                              width: sel ? 1.5 : 1),
                        ),
                        child: Text(
                          t == 'Makan Siang'
                              ? 'Siang'
                              : t == 'Makan Malam'
                                  ? 'Malam'
                                  : t,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: sel
                                  ? primary
                                  : (isDark
                                      ? Colors.white54
                                      : const Color(0xFF94A3B8))),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _grams > 0 ? _log : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Catat ${widget.food.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _MacroItem(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _FoodEntry {
  final String name;
  final int calories;
  final double protein, carbs, fat, fiber, sugarGrams;
  final String category, serving, emoji;

  const _FoodEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugarGrams,
    required this.category,
    required this.serving,
    required this.emoji,
  });
}

class _CategoryQuick {
  final String emoji, label, query;
  const _CategoryQuick(
      {required this.emoji, required this.label, required this.query});
}
