import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../penyedia/penyedia_aktivitas.dart';
import '../../inti/layanan/layanan_gemini.dart';
import '../../inti/layanan/layanan_media_latihan.dart';
import '../../inti/model/basis_data_latihan_lokal.dart';
import '../../inti/layanan/layanan_referensi.dart';
import '../../inti/model/referensi.dart';
import '../../inti/tema/design_tokens.dart';
import 'layar_latihan_aktif.dart';
import 'pemutar_youtube_latihan.dart';
import 'pemutar_video_lokal.dart';
import 'layar_referensi.dart';

// ─── SEHATI-AI Workout Screen ───────────────────────────────────────────────────
// Program latihan cerdas personal berbasis BMI (IBM) dan aktivitas fisik harian.
// Berurutan secara fisiologis: Pemanasan (Warm-Up) ➔ Latihan Inti ➔ Pendinginan (Cool-Down).
// Program tersimpan secara persisten dan hanya berganti jika pengguna menekan "Buat Ulang Program".

class WorkoutAIScreen extends StatefulWidget {
  const WorkoutAIScreen({super.key});

  @override
  State<WorkoutAIScreen> createState() => _WorkoutAIScreenState();
}

class _WorkoutAIScreenState extends State<WorkoutAIScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _workoutData;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _initWorkout();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _getStorageKey(String email) {
    final sanitized = email.trim().isEmpty
        ? 'guest'
        : email.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return 'sehati_saved_workout_program_$sanitized';
  }

  // ─── Initialize Program (Persistence Check) ───────────────────────────────
  Future<void> _initWorkout() async {
    try {
      final provider = context.read<ActivityProvider>();
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(provider.userEmail);
      final savedJson = prefs.getString(key);

      if (savedJson != null && savedJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(savedJson);
        final List<dynamic>? rawExercises = decoded['exercises'];

        if (rawExercises != null && rawExercises.isNotEmpty) {
          // Pastikan semua gerakan memiliki atribut phase
          _ensurePhasesAssigned(decoded);

          if (mounted) {
            setState(() {
              _workoutData = decoded;
              _isLoading = false;
            });
            _fadeCtrl.forward();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved workout program: $e');
    }

    // Jika belum ada program tersimpan, buat untuk pertama kali
    await _fetchWorkout(forceRegenerate: false);
  }

  // Menjamin setiap latihan memiliki tag phase yang valid
  void _ensurePhasesAssigned(Map<String, dynamic> data) {
    final list = data['exercises'] as List<dynamic>;
    if (list.isEmpty) return;

    bool hasAnyPhase = list.any((e) => e is Map && e['phase'] != null);
    if (!hasAnyPhase) {
      for (int i = 0; i < list.length; i++) {
        final ex = list[i] as Map<String, dynamic>;
        if (i == 0) {
          ex['phase'] = 'warmup';
        } else if (i == list.length - 1) {
          ex['phase'] = 'cooldown';
        } else {
          ex['phase'] = 'main';
        }
      }
    }
  }

  Future<void> _saveWorkoutToPrefs(Map<String, dynamic> data) async {
    try {
      final provider = context.read<ActivityProvider>();
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(provider.userEmail);
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving workout to prefs: $e');
    }
  }

  // ─── AI Prompt Builder & Generator ─────────────────────────────────────────
  Future<void> _fetchWorkout({bool forceRegenerate = false}) async {
    final provider = context.read<ActivityProvider>();
    if (mounted) setState(() => _isLoading = true);

    try {
      final age = provider.age;
      final gender = provider.gender;
      final bmi = provider.bmi;
      final weight = provider.weight;
      final height = provider.heightCm;
      final goals = provider.workoutGoal ?? 'Menjaga Kebugaran & Pembakaran Kalori';
      final muscles = provider.workoutMuscleGroups.isNotEmpty
          ? provider.workoutMuscleGroups.join(', ')
          : 'seluruh tubuh';
      final equipment = provider.workoutEquipment ?? 'bodyweight';

      // Konteks aktivitas hari ini
      final runningKm = provider.runningDistance;
      final hasRunToday = runningKm >= 0.5;
      final steps = provider.steps;
      final caloriesBurned = provider.caloriesBurned;
      final calorieTarget = provider.calorieTarget;
      final targetBurn = (calorieTarget - caloriesBurned).clamp(160, 320);

      final isJointFriendly = bmi >= 25.0;
      final isUnderweight = bmi < 18.5;

      final List<ReferenceItem> refItems =
          await ReferenceService.instance.getByTags(
        const ['activity', 'fasting', 'campaign'],
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
        final m = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(v);
        return m?.group(0);
      }

      final allowedSources = refItems
          .map((it) =>
              '- ${it.code}: ${citeName(it)} (${citeYear(it) ?? 'n/a'})')
          .join('\n');

      final prompt = '''
Anda adalah pelatih kebugaran AI fisiologis dan personal bernama SEHATI-AI.
Tugas Anda adalah merancang PROGRAM LATIHAN FISIK PERSONAL yang aman, terstruktur, dan efektif.

PROFIL KESEHATAN PENGGUNA:
- Usia: $age tahun | Gender: $gender
- Tinggi: ${height.toStringAsFixed(0)} cm | Berat: ${weight.toStringAsFixed(1)} kg
- BMI (IBM): ${bmi.toStringAsFixed(1)} (${isJointFriendly ? 'Overweight/Obesitas - WAJIB RAMAH PERSENDIAN' : (isUnderweight ? 'Underweight - PENGUATAN MASSA OTOT' : 'Ideal/Normal - SEIMBANG')})
- Tujuan Utama: $goals
- Area Fokus: $muscles
- Peralatan: $equipment

AKTIVITAS & DEFISIT HARI INI:
- Status Lari: ${hasRunToday ? 'Sudah lari ${runningKm.toStringAsFixed(1)} km hari ini' : 'BELUM LARI SAMA SEKALI HARI INI'}
- Total Langkah Harian: $steps langkah
- Kalori Terbakar Saat Ini: $caloriesBurned kkal dari target $calorieTarget kkal
- Target Pembakaran Sesi Ini: ~$targetBurn kkal (${hasRunToday ? 'Pemulihan & penguatan otot penunjang' : 'Kompensasi pembakaran kalori lari yang belum terpenuhi'})

ATURAN STRUKTUR LATIHAN WAJIB (URUTAN FISIOLOGIS):
Program HARUS terdiri dari 5-7 gerakan latihan yang berurutan dan dibagi tegas menjadi 3 FASE:
1. FASE PEMANASAN ("phase": "warmup"): TEPAT 1-2 gerakan mobilitas sendi & aktivasi kardio ringan (contoh: arm circles, marching in place, dynamic hip stretch). Durasi 30-45 detik per gerakan.
2. FASE LATIHAN INTI ("phase": "main"): TEPAT 3-4 gerakan latihan utama untuk pembakaran kalori dan penguatan otot.
   - PENTING UNTUK BMI: ${isJointFriendly ? 'Karena BMI >= 25.0, WAJIB pilih gerakan LOW-IMPACT / RAMAH PERSENDIAN LUTUT & ENGKEL (contoh: controlled bodyweight squat, incline/wall push-up, plank, glute bridge). DILARANG memberikan jump squat atau burpee tinggi yang membebani sendi!' : 'Kombinasi dinamis pembakar kalori kardio dan kekuatan otot.'}
   - PENTING UNTUK DEFISIT LARI: ${hasRunToday ? 'Fokus ke penguatan core dan stabilitas otot.' : 'Fokus pada pembakaran kalori kompensasi kardio tubuh untuk menggantikan pembakaran lari.'}
3. FASE PENDINGINAN ("phase": "cooldown"): TEPAT 1-2 gerakan peregangan statis & normalisasi detak jantung (contoh: child pose, hamstring stretch, cobra stretch). Durasi 40-60 detik.

ATURAN FORMAT WAJIB:
- DILARANG menggunakan atau menyebutkan kata Level (Pemula, Menengah, Mahir). Sesuaikan kesulitan murni dari BMI dan aktivitas.
- Durasi/Reps: Jika gerakan repetisi, atur "durationSeconds": 0 dan isi "sets" & "reps". Jika gerakan tahanan waktu (plank, stretching, warmup), atur "sets": 0, "reps": 0, dan isi "durationSeconds".
- "name": nama dalam Bahasa Inggris standar gym (misal: "arm circles", "squat", "push up", "plank", "child pose").
- "name_id": nama dalam Bahasa Indonesia yang komunikatif dan ramah.
- "muscleGroup": grup otot target.
- "phase": WAJIB salah satu dari "warmup", "main", atau "cooldown".
- Semua catatan medis ("notes") harus menyertakan kutipan resmi (WHO, 2024 atau Kemenkes RI):
$allowedSources

HANYA kembalikan JSON valid tanpa markdown formatting (tanpa ```json):
{
  "title": "${isJointFriendly ? 'Program Ramah Sendi & Kompensasi' : (hasRunToday ? 'Penguatan Otot & Pemulihan' : 'Kompensasi Kardio & Kebugaran')}",
  "totalDurationMinutes": ${isJointFriendly ? 20 : 22},
  "caloriesBurned": $targetBurn,
  "focus": "$muscles",
  "bmiStatus": "${isJointFriendly ? 'BMI ${bmi.toStringAsFixed(1)} • Ramah Sendi' : 'BMI ${bmi.toStringAsFixed(1)} • Kebugaran Aktif'}",
  "bmiAdvice": "${isJointFriendly ? 'Gerakan disesuaikan dengan benturan minimal guna melindungi persendian lutut & pinggul.' : 'Kombinasi pembakaran kalori dan pengencangan otot seluruh tubuh.'}",
  "activityStatus": "${hasRunToday ? 'Sudah Lari ${runningKm.toStringAsFixed(1)} km' : 'Belum Lari Hari Ini'}",
  "activityAdvice": "${hasRunToday ? 'Latihan berfokus pada penguatan core dan peregangan pemulihan.' : 'Kompensasi kalori intensif ~$targetBurn kkal untuk menjaga defisit energi harianmu.'}",
  "notes": [
    "Lakukan gerakan secara berurutan mulai dari pemanasan hingga pendinginan (WHO, 2020)",
    "Minum air secukupnya sebelum dan sesudah berolahraga (Kemenkes RI, 2022)"
  ],
  "citations": ["WHO-PA-FACTSHEET"],
  "exercises": [
    {
      "phase": "warmup",
      "name": "arm circles",
      "name_id": "Putaran Lengan Dinamis",
      "muscleGroup": "Bahu",
      "durationSeconds": 30,
      "sets": 0,
      "reps": 0,
      "instruction": "Rentangkan kedua lengan dan putar perlahan untuk melumasi persendian bahu."
    },
    {
      "phase": "main",
      "name": "squat",
      "name_id": "Bodyweight Squat",
      "muscleGroup": "Paha & Glutes",
      "durationSeconds": 0,
      "sets": 3,
      "reps": 12,
      "instruction": "Turunkan pinggul terkontrol dengan dada tegak dan lutut sejajar jari kaki."
    },
    {
      "phase": "cooldown",
      "name": "child pose",
      "name_id": "Peregangan Child Pose",
      "muscleGroup": "Punggung",
      "durationSeconds": 45,
      "sets": 0,
      "reps": 0,
      "instruction": "Duduk di atas tumit dan bungkukkan tubuh ke lantai sambil menarik napas dalam."
    }
  ]
}
''';

      final responseText = await GeminiService.instance.generateText(prompt);

      if (responseText != null) {
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
        if (match == null) throw Exception('No JSON found');
        final Map<String, dynamic> parsed = jsonDecode(match.group(0)!);

        // Enrich each exercise with local DB data + fetch media URLs
        final mediaService = ExerciseMediaService();
        final List<dynamic> exercises = parsed['exercises'] ?? [];

        for (int i = 0; i < exercises.length; i++) {
          final ex = exercises[i] as Map<String, dynamic>;

          // Pastikan phase terdefinisi
          if (ex['phase'] == null) {
            if (i == 0) {
              ex['phase'] = 'warmup';
            } else if (i == exercises.length - 1) {
              ex['phase'] = 'cooldown';
            } else {
              ex['phase'] = 'main';
            }
          }

          // Enrich from local DB
          final localEx = LocalExerciseDatabase.findByName(ex['name'] ?? '');
          if (localEx != null) {
            ex['muscleGroup'] ??= localEx.target;
            ex['instruction'] ??= localEx.instructions.join(' ');
            ex['localData'] = {
              'difficulty': localEx.difficulty,
              'equipment': localEx.equipment,
              'secondaryMuscles': localEx.secondaryMuscles,
              'defaultSets': localEx.defaultSets,
              'defaultReps': localEx.defaultReps,
              'durationSeconds': localEx.durationSeconds,
            };
          }

          // Fetch media URL
          final mediaUrl = await mediaService.fetchMediaUrl(ex['name'] ?? '');
          ex['mediaUrl'] = mediaUrl;
        }

        // Urutkan ulang memastikan Warmup di awal, Main di tengah, Cooldown di akhir
        _sortExercisesByPhase(parsed);

        // Simpan ke SharedPreferences secara persisten
        await _saveWorkoutToPrefs(parsed);

        if (mounted) {
          setState(() {
            _workoutData = parsed;
            _isLoading = false;
          });
          _fadeCtrl.forward();

          if (forceRegenerate) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✨ Program latihan baru berhasil dibuat & disimpan!'),
                backgroundColor: Color(0xFF059669),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        throw Exception('Response text is null');
      }
    } catch (e) {
      debugPrint('--- WORKOUT AI ERROR --- $e');
      final fallback = _getMockWorkout(
        bmi: provider.bmi,
        hasRunToday: provider.runningDistance >= 0.5,
        targetBurn: (provider.calorieTarget - provider.caloriesBurned).clamp(160, 300),
        muscles: provider.workoutMuscleGroups.isNotEmpty
            ? provider.workoutMuscleGroups.join(', ')
            : 'Seluruh Tubuh',
      );

      // Simpan fallback ke prefs
      await _saveWorkoutToPrefs(fallback);

      if (mounted) {
        setState(() {
          _workoutData = fallback;
          _isLoading = false;
        });
        _fadeCtrl.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Mode offline — program cadangan disesuaikan dengan BMI-mu.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _sortExercisesByPhase(Map<String, dynamic> parsed) {
    final List<dynamic> list = parsed['exercises'] ?? [];
    int phasePriority(String? phase) {
      switch (phase?.toLowerCase()) {
        case 'warmup':
          return 0;
        case 'main':
          return 1;
        case 'cooldown':
          return 2;
        default:
          return 1;
      }
    }

    list.sort((a, b) {
      final pa = phasePriority(a['phase']);
      final pb = phasePriority(b['phase']);
      return pa.compareTo(pb);
    });
    parsed['exercises'] = list;
  }

  Map<String, dynamic> _getMockWorkout({
    required double bmi,
    required bool hasRunToday,
    required int targetBurn,
    required String muscles,
  }) {
    final isJointFriendly = bmi >= 25.0;
    return {
      'title': isJointFriendly
          ? 'Program Ramah Sendi & Kompensasi'
          : hasRunToday
              ? 'Penguatan Otot & Pemulihan'
              : 'Kompensasi Kardio & Kebugaran',
      'totalDurationMinutes': isJointFriendly ? 20 : 22,
      'caloriesBurned': targetBurn,
      'focus': muscles,
      'bmiStatus': isJointFriendly
          ? 'BMI ${bmi.toStringAsFixed(1)} • Ramah Sendi'
          : (bmi < 18.5
              ? 'BMI ${bmi.toStringAsFixed(1)} • Penguatan Massa'
              : 'BMI ${bmi.toStringAsFixed(1)} • Kebugaran Aktif'),
      'bmiAdvice': isJointFriendly
          ? 'Gerakan berbenturan rendah (low-impact) guna melindungi persendian lutut.'
          : 'Kombinasi pembakaran kalori aktif dan penguatan otot seimbang.',
      'activityStatus': hasRunToday ? 'Sudah Lari Hari Ini' : 'Belum Lari Hari Ini',
      'activityAdvice': hasRunToday
          ? 'Fokus latihan dialihkan ke otot pendukung & mobilitas pemulihan.'
          : 'Kompensasi pembakaran kalori ~$targetBurn kkal untuk menjaga defisit energi harian.',
      'notes': [
        isJointFriendly
            ? 'Gerakan dipilih dengan hentakan minimal untuk kenyamanan persendian (Kemenkes RI, 2022).'
            : 'Aktivitas fisik berurutan dari pemanasan hingga pendinginan meningkatkan kebugaran (WHO, 2020).',
        'Pastikan minum air sebelum dan sesudah latihan untuk hidrasi optimal (WHO, 2024).'
      ],
      'citations': ['WHO-PA-FACTSHEET'],
      'exercises': [
        // FASE 1: PEMANASAN
        {
          'phase': 'warmup',
          'name': 'arm circles',
          'name_id': 'Putaran Lengan Dinamis',
          'muscleGroup': 'Bahu',
          'durationSeconds': 30,
          'sets': 0,
          'reps': 0,
          'emoji': '🔄',
          'instruction': 'Rentangkan kedua tangan lalu buat putaran perlahan untuk melumasi persendian bahu.',
        },
        // FASE 2: LATIHAN INTI
        if (isJointFriendly) ...[
          {
            'phase': 'main',
            'name': 'squat',
            'name_id': 'Bodyweight Squat Terkontrol',
            'muscleGroup': 'Quadriceps',
            'durationSeconds': 0,
            'sets': 3,
            'reps': 12,
            'emoji': '🏋️',
            'instruction': 'Turunkan pinggul terkontrol tanpa membebani lutut secara mendadak.',
          },
          {
            'phase': 'main',
            'name': 'incline push up',
            'name_id': 'Push Up Incline (Ramah Sendi)',
            'muscleGroup': 'Dada',
            'durationSeconds': 0,
            'sets': 3,
            'reps': 10,
            'emoji': '💪',
            'instruction': 'Lakukan push-up dengan tangan bertumpu pada bidang lebih tinggi untuk mengurangi beban sendi.',
          },
          {
            'phase': 'main',
            'name': 'plank',
            'name_id': 'Plank Penguat Core',
            'muscleGroup': 'Core',
            'durationSeconds': 35,
            'sets': 0,
            'reps': 0,
            'emoji': '🪵',
            'instruction': 'Tahan posisi tubuh lurus dengan bertumpu pada lengan bawah, kencangkan perut.',
          },
        ] else ...[
          {
            'phase': 'main',
            'name': 'jumping jack',
            'name_id': 'Jumping Jack Kardio',
            'muscleGroup': 'Cardio',
            'durationSeconds': 40,
            'sets': 0,
            'reps': 0,
            'emoji': '⭐',
            'instruction': 'Lompat sambil membuka kaki dan mengangkat tangan untuk memacu pembakaran kalori.',
          },
          {
            'phase': 'main',
            'name': 'push up',
            'name_id': 'Push Up Standar',
            'muscleGroup': 'Dada',
            'durationSeconds': 0,
            'sets': 3,
            'reps': 12,
            'emoji': '💪',
            'instruction': 'Turunkan dada terkontrol lalu dorong kembali ke atas dengan kekuatan dada.',
          },
          {
            'phase': 'main',
            'name': 'squat',
            'name_id': 'Air Squat Dinamis',
            'muscleGroup': 'Quadriceps',
            'durationSeconds': 0,
            'sets': 3,
            'reps': 15,
            'emoji': '🏋️',
            'instruction': 'Buka kaki selebar bahu, dorong pinggul ke belakang dan tegakkan punggung.',
          },
          {
            'phase': 'main',
            'name': 'plank',
            'name_id': 'Isometric Plank',
            'muscleGroup': 'Core',
            'durationSeconds': 40,
            'sets': 0,
            'reps': 0,
            'emoji': '🪵',
            'instruction': 'Tahan tubuh tetap lurus sempurna, aktifkan seluruh otot perut.',
          },
        ],
        // FASE 3: PENDINGINAN
        {
          'phase': 'cooldown',
          'name': 'child pose',
          'name_id': 'Peregangan Punggung & Pinggul',
          'muscleGroup': 'Punggung',
          'durationSeconds': 45,
          'sets': 0,
          'reps': 0,
          'emoji': '🧘',
          'instruction': 'Duduk di atas tumit, condongkan dada ke lantai dan tarik napas perlahan untuk relaksasi total.',
        },
      ],
    };
  }

  // ─── Exercise Swap ─────────────────────────────────────────────────────────
  Future<void> _swapExercise(int index, Map<String, dynamic> oldEx) async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ActivityProvider>();
      final equipment = provider.workoutEquipment ?? 'bodyweight';
      final oldName = oldEx['name_id'] ?? oldEx['name'];
      final phase = oldEx['phase'] ?? 'main';
      final isJointFriendly = provider.bmi >= 25.0;

      final prompt = '''
SEHATI-AI: Pengguna ingin MENGGANTI gerakan "$oldName" pada fase "$phase".
Peralatan tersedia: $equipment.
Karakteristik: ${isJointFriendly ? 'Wajib ramah sendi lutut (low impact)' : 'Standar bugar'}.

Kembalikan HANYA JSON object (tanpa markdown):
{
  "phase": "$phase",
  "name": "nama inggris standar gym",
  "name_id": "Nama Indonesia yang komunikatif",
  "muscleGroup": "Otot Target",
  "durationSeconds": 0,
  "sets": 3,
  "reps": 12,
  "emoji": "💪",
  "instruction": "Instruksi singkat 1-2 kalimat cara melakukan gerakan dengan postur yang benar."
}
''';
      final responseText = await GeminiService.instance.generateText(prompt);
      if (responseText != null) {
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
        if (match == null) throw Exception('No JSON');
        final Map<String, dynamic> newEx = jsonDecode(match.group(0)!);
        newEx['phase'] = phase; // Garansi fase tetap sama
        final mediaUrl =
            await ExerciseMediaService().fetchMediaUrl(newEx['name'] ?? '');
        newEx['mediaUrl'] = mediaUrl;

        if (mounted) {
          setState(() {
            _workoutData!['exercises'][index] = newEx;
            _isLoading = false;
          });
          // Update juga di storage
          await _saveWorkoutToPrefs(_workoutData!);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Diganti: ${newEx['name_id'] ?? newEx['name']}'),
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengganti latihan')));
      }
    }
  }

  void _showRegenerateConfirmDialog() {
    final theme = Theme.of(context);
    final provider = context.read<ActivityProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Buat Ulang Program?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'SEHATI-AI akan mengkalibrasi ulang program latihan berdasarkan data BMI (${provider.bmi.toStringAsFixed(1)}) dan aktivitas lari/langkah terbarumu.',
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _fetchWorkout(forceRegenerate: true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buat Sekarang',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _startActiveWorkout() {
    if (_workoutData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(workoutData: _workoutData!)),
      ).then((_) => setState(() {}));
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? _buildLoadingView(theme, primary)
          : FadeTransition(
              opacity: _fadeAnim,
              child: _buildContent(theme, isDark, primary),
            ),
    );
  }

  Widget _buildLoadingView(ThemeData theme, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 3, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              '🧠 SEHATI-AI sedang mengkalibrasi\nprogram latihan sesuai BMI & aktivitasmu...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Menyusun urutan: Pemanasan ➔ Latihan Inti ➔ Pendinginan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark, Color primary) {
    final exercises =
        List<Map<String, dynamic>>.from(_workoutData!['exercises'] as List);

    // Grouping by phase
    final warmupExercises =
        exercises.where((e) => (e['phase'] ?? 'main') == 'warmup').toList();
    final mainExercises =
        exercises.where((e) => (e['phase'] ?? 'main') == 'main').toList();
    final cooldownExercises =
        exercises.where((e) => (e['phase'] ?? 'main') == 'cooldown').toList();

    final notesRaw = _workoutData?['notes'];
    final citationsRaw = _workoutData?['citations'];
    final notes = (notesRaw is List)
        ? notesRaw.map((e) => e.toString()).toList()
        : const <String>[];
    final citations = (citationsRaw is List)
        ? citationsRaw.map((e) => e.toString()).toList()
        : const <String>[];

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return CustomScrollView(
      slivers: [
        // ── Gradient Header ──
        SliverToBoxAdapter(child: _buildHeader(theme, isDark, primary)),

        // ── Smart Personalization Card (BMI & Defisit Lari) ──
        SliverToBoxAdapter(child: _buildPersonalizationCard(theme, primary)),

        // ── Stats Row ──
        SliverToBoxAdapter(child: _buildStatsRow(theme, primary)),

        // ── Phase 1: Pemanasan (Warm-Up) ──
        if (warmupExercises.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _PhaseHeader(
              phaseNumber: '1',
              title: 'Pemanasan (Warm-Up)',
              subtitle: 'Mempersiapkan persendian & denyut nadi bertahap',
              color: const Color(0xFFF59E0B),
              icon: Icons.wb_sunny_rounded,
              count: warmupExercises.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: warmupExercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final ex = warmupExercises[i];
                final globalIndex = exercises.indexOf(ex);
                return _ExerciseCard(
                  exercise: ex,
                  index: globalIndex,
                  phaseColor: const Color(0xFFF59E0B),
                  onTap: () => _showExerciseDetail(ctx, ex, globalIndex),
                  onSwap: () => _swapExercise(globalIndex, ex),
                );
              },
            ),
          ),
        ],

        // ── Phase 2: Latihan Inti (Core Workout) ──
        if (mainExercises.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _PhaseHeader(
              phaseNumber: '2',
              title: 'Latihan Inti (Core Workout)',
              subtitle: 'Pembakaran kalori kompensasi & penguatan otot',
              color: primary,
              icon: Icons.fitness_center_rounded,
              count: mainExercises.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: mainExercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final ex = mainExercises[i];
                final globalIndex = exercises.indexOf(ex);
                return _ExerciseCard(
                  exercise: ex,
                  index: globalIndex,
                  phaseColor: primary,
                  onTap: () => _showExerciseDetail(ctx, ex, globalIndex),
                  onSwap: () => _swapExercise(globalIndex, ex),
                );
              },
            ),
          ),
        ],

        // ── Phase 3: Pendinginan (Cool-Down) ──
        if (cooldownExercises.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _PhaseHeader(
              phaseNumber: '3',
              title: 'Pendinginan (Cool-Down)',
              subtitle: 'Peregangan statis & pemulihan denyut jantung',
              color: const Color(0xFF10B981),
              icon: Icons.spa_rounded,
              count: cooldownExercises.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: cooldownExercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final ex = cooldownExercises[i];
                final globalIndex = exercises.indexOf(ex);
                return _ExerciseCard(
                  exercise: ex,
                  index: globalIndex,
                  phaseColor: const Color(0xFF10B981),
                  onTap: () => _showExerciseDetail(ctx, ex, globalIndex),
                  onSwap: () => _swapExercise(globalIndex, ex),
                );
              },
            ),
          ),
        ],

        // ── Catatan Medis & Referensi AI ──
        if (notes.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 18, color: primary),
                        const SizedBox(width: 8),
                        Text(
                          'Catatan Pelatih & Rujukan Medis',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...notes.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ',
                                  style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w900)),
                              Expanded(
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.85),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (citations.isNotEmpty)
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
                          icon: const Icon(Icons.menu_book_rounded, size: 16),
                          label: const Text('Lihat Sumber Rujukan',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        // ── Bottom Action CTAs ──
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomPadding + 28),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _startActiveWorkout,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient:
                          const LinearGradient(colors: AppColors.gradientPrimary),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Mulai Latihan Sekarang!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showRegenerateConfirmDialog,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 13),
                    side: BorderSide(color: primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(Icons.autorenew_rounded, color: primary, size: 20),
                  label: Text(
                    'Buat Ulang Program',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Program tersimpan aman dan tidak akan berganti sampai kamu menekan "Buat Ulang Program".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme, bool isDark, Color primary) {
    final title = _workoutData!['title'] ?? 'Program Latihan';
    final focus = _workoutData!['focus'] ?? '';
    final coverImg = getLocalImagePath(focus.isNotEmpty ? focus : 'default');

    return Stack(
      children: [
        // Background cover image
        if (coverImg != null)
          SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.asset(
              coverImg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),

        // Gradient overlay
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: coverImg != null
                  ? [
                      primary.withValues(alpha: 0.92),
                      primary.withValues(alpha: 0.6),
                    ]
                  : [
                      primary,
                      primary.withValues(alpha: 0.75),
                    ],
              begin: Alignment.bottomCenter,
              end: Alignment.topRight,
            ),
          ),
        ),

        // Content
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'SEHATI-AI Coach',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                      shadows: [
                        Shadow(
                            color: Colors.black38,
                            offset: Offset(0, 2),
                            blurRadius: 6)
                      ],
                    ),
                  ),
                  if (focus.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.accessibility_new_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('Fokus: $focus',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Smart Personalization Card (BMI & Defisit Lari) ───────────────────────
  Widget _buildPersonalizationCard(ThemeData theme, Color primary) {
    final provider = context.watch<ActivityProvider>();
    final bmi = provider.bmi;
    final isJointFriendly = bmi >= 25.0;
    final runningKm = provider.runningDistance;
    final hasRunToday = runningKm >= 0.5;

    final bmiStatus = _workoutData?['bmiStatus'] ??
        (isJointFriendly
            ? 'BMI ${bmi.toStringAsFixed(1)} • Ramah Sendi'
            : 'BMI ${bmi.toStringAsFixed(1)} • Kebugaran Aktif');

    final bmiAdvice = _workoutData?['bmiAdvice'] ??
        (isJointFriendly
            ? 'Gerakan berbenturan rendah untuk menjaga sendi lutut tetap aman.'
            : 'Kombinasi latihan kardio dinamis dan penguatan otot.');

    final activityStatus = _workoutData?['activityStatus'] ??
        (hasRunToday
            ? 'Sudah Lari ${runningKm.toStringAsFixed(1)} km'
            : 'Belum Lari Hari Ini');

    final activityAdvice = _workoutData?['activityAdvice'] ??
        (hasRunToday
            ? 'Program difokuskan pada penguatan otot penyangga & pemulihan.'
            : 'Kompensasi pembakaran kalori aktif untuk menggantikan porsi lari.');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.psychology_rounded, size: 18, color: primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Kalibrasi Cerdas Personal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isJointFriendly
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                      : primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isJointFriendly
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                        : primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isJointFriendly ? '🛡️' : '⚖️',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      bmiStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isJointFriendly
                            ? const Color(0xFFD97706)
                            : primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏃', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      activityStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$bmiAdvice $activityAdvice',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow(ThemeData theme, Color primary) {
    final dur = _workoutData!['totalDurationMinutes'] ?? 20;
    final cal = _workoutData!['caloriesBurned'] ?? 180;
    final exCount = (_workoutData!['exercises'] as List).length;
    final provider = context.watch<ActivityProvider>();
    final isJointFriendly = provider.bmi >= 25.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          _StatChip(icon: '⏱️', value: '${dur}m', label: 'Durasi'),
          const SizedBox(width: 8),
          _StatChip(icon: '🔥', value: '$cal kal', label: 'Target'),
          const SizedBox(width: 8),
          _StatChip(
            icon: isJointFriendly ? '🛡️' : '💪',
            value: isJointFriendly ? 'Ramah Sendi' : 'Standar',
            label: 'Proteksi',
          ),
          const SizedBox(width: 8),
          _StatChip(icon: '🎯', value: '$exCount', label: 'Gerakan'),
        ],
      ),
    );
  }

  // ─── Exercise Detail Modal ─────────────────────────────────────────────────
  void _showExerciseDetail(
      BuildContext context, Map<String, dynamic> exercise, int index) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final localData = exercise['localData'] as Map<String, dynamic>?;
    final secondary = localData != null
        ? (localData['secondaryMuscles'] as List<dynamic>?) ?? []
        : [];
    final instructions = exercise['instruction'] as String? ?? '';
    final phase = exercise['phase'] as String? ?? 'main';

    Color phaseColor;
    String phaseLabel;
    if (phase == 'warmup') {
      phaseColor = const Color(0xFFF59E0B);
      phaseLabel = 'Fase 1: Pemanasan';
    } else if (phase == 'cooldown') {
      phaseColor = const Color(0xFF10B981);
      phaseLabel = 'Fase 3: Pendinginan';
    } else {
      phaseColor = primary;
      phaseLabel = 'Fase 2: Latihan Inti';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, sc) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: sc,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        ExerciseYouTubePlayer(
                          exerciseName: exercise['name'] ?? '',
                          height: 220,
                          mediaUrl: exercise['mediaUrl'] as String?,
                          emoji: exercise['emoji'] as String? ?? '🏃',
                          isCover: true,
                        ),
                        const SizedBox(height: 18),
                        // Phase Tag
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: phaseColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                phaseLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: phaseColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Name + muscle tag
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise['name_id'] ??
                                        exercise['name'] ??
                                        'Latihan',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (exercise['name'] != null &&
                                      exercise['name'] != exercise['name_id'])
                                    Text(
                                      exercise['name'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                exercise['muscleGroup'] ?? '',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: primary,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Stat pills
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _DetailPill(
                              icon: Icons.timer_outlined,
                              text: exercise['durationSeconds'] != null &&
                                      exercise['durationSeconds'] > 0
                                  ? _formatDuration(exercise['durationSeconds'])
                                  : '${exercise['sets'] ?? 3} × ${exercise['reps'] ?? 12} reps',
                              color: primary,
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _swapExercise(index, exercise);
                              },
                              icon: Icon(Icons.swap_horiz,
                                  size: 16, color: theme.colorScheme.onSurface),
                              label: Text('Ganti Gerakan',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Secondary muscles
                        if (secondary.isNotEmpty) ...[
                          Text('Otot Sekunder Terlibat',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: secondary
                                .map((m) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.dividerColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(m.toString(),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .textTheme.bodyMedium?.color)),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        // Instructions
                        Text('Petunjuk Gerakan Benar',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 10),
                        Text(
                          instructions.isNotEmpty
                              ? instructions
                              : 'Lakukan gerakan ini sesuai panduan visual di atas. Jaga kestabilan postur untuk hasil maksimal dan menghindari risiko cedera.',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Tutup',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Phase Section Header ──────────────────────────────────────────────────────
class _PhaseHeader extends StatelessWidget {
  final String phaseNumber;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final int count;

  const _PhaseHeader({
    required this.phaseNumber,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count Gerakan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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

// ─── Exercise Card ─────────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final int index;
  final Color phaseColor;
  final VoidCallback onTap;
  final VoidCallback onSwap;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.phaseColor,
    required this.onTap,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final mediaUrl = exercise['mediaUrl'] as String?;
    final muscle = exercise['muscleGroup'] as String? ?? '';
    final hasDuration = (exercise['durationSeconds'] as int? ?? 0) > 0;
    final duration = exercise['durationSeconds'] as int? ?? 0;
    final sets = exercise['sets'] as int? ?? 3;
    final reps = exercise['reps'] as int? ?? 12;
    final metricText = hasDuration
        ? '${duration}s'
        : sets > 0
            ? '$sets×$reps reps'
            : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            // Thumbnail with number tag
            Stack(
              children: [
                ExerciseThumbnail(
                  exerciseName: exercise['name'] ?? '',
                  mediaUrl: mediaUrl,
                  emoji: exercise['emoji'] ?? '🏃',
                  size: 64,
                ),
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: phaseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Exercise Name & Metrics
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name_id'] ?? exercise['name'] ?? 'Latihan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise['name'] != null &&
                      exercise['name'] != exercise['name_id'])
                    Text(
                      exercise['name'],
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (muscle.isNotEmpty) ...[
                        _MiniTag(text: muscle, color: primary),
                        const SizedBox(width: 6),
                      ],
                      if (metricText.isNotEmpty)
                        _MiniTag(
                          text: metricText,
                          color: const Color(0xFF10B981),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.info_outline_rounded,
                      color: primary.withValues(alpha: 0.7), size: 20),
                  onPressed: onTap,
                ),
                const SizedBox(height: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.swap_horiz_rounded,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      size: 20),
                  onPressed: onSwap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatChip(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 3),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Pill ──────────────────────────────────────────────────────────────
class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _DetailPill(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Mini Tag ─────────────────────────────────────────────────────────────────
class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10.5, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
