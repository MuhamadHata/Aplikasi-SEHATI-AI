import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../inti/model/estimasi_langkah.dart';
import '../inti/tema/design_tokens.dart';
import '../penyedia/penyedia_aktivitas.dart';
import '../komponen/kutipan_sumber.dart';
import 'layar_referensi.dart';

class StepCalorieCalculatorScreen extends StatefulWidget {
  const StepCalorieCalculatorScreen({super.key});

  @override
  State<StepCalorieCalculatorScreen> createState() =>
      _StepCalorieCalculatorScreenState();
}

class _StepCalorieCalculatorScreenState
    extends State<StepCalorieCalculatorScreen> {
  final _calCtrl = TextEditingController(text: '200');
  final _stepsCtrl = TextEditingController(text: '3000');
  final _weightCtrl = TextEditingController();

  bool _modeCaloriesToSteps = true;
  StepIntensityPreset _preset = StepCalorieEstimator.presets[1];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final w = context.read<ActivityProvider>().weight;
      _weightCtrl.text = w.toStringAsFixed(1);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _stepsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double _weightKg() => double.tryParse(_weightCtrl.text.trim()) ?? 0.0;

  int _calc() {
    final w = _weightKg();
    if (_modeCaloriesToSteps) {
      final cal = int.tryParse(_calCtrl.text.trim()) ?? 0;
      return StepCalorieEstimator.estimateStepsForCalories(
        caloriesKcal: cal,
        weightKg: w,
        preset: _preset,
      );
    }
    final steps = int.tryParse(_stepsCtrl.text.trim()) ?? 0;
    return StepCalorieEstimator.estimateCaloriesForSteps(
      steps: steps,
      weightKg: w,
      preset: _preset,
    );
  }

  int _calcMinutes() {
    final w = _weightKg();
    if (_modeCaloriesToSteps) {
      final cal = int.tryParse(_calCtrl.text.trim()) ?? 0;
      return StepCalorieEstimator.estimateMinutesForCalories(
        caloriesKcal: cal,
        weightKg: w,
        preset: _preset,
      );
    }
    return 0;
  }

  void _showFormulaInfo(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cara Hitung: Rumus MET',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    StepCalorieEstimator.metFormula,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              StepCalorieEstimator.metExplanation,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nilai MET per Intensitas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...StepCalorieEstimator.presets.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'MET ${p.met}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${p.stepsPerMinute} spm',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      if (p.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          p.description,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            const CitationFooter(
              sources: StepCalorieEstimator.formulaCitations,
              note:
                  'Estimasi dapat berbeda tergantung kondisi individu, medan, dan efisiensi gerak.',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _calc();
    final minutes = _calcMinutes();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text('Kalkulator Langkah',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                color: theme.textTheme.titleLarge?.color)),
        actions: [
          IconButton(
            tooltip: 'Cara hitung & sumber',
            onPressed: () => _showFormulaInfo(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            tooltip: 'Sumber referensi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReferencesScreen(
                    tags: ['steps', 'activity', 'calories'],
                    title: 'Sumber: Aktivitas Fisik',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.menu_book_rounded),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.extension<AppThemeExtension>()?.gradientCard ??
                    AppColors.gradientCard,
              ),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _modeCaloriesToSteps = true),
                        child: _ModeChip(
                          active: _modeCaloriesToSteps,
                          icon: '🔥',
                          label: 'Kalori → Langkah',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _modeCaloriesToSteps = false),
                        child: _ModeChip(
                          active: !_modeCaloriesToSteps,
                          icon: '👟',
                          label: 'Langkah → Kalori',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Berat badan (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StepIntensityPreset>(
                  initialValue: _preset,
                  decoration: const InputDecoration(
                    labelText: 'Intensitas (perkiraan)',
                    border: OutlineInputBorder(),
                  ),
                  items: StepCalorieEstimator.presets
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.label} - ${p.stepsPerMinute} spm'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _preset = v ?? _preset),
                ),
                const SizedBox(height: 12),
                if (_modeCaloriesToSteps)
                  TextField(
                    controller: _calCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target kalori terbakar (kkal)',
                      prefixIcon: Icon(Icons.local_fire_department_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  )
                else
                  TextField(
                    controller: _stepsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target langkah (steps)',
                      prefixIcon: Icon(Icons.directions_walk_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Hasil
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hasil (perkiraan)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'Poppins'),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showFormulaInfo(context),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: theme.hintColor),
                          const SizedBox(width: 4),
                          Text(
                            'Rumus MET',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.hintColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _modeCaloriesToSteps ? '≈ $result langkah' : '≈ $result kkal',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (_modeCaloriesToSteps && minutes > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '≈ $minutes menit ${_preset.label}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Rumus visual
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📐 ${StepCalorieEstimator.metFormula}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MET ${_preset.label} = ${_preset.met} | Berat = ${_weightKg().toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ini estimasi berbasis MET dan kecepatan langkah. Hasil bisa berbeda tergantung pace, kondisi tubuh, dan medan.',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 12),
                const CitationFooter(
                  sources: StepCalorieEstimator.formulaCitations,
                ),
              ],
            ),
          ),
          // Dескripsi preset yang dipilih
          if (_preset.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 ${_preset.label}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _preset.description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _preset.citation,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: theme.hintColor,
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
}

class _ModeChip extends StatelessWidget {
  final bool active;
  final String icon;
  final String label;

  const _ModeChip(
      {required this.active, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.35)
              : theme.dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
