import 'package:flutter/material.dart';
import '../inti/tema/design_tokens.dart';
import '../inti/layanan/layanan_feedback_ai.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DialogKoreksiNutrisi — Bottom sheet untuk koreksi data nutrisi AI
//
// Fitur Enhanced:
// - Deteksi kuantitas (2 telur, 3 potong ayam)
// - Edit bahan makanan
// - Edit kategori
// - Serving size editor
//
// Ketika user mengoreksi data, koreksi ini menjadi "label" baru yang akan
// di-fine-tune ke model Gemini — pengetahuan tersimpan di BOBOT AI.
// ═══════════════════════════════════════════════════════════════════════════

/// Tampilkan dialog koreksi dan tunggu hasilnya.
/// Mengembalikan true jika koreksi berhasil dikirim, false jika dibatalkan.
Future<bool> tampilkanDialogKoreksiNutrisi(
  BuildContext context, {
  required String foodName,
  required Map<String, dynamic> aiPrediction,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DialogKoreksiNutrisi(
      foodName: foodName,
      aiPrediction: aiPrediction,
    ),
  );
  return result ?? false;
}

class _DialogKoreksiNutrisi extends StatefulWidget {
  final String foodName;
  final Map<String, dynamic> aiPrediction;

  const _DialogKoreksiNutrisi({
    required this.foodName,
    required this.aiPrediction,
  });

  @override
  State<_DialogKoreksiNutrisi> createState() => _DialogKoreksiNutrisiState();
}

