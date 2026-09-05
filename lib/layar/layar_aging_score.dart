import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../inti/model/aging_score.dart';
import '../inti/tema/design_tokens.dart';
import '../penyedia/penyedia_aktivitas.dart';
import '../komponen/kutipan_sumber.dart';
import 'layar_referensi.dart';

class LifestyleAgingScoreScreen extends StatefulWidget {
  const LifestyleAgingScoreScreen({super.key});

  @override
  State<LifestyleAgingScoreScreen> createState() =>
      _LifestyleAgingScoreScreenState();
}

class _LifestyleAgingScoreScreenState extends State<LifestyleAgingScoreScreen> {
  String _smokingStatus = ActivityProvider.smokingStatusNone;
  bool _sleepAdequate = true;
  bool _stressManaged = true;
  double _activityMinPerWeek = 150;
  double _sugaryDrinksPerWeek = 2;
  double _bmi = 22.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ap = context.read<ActivityProvider>();
      setState(() {
        _smokingStatus = ap.smokingStatus;
        _sleepAdequate = ap.lastSleepRecord?.isAdequate ?? ap.sleepAdequateHabit;
        _stressManaged = ap.stressManaged;
        _activityMinPerWeek = ap.moderateActivityMinutesPerWeek.toDouble();
        _sugaryDrinksPerWeek = ap.sugaryDrinksPerWeek.toDouble();
        _bmi = ap.bmi;
      });
    });
  }

  Future<void> _persistLifestyle() async {
    final ap = context.read<ActivityProvider>();
    await ap.setSmokingStatus(_smokingStatus);
    await ap.updateLifestyleAgingPreferences(
      sleepAdequate: _sleepAdequate,
      stressManaged: _stressManaged,
      activityMinutesPerWeek: _activityMinPerWeek.round(),
      sugaryDrinksPerWeek: _sugaryDrinksPerWeek.round(),
    );
    ap.updateBMI(_bmi);
  }

  LifestyleAgingResult _calc() {
    return LifestyleAgingScore.calculate(
      LifestyleAgingInputs(
        smokingStatus: _smokingStatus,
        moderateActivityMinutesPerWeek: _activityMinPerWeek.round(),
        sugaryDrinksPerWeek: _sugaryDrinksPerWeek.round(),
        bmi: _bmi,
        sleepAdequate: _sleepAdequate,
        stressManaged: _stressManaged,
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Luar Biasa! 🌟';
    if (score >= 65) return 'Baik 👍';
    if (score >= 50) return 'Cukup ✅';
    if (score >= 30) return 'Perlu Perbaikan ⚠️';
    return 'Kritis – Ubah Gaya Hidup 🚨';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _calc();
    final scoreColor = _scoreColor(result.score);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text('Rumus Aging Score',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                color: theme.textTheme.titleLarge?.color)),
        actions: [
          IconButton(
            tooltip: 'Sumber',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReferencesScreen(
                  tags: ['cerdik', 'aging', 'activity', 'sugar', 'diabetes'],
                  title: 'Sumber: Aging Score',
                ),
              ),
            ),
            icon: const Icon(Icons.menu_book_rounded),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Definisi
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
                const Text(
                  'Tentang Aging Score',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skor transparan berbasis kebiasaan hidup (bukan usia biologis/diagnosis). '
                  'Skor mulai dari 100 lalu dikurangi berdasarkan faktor risiko gaya hidup '
                  'sesuai pedoman CERDIK dari Kemenkes RI.',
                  style: TextStyle(
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 8),
                const CitationWidget(
                  sources: [
                    'Kemenkes RI CERDIK, 2022',
                    'WHO Global PA Guidelines, 2020',
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Input switches & sliders
          _SmokingStatusCard(
            value: _smokingStatus,
            onChanged: (value) {
              setState(() => _smokingStatus = value);
              _persistLifestyle();
            },
          ),
          _SwitchRow(
            label: 'Istirahat cukup (≥7 jam/hari)',
            value: _sleepAdequate,
            onChanged: (v) {
              setState(() => _sleepAdequate = v);
              _persistLifestyle();
            },
          ),
          _SwitchRow(
            label: 'Stres terkelola',
            value: _stressManaged,
            onChanged: (v) {
              setState(() => _stressManaged = v);
              _persistLifestyle();
            },
          ),
          const SizedBox(height: 10),
          _SliderRow(
            label: 'Aktivitas fisik intensitas sedang (menit/minggu)',
            value: _activityMinPerWeek,
            min: 0,
            max: 300,
            divisions: 60,
            onChanged: (v) => setState(() => _activityMinPerWeek = v),
            onChangeEnd: (_) {
              _persistLifestyle();
            },
          ),
          _SliderRow(
            label: 'Minuman manis (kali/minggu)',
            value: _sugaryDrinksPerWeek,
            min: 0,
            max: 14,
            divisions: 14,
            onChanged: (v) => setState(() => _sugaryDrinksPerWeek = v),
            onChangeEnd: (_) {
              _persistLifestyle();
            },
          ),
          _SliderRow(
            label: 'BMI (IMT)',
            value: _bmi,
            min: 15,
            max: 40,
            divisions: 50,
            onChanged: (v) => setState(() => _bmi = v),
            onChangeEnd: (_) {
              _persistLifestyle();
            },
          ),
          const SizedBox(height: 12),

          // Hasil skor dengan progress bar berwarna
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
                Text(
                  'Aging Score (Gaya Hidup)',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${result.score}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                        fontFamily: 'Poppins',
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: scoreColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _scoreLabel(result.score),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar berwarna
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: result.score / 100,
                    backgroundColor:
                        scoreColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 12),
                // Rumus
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '📐 Rumus: 100 − penalti merokok − penalti aktivitas − penalti minuman manis − penalti BMI − penalti tidur − penalti stres',
                    style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7)),
                  ),
                ),
                if (result.deductions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Penalti aktif:',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  ...result.deductions.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $d',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.75)),
                        ),
                      )),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Dasar ilmiah per komponen (ExpansionTile)
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
            ),
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: const Text(
                  '📚 Dasar Ilmiah Rumus',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                subtitle: Text(
                  'Tap untuk lihat penjelasan ilmiah per komponen',
                  style:
                      TextStyle(fontSize: 11, color: theme.hintColor),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        _ScienceRow(
                          icon: Icons.health_and_safety_rounded,
                          title: 'Merokok (−25 poin)',
                          explanation:
                              'Merokok merusak DNA secara epigenetik, memperpendek telomer, '
                              'dan mempercepat penuaan sel. Ini faktor risiko terbesar yang '
                              'dapat dikendalikan.',
                          citations: [
                            'Kemenkes RI Kawasan Tanpa Rokok, 2023',
                            'WHO Tobacco Fact Sheet, 2023',
                          ],
                        ),
                        _ScienceRow(
                          icon: Icons.health_and_safety_rounded,
                          title: 'Aktivitas < 150 mnt/minggu (−15 poin)',
                          explanation:
                              'Minimal 150 menit per minggu aktivitas fisik aerobik intensitas '
                              'sedang direkomendasikan WHO untuk mencegah penyakit kronik, '
                              'menjaga berat badan, dan memperlambat penuaan fungsional.',
                          citations: [
                            'WHO Global PA Guidelines, 2020',
                            'Kemenkes RI Pedoman AktFisik, 2020',
                          ],
                        ),
                        _ScienceRow(
                          icon: Icons.health_and_safety_rounded,
                          title: 'Minuman manis ≥3×/minggu (−8 atau −15)',
                          explanation:
                              'Konsumsi gula bebas (free sugars) >10% dari total energi harian '
                              'meningkatkan inflamasi kronik, obesitas, dan risiko DMT2. '
                              'WHO merekomendasikan <25g gula bebas per hari.',
                          citations: [
                            'WHO Free Sugars Guideline, 2015',
                            'Kemenkes RI Batas Gula Garam Lemak, 2020',
                          ],
                        ),
                        _ScienceRow(
                          icon: Icons.health_and_safety_rounded,
                          title: 'BMI ≥25 (−8 poin) / ≥30 (−15 poin)',
                          explanation:
                              'Kelebihan berat badan (BMI 25–29.9) dan obesitas (≥30) '
                              'dikaitkan dengan risiko lebih tinggi penyakit jantung, '
                              'diabetes, dan beberapa jenis kanker. IMT ideal: 18.5–24.9.',
                          citations: [
                            'Kemenkes RI CERDIK, 2022',
                            'WHO BMI Classification, 2023',
                          ],
                        ),
                        _ScienceRow(
                          icon: Icons.health_and_safety_rounded,
                          title: 'Tidur kurang (−10 poin)',
                          explanation:
                              'Tidur <7 jam per malam secara konsisten meningkatkan risiko '
                              'diabetes tipe 2, hipertensi, dan gangguan imun. Saat tidur, '
                              'tubuh melakukan proses reparasi sel dan konsolidasi memori.',
                          citations: [
                            'WHO Mental Health Action Plan, 2021',
                            'Kemenkes RI Germas Tidur Cukup, 2021',
                          ],
                        ),
                        _ScienceRow(
                          icon: Icons.health_and_safety_rounded,
                          title: 'Stres tidak terkelola (−10 poin)',
                          explanation:
                              'Stres kronis meningkatkan kadar kortisol yang, jika terus-menerus '
                              'tinggi, mempercepat penuaan seluler, melemahkan imun, dan merusak '
                              'jaringan kardiovaskular.',
                          citations: [
                            'WHO World Mental Health Report, 2022',
                            'Kemenkes RI Kesehatan Jiwa, 2022',
                          ],
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Text(
            'Catatan: gunakan ini untuk memantau kebiasaan. Untuk keluhan kesehatan/risiko penyakit, konsultasikan tenaga kesehatan.',
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ScienceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String explanation;
  final List<String> citations;
  final bool isLast;

  const _ScienceRow({
    required this.icon,
    required this.title,
    required this.explanation,
    required this.citations,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 6),
                    CitationWidget(sources: citations),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              color: theme.dividerColor.withValues(alpha: 0.08), height: 8),
      ],
    );
  }
}

class _SmokingStatusCard extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SmokingStatusCard({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = [
      ActivityProvider.smokingStatusNone,
      ActivityProvider.smokingStatusActive,
      ActivityProvider.smokingStatusPassive,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status rokok dan paparan asap',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = option == value;
              return ChoiceChip(
                label: Text(ActivityProvider.smokingStatusLabelOf(option)),
                selected: selected,
                onSelected: (_) => onChanged(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface)),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  value.round().toString(),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
