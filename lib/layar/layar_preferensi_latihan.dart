import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../inti/tema/design_tokens.dart';
import '../../penyedia/penyedia_aktivitas.dart';

class WorkoutPreferencesScreen extends StatefulWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  State<WorkoutPreferencesScreen> createState() =>
      _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1 – Goals (multi-select)
  final List<String> _selectedGoals = [];
  // Step 2 – Muscle Focus (multi-select)
  final List<String> _selectedMuscles = [];
  // Step 3 – Equipment (single)
  String? _selectedEquipment;
  // Step 4 – Frequency (single)
  int? _selectedFrequency;

  static const int _totalSteps = 4;

  // ─── Step Data ───────────────────────────────────────────────────────────
  final _goals = [
    {
      'id': 'Build Muscle',
      'label': 'Bangun Otot',
      'emoji': '💪',
      'color': 0xFFFF7A96
    },
    {
      'id': 'Lose Weight',
      'label': 'Turunkan Berat',
      'emoji': '🔥',
      'color': 0xFFFB923C
    },
    {
      'id': 'Gain Strength',
      'label': 'Tambah Kekuatan',
      'emoji': '⚡',
      'color': 0xFF34D399
    },
    {
      'id': 'Stay Fit',
      'label': 'Tetap Bugar',
      'emoji': '🏃',
      'color': 0xFF38BDF8
    },
    {
      'id': 'Conditioning',
      'label': 'Kondisi Tubuh',
      'emoji': '🧠',
      'color': 0xFFA78BFA
    },
    {'id': 'Sport', 'label': 'Olahraga', 'emoji': '⚽', 'color': 0xFFFBBF24},
  ];

  final _muscles = [
    {'id': 'chest', 'label': 'Dada', 'emoji': '🫀'},
    {'id': 'back', 'label': 'Punggung', 'emoji': '🦾'},
    {'id': 'arms', 'label': 'Lengan', 'emoji': '💪'},
    {'id': 'shoulders', 'label': 'Bahu', 'emoji': '🫷'},
    {'id': 'abs', 'label': 'Perut', 'emoji': '🎯'},
    {'id': 'legs', 'label': 'Kaki', 'emoji': '🦵'},
    {'id': 'glutes', 'label': 'Bokong', 'emoji': '🍑'},
    {'id': 'cardio', 'label': 'Seluruh Tubuh', 'emoji': '🔄'},
  ];

  final _equipment = [
    {
      'id': 'Full Gym',
      'label': 'Full Gym',
      'emoji': '🏟️',
      'desc': 'Semua alat tersedia'
    },
    {
      'id': 'barbell',
      'label': 'Barbel',
      'emoji': '🏋️',
      'desc': 'Barbel & rak beban'
    },
    {
      'id': 'dumbbell',
      'label': 'Dumbbell',
      'emoji': '🪃',
      'desc': 'Dumbbell saja'
    },
    {
      'id': 'kettle',
      'label': 'Kettlebell',
      'emoji': '⚙️',
      'desc': 'Kettlebell ajah'
    },
    {
      'id': 'machine',
      'label': 'Mesin Gym',
      'emoji': '🤖',
      'desc': 'Mesin & kabel'
    },
    {
      'id': 'bodyweight',
      'label': 'Tanpa Alat',
      'emoji': '🤸',
      'desc': 'Bodyweight only'
    },
  ];

  // ─── Navigation ──────────────────────────────────────────────────────────
  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _selectedGoals.isNotEmpty;
      case 1:
        return _selectedMuscles.isNotEmpty;
      case 2:
        return _selectedEquipment != null;
      case 3:
        return _selectedFrequency != null;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (!_canProceed) return;
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAndFinish();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _saveAndFinish() {
    context.read<ActivityProvider>().updateWorkoutPreferences(
          _selectedGoals.first,
          level: 'Adaptif (BMI & Aktivitas)',
          muscleGroups: _selectedMuscles,
          equipment: _selectedEquipment,
          frequency: _selectedFrequency,
        );
    Navigator.pushReplacementNamed(context, '/workout-ai');
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar with step indicator ──
            _buildTopBar(theme, isDark),
            // ── Page content ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _GoalStep(
                    goals: _goals,
                    selected: _selectedGoals,
                    onToggle: (id) => setState(() {
                      if (_selectedGoals.contains(id)) {
                        _selectedGoals.remove(id);
                      } else {
                        _selectedGoals.add(id);
                      }
                    }),
                  ),
                  _MuscleStep(
                    muscles: _muscles,
                    selected: _selectedMuscles,
                    onToggle: (id) => setState(() {
                      if (_selectedMuscles.contains(id)) {
                        _selectedMuscles.remove(id);
                      } else {
                        _selectedMuscles.add(id);
                      }
                    }),
                  ),
                  _EquipmentStep(
                    equipment: _equipment,
                    selected: _selectedEquipment,
                    onSelect: (id) => setState(() => _selectedEquipment = id),
                  ),
                  _FrequencyStep(
                    selected: _selectedFrequency,
                    onSelect: (v) => setState(() => _selectedFrequency = v),
                  ),
                ],
              ),
            ),
            // ── Bottom action buttons ──
            _buildBottomBar(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _prevPage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.15)),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Latihan SEHATI-AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Langkah ${_currentPage + 1} dari $_totalSteps',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Step dots
              Row(
                children: List.generate(_totalSteps, (i) {
                  final active = i == _currentPage;
                  final done = i < _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(left: 5),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: done || active
                          ? theme.colorScheme.primary
                          : theme.dividerColor.withValues(alpha: 0.25),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalSteps,
              minHeight: 4,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    final isLast = _currentPage == _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: GestureDetector(
        onTap: _canProceed ? _nextPage : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: _canProceed
                ? const LinearGradient(colors: AppColors.gradientPrimary)
                : null,
            color:
                _canProceed ? null : theme.dividerColor.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLast ? 'Mulai! Buat Program 🚀' : 'Lanjutkan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _canProceed
                        ? Colors.white
                        : theme.dividerColor.withValues(alpha: 0.5),
                    letterSpacing: 0.3,
                  ),
                ),
                if (!isLast && _canProceed) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step 1: Goals ────────────────────────────────────────────────────────────
class _GoalStep extends StatelessWidget {
  final List<Map<String, dynamic>> goals;
  final List<String> selected;
  final Function(String) onToggle;

  const _GoalStep(
      {required this.goals, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Apa Tujuanmu?',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Pilih satu atau lebih tujuan latihan kamu.',
              style: TextStyle(
                  fontSize: 15, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: goals.map((g) {
              final isSelected = selected.contains(g['id']);
              final color = Color(g['color'] as int);
              return GestureDetector(
                onTap: () => onToggle(g['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.12)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : theme.dividerColor.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(g['emoji'],
                              style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        g['label'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color:
                              isSelected ? color : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Icon(Icons.check_circle, color: color, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Muscle Focus ─────────────────────────────────────────────────────
class _MuscleStep extends StatelessWidget {
  final List<Map<String, dynamic>> muscles;
  final List<String> selected;
  final Function(String) onToggle;

  const _MuscleStep(
      {required this.muscles, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.accessibility_new_rounded, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Area Fokus Otot',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Pilih bagian tubuh yang ingin dilatih.',
              style: TextStyle(
                  fontSize: 15, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: muscles.map((m) {
              final isSel = selected.contains(m['id']);
              return GestureDetector(
                onTap: () => onToggle(m['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel
                        ? primary.withValues(alpha: 0.12)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: isSel
                          ? primary
                          : theme.dividerColor.withValues(alpha: 0.2),
                      width: isSel ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m['emoji'], style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        m['label'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? primary : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (selected.contains('cardio'))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '"Seluruh Tubuh" mencakup semua grup otot sekaligus.',
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Step 3: Equipment ────────────────────────────────────────────────────────
class _EquipmentStep extends StatelessWidget {
  final List<Map<String, dynamic>> equipment;
  final String? selected;
  final Function(String) onSelect;

  const _EquipmentStep(
      {required this.equipment,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center_rounded, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Peralatan Tersedia',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          Text('SEHATI-AI akan menyesuaikan gerakan berdasarkan alatmu.',
              style: TextStyle(
                  fontSize: 15, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 24),
          ...equipment.map((e) {
            final isSel = selected == e['id'];
            return GestureDetector(
              onTap: () => onSelect(e['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: isSel
                      ? primary.withValues(alpha: 0.08)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel
                        ? primary
                        : theme.dividerColor.withValues(alpha: 0.2),
                    width: isSel ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(e['emoji'], style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['label'],
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSel
                                      ? primary
                                      : theme.colorScheme.onSurface)),
                          Text(e['desc'],
                              style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color)),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSel
                          ? Icon(Icons.check_circle_outline_rounded,
                              key: const ValueKey('on'), color: primary)
                          : Icon(Icons.circle_outlined,
                              key: const ValueKey('off'),
                              color: theme.dividerColor.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Step 4: Frequency ────────────────────────────────────────────────────────
class _FrequencyStep extends StatelessWidget {
  final int? selected;
  final Function(int) onSelect;

  const _FrequencyStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final freqLabels = {
      1: '1x / minggu',
      2: '2x / minggu',
      3: '3x / minggu',
      4: '4x / minggu',
      5: '5x / minggu',
      6: '6x / minggu',
      7: 'Setiap hari',
    };

    final freqIcons = {
      1: Icons.self_improvement_rounded,
      2: Icons.directions_walk_rounded,
      3: Icons.directions_run_rounded,
      4: Icons.fitness_center_rounded,
      5: Icons.sports_martial_arts_rounded,
      6: Icons.bolt_rounded,
      7: Icons.local_fire_department_rounded,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Seberapa Sering?',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Berapa kali per minggu kamu ingin berlatih?',
              style: TextStyle(
                  fontSize: 15, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: List.generate(7, (i) {
              final freq = i + 1;
              final isSel = selected == freq;
              return GestureDetector(
                onTap: () => onSelect(freq),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSel
                        ? primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel
                          ? primary
                          : theme.dividerColor.withValues(alpha: 0.2),
                      width: isSel ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(freqIcons[freq]!,
                          size: 18,
                          color: isSel ? primary : theme.colorScheme.primary.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Text(
                        freqLabels[freq]!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          color: isSel ? primary : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