class _DialogKoreksiNutrisiState extends State<_DialogKoreksiNutrisi>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _servingCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _calCtrl;
  late final TextEditingController _protCtrl;
  late final TextEditingController _carbCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _fiberCtrl;
  late final TextEditingController _sugarCtrl;
  late final TextEditingController _cafCtrl;
  late final TextEditingController _ingredientCtrl;

  String _selectedCategory = 'Umum';
  List<String> _ingredients = [];
  bool _sending = false;
  late TabController _tabController;

  static const List<String> _categories = [
    'Umum',
    'Minuman',
    'Buah',
    'Sayur',
    'Nasi & Karbohidrat',
    'Daging & Protein',
    'Seafood',
    'Telur',
    'Susu & Dairy',
    'Mie & Pasta',
    'Kue & Snack',
  ];

  static const List<String> _quantityPresets = [
    '1 potong',
    '2 potong',
    '3 potong',
    '1 piring',
    '2 piring',
    '1 porsi',
    '2 porsi',
    '1 gelas',
    '2 gelas',
    '1 buah',
    '2 buah',
    '3 buah',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final p = widget.aiPrediction;

    // Parse food name untuk extract quantity
    String name = p['name'] ?? widget.foodName;
    int quantity = 1;
    final quantityMatch = RegExp(r'^(\d+)').firstMatch(name);
    if (quantityMatch != null) {
      quantity = int.tryParse(quantityMatch.group(1) ?? '1') ?? 1;
      name = name.replaceFirst(RegExp(r'^\d+\s*'), '');
    }

    _nameCtrl = TextEditingController(text: name);
    _servingCtrl = TextEditingController(text: p['serving'] ?? '1 porsi');
    _quantityCtrl = TextEditingController(text: '$quantity');
    _calCtrl = TextEditingController(text: '${(p['calories'] as num?)?.toInt() ?? 0}');
    _protCtrl = TextEditingController(text: '${(p['protein'] as num?)?.toDouble() ?? 0.0}');
    _carbCtrl = TextEditingController(text: '${(p['carbs'] as num?)?.toDouble() ?? 0.0}');
    _fatCtrl = TextEditingController(text: '${(p['fat'] as num?)?.toDouble() ?? 0.0}');
    _fiberCtrl = TextEditingController(text: '${(p['fiber'] as num?)?.toDouble() ?? 0.0}');
    _sugarCtrl = TextEditingController(text: '${(p['sugarGrams'] as num?)?.toDouble() ?? 0.0}');
    _cafCtrl = TextEditingController(text: '${(p['caffeineMg'] as num?)?.toInt() ?? 0}');
    _ingredientCtrl = TextEditingController();

    // Parse category
    final category = p['category'] ?? 'Umum';
    if (_categories.contains(category)) {
      _selectedCategory = category;
    }

    // Parse ingredients
    final ingredientsData = p['ingredients'];
    if (ingredientsData is List) {
      _ingredients = List<String>.from(ingredientsData);
    } else if (ingredientsData is String) {
      _ingredients = ingredientsData.split(',').map((e) => e.trim()).toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingCtrl.dispose();
    _quantityCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _fiberCtrl.dispose();
    _sugarCtrl.dispose();
    _cafCtrl.dispose();
    _ingredientCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final ingredient = _ingredientCtrl.text.trim();
    if (ingredient.isNotEmpty && !_ingredients.contains(ingredient)) {
      setState(() {
        _ingredients.add(ingredient);
        _ingredientCtrl.clear();
      });
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
  }

  void _selectQuantityPreset(String preset) {
    setState(() {
      _quantityCtrl.text = preset;
    });
  }

  void _adjustQuantity(int delta) {
    final current = int.tryParse(_quantityCtrl.text) ?? 1;
    final newValue = (current + delta).clamp(1, 99);
    setState(() {
      _quantityCtrl.text = '$newValue';
    });
  }

  Map<String, dynamic> _buildCorrection() {
    final quantity = int.tryParse(_quantityCtrl.text) ?? 1;
    final name = _nameCtrl.text.trim();

    // Build full name dengan quantity
    String fullName = name;
    if (quantity > 1) {
      // Extract unit dari serving
      final serving = _servingCtrl.text.trim();
      final unitMatch = RegExp(r'^\d+\s*(\w+)').firstMatch(serving);
      final unit = unitMatch?.group(1) ?? 'porsi';
      fullName = '$quantity $unit $name';
    }

    return {
      'name': fullName,
      'originalName': name,
      'quantity': quantity,
      'serving': _servingCtrl.text.trim(),
      'calories': int.tryParse(_calCtrl.text) ?? 0,
      'protein': double.tryParse(_protCtrl.text) ?? 0.0,
      'carbs': double.tryParse(_carbCtrl.text) ?? 0.0,
      'fat': double.tryParse(_fatCtrl.text) ?? 0.0,
      'fiber': double.tryParse(_fiberCtrl.text) ?? 0.0,
      'sugarGrams': double.tryParse(_sugarCtrl.text) ?? 0.0,
      'caffeineMg': int.tryParse(_cafCtrl.text) ?? 0,
      'category': _selectedCategory,
      'ingredients': _ingredients,
    };
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final success = await AIFeedbackService.instance.submitCorrection(
      foodName: widget.foodName,
      aiPrediction: widget.aiPrediction,
      userCorrection: _buildCorrection(),
    );
    if (mounted) {
      setState(() => _sending = false);
      Navigator.pop(context, success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Drag handle ───────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🧠', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Koreksi Data Makanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'Perbaiki data AI untuk pembelajaran berkelanjutan',
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: onSurface.withValues(alpha: 0.6),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: '📝 Info'),
                  Tab(text: '🍽️ Porsi'),
                  Tab(text: '📊 Nutrisi'),
                ],
              ),
            ),

            // ── Tab Content ──────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Info Dasar
                  _buildInfoTab(ctrl, theme, onSurface),
                  // Tab 2: Porsi & Kuantitas
                  _buildPorsiTab(theme, onSurface),
                  // Tab 3: Nutrisi
                  _buildNutrisiTab(ctrl, theme),
                ],
              ),
            ),

            // ── Action buttons ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _sending ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🧠', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8),
                                Text(
                                  'Simpan Koreksi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: Info Dasar ──────────────────────────────────────────────────────
  Widget _buildInfoTab(ScrollController ctrl, ThemeData theme, Color onSurface) {
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      children: [
        // Nama Makanan
        _buildSectionTitle('Nama Makanan'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(
            'Contoh: Martabak Telur, Nasi Goreng',
            theme,
          ),
        ),
        const SizedBox(height: 20),

        // Kategori
        _buildSectionTitle('Kategori'),
        const SizedBox(height: 8),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              borderRadius: BorderRadius.circular(12),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Bahan Makanan
        _buildSectionTitle('Bahan Makanan'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ingredientCtrl,
                decoration: _inputDecoration('Tambah bahan...', theme),
                onFieldSubmitted: (_) => _addIngredient(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addIngredient,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ingredients.map((ing) {
            return Chip(
              label: Text(ing, style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeIngredient(ing),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            );
          }).toList(),
        ),
        if (_ingredients.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Contoh: Tepung, Telur, Minyak, Gula',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── Tab 2: Porsi & Kuantitas ──────────────────────────────────────────────
  Widget _buildPorsiTab(ThemeData theme, Color onSurface) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      children: [
        // Kuantitas Selector
        _buildSectionTitle('Jumlah Porsi / Kuantitas'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onPressed: () => _adjustQuantity(-1),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _quantityCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _QuantityButton(
                    icon: Icons.add,
                    onPressed: () => _adjustQuantity(1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Jumlah item/porsi makanan',
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick presets
        _buildSectionTitle('Preset Cepat'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quantityPresets.map((preset) {
            final isSelected = _quantityCtrl.text == preset;
            return InkWell(
              onTap: () => _selectQuantityPreset(preset),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : theme.dividerColor,
                  ),
                ),
                child: Text(
                  preset,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Serving Size
        _buildSectionTitle('Ukuran Porsi'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _servingCtrl,
          decoration: _inputDecoration(
            'Contoh: 1 piring (250g), 2 potong (100g)',
            theme,
          ),
        ),
        const SizedBox(height: 16),

        // Info kalori per porsi
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nutrisi yang diinput adalah untuk $_quantityCtrl.text porsi. '
                  'AI akan mengkalikan nilai ini dengan jumlah porsi.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Tab 3: Nutrisi ─────────────────────────────────────────────────────────
  Widget _buildNutrisiTab(ScrollController ctrl, ThemeData theme) {
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Text('⚡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Isi nilai nutrisi untuk 1 porsi makanan. '
                  'AI akan mengkalikan dengan jumlah porsi.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid nutrisi
        Row(
          children: [
            Expanded(
              child: _NutrisiField(
                label: '🔥 Kalori',
                controller: _calCtrl,
                unit: 'kkal',
                isInt: true,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NutrisiField(
                label: '💪 Protein',
                controller: _protCtrl,
                unit: 'g',
                theme: theme,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _NutrisiField(
                label: '🌾 Karbohidrat',
                controller: _carbCtrl,
                unit: 'g',
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NutrisiField(
                label: '🥑 Lemak',
                controller: _fatCtrl,
                unit: 'g',
                theme: theme,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _NutrisiField(
                label: '🌿 Serat',
                controller: _fiberCtrl,
                unit: 'g',
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NutrisiField(
                label: '🍬 Gula Total',
                controller: _sugarCtrl,
                unit: 'g',
                theme: theme,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _NutrisiField(
                label: '☕ Kafein',
                controller: _cafCtrl,
                unit: 'mg',
                isInt: true,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 8),

        // Gula info
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '💡 Gula = Gula tambahan + Gula alami. Teh manis ~30g, Nasi = 0g',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, ThemeData theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: theme.hintColor,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: theme.colorScheme.surface,
    );
  }
}

// ─── Quantity Button Widget ──────────────────────────────────────────────────
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }
}

// ─── Nutrisi Field Widget ────────────────────────────────────────────────────
class _NutrisiField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final bool isInt;
  final ThemeData theme;

  const _NutrisiField({
    required this.label,
    required this.controller,
    required this.unit,
    this.isInt = false,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(
              decimal: !isInt,
              signed: false,
            ),
            decoration: InputDecoration(
              suffixText: unit,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}
