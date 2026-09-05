import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../penyedia/penyedia_aktivitas.dart';
import '../../penyedia/penyedia_gula_darah.dart';
import '../../inti/tema/design_tokens.dart';
import '../../inti/layanan/layanan_gemini.dart';
import '../../inti/layanan/layanan_referensi.dart';
import '../../inti/model/referensi.dart';
import 'dart:convert';
import 'layar_referensi.dart';

class DiabetesScanScreen extends StatefulWidget {
  const DiabetesScanScreen({super.key});

  @override
  State<DiabetesScanScreen> createState() => _DiabetesScanScreenState();
}

class _DiabetesScanScreenState extends State<DiabetesScanScreen> {
  final _formKey = GlobalKey<FormState>();
  List<String> _citations = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ap = context.read<ActivityProvider>();
      _ageCtrl.text = ap.age.toString();
      _bmiCtrl.text = ap.bmi.toStringAsFixed(1);
      final latestGlucose = context.read<BloodGlucoseProvider>().catatanTerbaru;
      if (latestGlucose != null && latestGlucose.nilai > 0) {
        _glucoseCtrl.text = latestGlucose.nilai.toStringAsFixed(0);
      }
    });
  }

  final TextEditingController _pregnanciesCtrl =
      TextEditingController(text: '0');
  final TextEditingController _glucoseCtrl = TextEditingController();
  final TextEditingController _bloodPressureCtrl = TextEditingController();
  final TextEditingController _bmiCtrl = TextEditingController();
  final TextEditingController _dpfCtrl = TextEditingController(text: '0.5');
  final TextEditingController _ageCtrl = TextEditingController();

  bool _isLoading = false;
  String? _result;
  bool _isHighRisk = false;

  @override
  void dispose() {
    _pregnanciesCtrl.dispose();
    _glucoseCtrl.dispose();
    _bloodPressureCtrl.dispose();
    _bmiCtrl.dispose();
    _dpfCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyzeDiabetesRisk() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _citations = const [];
    });

    try {
      final ap = context.read<ActivityProvider>();
      final String gender = ap.gender;
      final fastingMode = ap.fastingMode;
      final fastingPhase = ap.fastingPhaseLabel;
      final isFastingNow = ap.isFastingNow;

      final List<ReferenceItem> refItems =
          await ReferenceService.instance.getByTags(
        const ['diabetes', 'blood_pressure', 'fasting', 'sugar', 'activity'],
      );

      String citeName(ReferenceItem it) {
        final p = it.publisher.toLowerCase();
        if (p.contains('world health organization')) return 'WHO';
        if (p.contains('kementerian kesehatan')) return 'Kemenkes RI';
        return it.publisher;
      }

      String? citeYear(ReferenceItem it) {
        final v = it.published;
        if (v == null || v.trim().isEmpty) return null;
        final dt = DateTime.tryParse(v.trim());
        if (dt != null) return dt.year.toString();
        final m = RegExp(r'\\b(19\\d{2}|20\\d{2})\\b').firstMatch(v);
        return m?.group(0);
      }

      final allowedSources = refItems
          .map((it) =>
              '- ${it.code}: ${citeName(it)} (${citeYear(it) ?? 'n/a'})')
          .join('\\n');

      final systemPrompt = '''
Anda adalah Dokter Spesialis Endokrinologi dan AI skrining diabetes (edukasi, bukan diagnosis definitif).
Tugas Anda: menjelaskan estimasi risiko berdasarkan input pengguna, dan memberi rekomendasi gaya hidup yang aman.

ATURAN KUTIPAN WAJIB:
- Setiap kalimat rekomendasi HARUS menyertakan kutipan format (Sumber, Tahun), contoh: (WHO, 2024).
- Anda hanya boleh menggunakan sumber dari daftar ini (gunakan nama & tahun yang sesuai):
$allowedSources
- Jangan membuat sumber baru.

Berikan respons HANYA dalam format JSON persis seperti ini, tanpa markdown block:
{
  "riskPercentage": 75,
  "riskType": "Diabetes Tipe 2 / Pra-diabetes / Risiko Tinggi karena Obesitas",
  "riskLevel": "Tinggi | Rendah",
  "explanation": "Penjelasan ringkas 2-3 paragraf mengapa hasil ini diberikan (faktor dominan).",
  "recommendations": ["Saran 1 (Sumber, Tahun)", "Saran 2 (Sumber, Tahun)", "Saran 3 (Sumber, Tahun)"],
  "citations": ["WHO-DIABETES-FACTSHEET"]
}
PENTING: Jangan berikan output selain JSON di atas.
''';

      final prompt = '''
Analisis metrik kesehatan pasien berikut dan berikan prediksi risikonya:
- Gender: $gender
- Pregnancies (Kehamilan): ${_pregnanciesCtrl.text}
- Glucose (Gula Darah): ${_glucoseCtrl.text} mg/dL (Normal: 70-99, Pra-diabetes: 100-125, Diabetes: >=126)
- BloodPressure (Tekanan Darah Diastolik): ${_bloodPressureCtrl.text} mm Hg
- BMI (Indeks Massa Tubuh): ${_bmiCtrl.text}
- DiabetesPedigreeFunction (Riwayat Keluarga): ${_dpfCtrl.text}
- Age (Umur): ${_ageCtrl.text} tahun

Konteks tambahan:
- Mode puasa: $fastingMode
- Status saat ini: ${isFastingNow ? 'sedang puasa' : 'jendela makan'}
- Fase: $fastingPhase

Berdasarkan data di atas (khususnya Glukosa dan BMI sebagai faktor utama dalam dataset Pima), berikan hasil JSON Anda sekarang.
      ''';

      final responseText = await GeminiService.instance
          .generateText(prompt, systemPrompt: systemPrompt);

      if (responseText != null) {
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
        final jsonString = (match?.group(0) ?? responseText).trim();

        final isHigh = jsonString.contains('"riskLevel": "Tinggi"') ||
            jsonString.contains('"riskLevel":"Tinggi"');

        try {
          final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
          _citations = List<String>.from(parsed['citations'] ?? const []);
        } catch (_) {
          _citations = const [];
        }

        setState(() {
          _isHighRisk = isHigh;
          _result = jsonString;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final bool isQuota = e.toString().toLowerCase().contains('quota') ||
          e.toString().contains('429');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isQuota
              ? '⚠️ Kuota AI habis. Ganti API key di aistudio.google.com'
              : '❌ Terjadi kesalahan. Coba lagi.'),
          backgroundColor: isQuota ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(
      BuildContext context, String label, TextEditingController controller,
      {String? hint, String? helper}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
            color: theme.colorScheme.onSurface, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperStyle: TextStyle(color: theme.hintColor),
          labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Wajib diisi';
          }
          if (double.tryParse(value) == null) {
            return 'Harus berupa angka';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ap = context.watch<ActivityProvider>();
    final String gender = ap.gender;
    final bpHelper = ap.fastingMode == 'none'
        ? 'Tekanan Darah Diastolik (mm Hg)'
        : 'Tekanan Darah Diastolik (mm Hg)\nMode puasa: ${ap.fastingPhaseLabel}. Isi sesuai jam pengukuran.';
    if (gender == 'Pria' && _pregnanciesCtrl.text != '0') {
      _pregnanciesCtrl.text = '0';
    }

    // Basic JSON parser
    String? explanation;
    int? riskPercentage;
    String? riskType;
    List<String> recommendations = const [];
    List<String> citations = _citations;

    if (_result != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(_result!);
        explanation = data['explanation'];
        riskPercentage = data['riskPercentage'];
        riskType = data['riskType'];
        recommendations =
            List<String>.from(data['recommendations'] ?? const []);
        citations = List<String>.from(data['citations'] ?? citations);
      } catch (e) {
        explanation = "Gagal memparsing penjelasan AI.";
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Deteksi Diabetes',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface)),
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.bloodtype_outlined,
                            size: 32, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skrining Medis',
                            style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                fontFamily: 'Poppins'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masukkan data metrik tubuh untuk memprediksi risiko diabetes.',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(context, 'Umur (Tahun)', _ageCtrl,
                  hint: 'Contoh: 45'),
              _buildTextField(context, 'Gula Darah (Glucose)', _glucoseCtrl,
                  hint: 'Contoh: 120', helper: '0 - 200 mg/dL'),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 12),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/blood-glucose');
                      if (context.mounted) {
                        final latest = context.read<BloodGlucoseProvider>().catatanTerbaru;
                        if (latest != null && latest.nilai > 0) {
                          _glucoseCtrl.text = latest.nilai.toStringAsFixed(0);
                        }
                      }
                    },
                    icon: const Icon(Icons.monitor_heart_outlined, size: 16),
                    label: const Text(
                      'Buka Monitor & Log Gula Darah',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              _buildTextField(context, 'Indeks Massa Tubuh (BMI)', _bmiCtrl,
                  hint: 'Contoh: 28.5', helper: 'Berat(kg) / Tinggi(m)²'),
              _buildTextField(
                  context, 'Tekanan Darah (Blood Pressure)', _bloodPressureCtrl,
                  hint: 'Contoh: 70', helper: bpHelper),
              if (gender != 'Pria')
                _buildTextField(
                    context, 'Kehamilan (Pregnancies)', _pregnanciesCtrl,
                    hint: 'Contoh: 0', helper: 'Jumlah kehamilan'),
              _buildTextField(
                  context, 'Riwayat Keluarga (Pedigree Function)', _dpfCtrl,
                  hint: 'Contoh: 0.5',
                  helper: 'Riwayat diabetes keluarga (0.1 - 2.5)'),
              _PedigreeQuickPick(
                onPick: (v) => setState(() => _dpfCtrl.text = v),
                onOpenSources: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReferencesScreen(
                        tags: ['diabetes', 'dpf', 'dataset'],
                        title: 'Sumber: Pedigree Function',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressColor())
                  : ElevatedButton(
                      onPressed: _analyzeDiabetesRisk,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text('Mulai Analisis',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins')),
                    ),
              if (_result != null && !_isLoading) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _isHighRisk
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color:
                            _isHighRisk ? AppColors.error : AppColors.success,
                        width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isHighRisk ? 'RISIKO TINGGI' : 'RISIKO RENDAH',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color:
                              _isHighRisk ? AppColors.error : AppColors.success,
                          fontFamily: 'Poppins',
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (riskPercentage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '$riskPercentage%',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: _isHighRisk
                                ? AppColors.error
                                : AppColors.success,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'Estimasi Risiko',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (riskType != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: (_isHighRisk
                                        ? AppColors.error
                                        : AppColors.success)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            riskType,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isHighRisk
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        explanation ?? 'Data diterima dan teranalisis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      if (recommendations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Rekomendasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...recommendations.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: TextStyle(
                                        color: theme.colorScheme.onSurface),
                                  ),
                                  Expanded(
                                    child: Text(
                                      r,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      if (citations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReferencesScreen(
                                  codes: citations,
                                  title: 'Sumber Saran AI',
                                ),
                              ),
                            ),
                            icon: Icon(Icons.menu_book_rounded, size: 18),
                            label: const Text('Lihat sumber'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class CircularProgressColor extends StatelessWidget {
  const CircularProgressColor({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12.0),
      child: CircularProgressIndicator(color: AppColors.error),
    );
  }
}

class _PedigreeQuickPick extends StatelessWidget {
  final void Function(String value) onPick;
  final VoidCallback onOpenSources;

  _PedigreeQuickPick({required this.onPick, required this.onOpenSources});

  void _showDpfDetail(BuildContext context) {
    final theme = Theme.of(context);
    // DPF value table
    const dpfEntries = [
      {
        'val': '0.1',
        'label': 'Tidak ada riwayat',
        'who': 'Tidak diketahui ada anggota keluarga dengan diabetes.',
        'color': 0xFF10B981,
      },
      {
        'val': '0.3',
        'label': 'Riwayat jauh (kakek/nenek)',
        'who': 'Satu atau dua kakek/nenek/paman/tante dengan diabetes. Pengaruh genetik lebih rendah.',
        'color': 0xFF84CC16,
      },
      {
        'val': '0.5',
        'label': 'Satu orang tua / saudara kandung',
        'who': 'Ibu, ayah, atau satu saudara kandung terdiagnosis diabetes. Risiko meningkat ~2×.',
        'color': 0xFFF59E0B,
      },
      {
        'val': '1.0',
        'label': '≥2 anggota keluarga inti',
        'who': 'Misal: dua orang tua, atau satu orang tua + saudara kandung. Risiko cukup signifikan.',
        'color': 0xFFF97316,
      },
      {
        'val': '1.5',
        'label': 'Banyak riwayat (3+ orang)',
        'who': 'Tiga atau lebih anggota keluarga inti/kakek-nenek. Riwayat keluarga kuat.',
        'color': 0xFFEF4444,
      },
      {
        'val': '2.0+',
        'label': 'Riwayat sangat kuat',
        'who': 'Diabetes lintas generasi (kakek, orang tua, saudara). Pengaruh genetik dominan.',
        'color': 0xFF9F1239,
      },
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'Panduan Nilai DPF',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'DiabetesPedigreeFunction (DPF) adalah fitur dari dataset Pima Indians Diabetes '
              '(NIDDK, 1988) untuk merangkum pengaruh riwayat keluarga dalam satu angka. '
              'Gunakan tabel berikut untuk memilih nilai yang paling mendekati kondisi Anda.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 14),
            ...dpfEntries.map((e) {
              final color = Color(e['color'] as int);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            onPick(e['val'] as String);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              e['val'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: color,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(Icons.touch_app_rounded,
                            size: 16, color: color.withValues(alpha: 0.6)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      e['who'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            // Kutipan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.library_books_rounded,
                          size: 14, color: theme.hintColor),
                      const SizedBox(width: 6),
                      Text('Sumber Dataset & Kutipan',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.hintColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CiteRow(Icons.health_and_safety_rounded,
                      'Smith et al., Pima Indians Diabetes Dataset, 1988 (NIDDK/UCI ML Repository)'),
                  _CiteRow(Icons.health_and_safety_rounded, 'WHO Diabetes Fact Sheet, 2023'),
                  _CiteRow(Icons.health_and_safety_rounded,
                      'Kemenkes RI, Pedoman Pengendalian Diabetes Melitus, 2021'),
                  const SizedBox(height: 6),
                  Text(
                    'Angka DPF adalah estimasi untuk keperluan prediksi model. Bukan pengganti diagnosis klinis.',
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: theme.hintColor.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onOpenSources();
              },
              icon: Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Lihat Semua Sumber'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pilihan cepat DPF',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showDpfDetail(context),
                icon: Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('Panduan Nilai'),
              )
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PickChip(
                label: '0.1 – Tidak ada riwayat',
                onTap: () => onPick('0.1'),
              ),
              _PickChip(
                label: '0.5 – Satu orang tua/saudara',
                onTap: () => onPick('0.5'),
              ),
              _PickChip(
                label: '1.0 – ≥2 keluarga inti',
                onTap: () => onPick('1.0'),
              ),
              _PickChip(
                label: '1.5 – Banyak riwayat',
                onTap: () => onPick('1.5'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Panduan Nilai" untuk melihat tabel penjelasan per nilai beserta kutipan sumber.',
            style: TextStyle(fontSize: 12, color: theme.hintColor, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _CiteRow extends StatelessWidget {
  final IconData icon;
  final String text;
  _CiteRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary), // const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  _PickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85)),
        ),
      ),
    );
  }
}