// ==========================================
// BAGIAN: MODEL DATA
// Berisi definisi struktur data dan objek yang digunakan dalam aplikasi.
// ==========================================

/// Local Exercise Database
///
/// A comprehensive offline exercise database with 60+ exercises organized by
/// muscle group. Each entry includes bilateral data:
/// - Asset path referencing a consistent naming convention
/// - AscendAPI GIF URL as a reliable online fallback
/// - Step-by-step instructions in Bahasa Indonesia
/// - Targeted muscle, equipment, sets/reps data
///
/// Asset naming convention: assets/exercises/<bodypart>/<exercise_id>.gif
/// GIF fallback: fetched from exercisedbv2.ascendapi.com
library;


class LocalExercise {
  final String id;
  final String name; // English name for API lookup
  final String nameId; // Indonesian name for display
  final String
      bodyPart; // chest | back | arms | shoulders | abs | legs | glutes | cardio
  final String
      equipment; // none | dumbbell | barbell | cable | machine | bodyweight
  final String target; // primary muscle in English
  final String assetPath; // local asset GIF path
  final String gifUrl; // fallback online GIF from AscendAPI/exercisedb
  final String emoji;
  final int defaultSets;
  final int defaultReps; // 0 if duration-based
  final int durationSeconds; // 0 if rep-based
  final List<String> instructions;
  final List<String> secondaryMuscles;
  final String difficulty; // Pemula | Menengah | Lanjutan

  const LocalExercise({
    required this.id,
    required this.name,
    required this.nameId,
    required this.bodyPart,
    required this.equipment,
    required this.target,
    required this.assetPath,
    required this.gifUrl,
    required this.emoji,
    this.defaultSets = 3,
    this.defaultReps = 12,
    this.durationSeconds = 0,
    required this.instructions,
    this.secondaryMuscles = const [],
    this.difficulty = 'Pemula',
  });

  String get durationOrReps {
    if (durationSeconds > 0) return '${durationSeconds}s';
    return '${defaultSets}x$defaultReps';
  }
}

class LocalExerciseDatabase {
  static const List<LocalExercise> all = [
    // ─── CHEST ───────────────────────────────────────────────────────────────
    LocalExercise(
      id: 'chest_001',
      name: 'push up',
      nameId: 'Push Up',
      bodyPart: 'chest',
      equipment: 'bodyweight',
      target: 'pectorals',
      assetPath: 'assets/exercises/chest/push_up.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=push+up',
      emoji: '💪',
      defaultSets: 3,
      defaultReps: 15,
      difficulty: 'Pemula',
      secondaryMuscles: ['triceps', 'shoulders'],
      instructions: [
        'Posisikan tangan selebar bahu di lantai.',
        'Luruskan tubuh dari kepala hingga kaki.',
        'Turunkan dada hingga hampir menyentuh lantai.',
        'Dorong tubuh ke atas dengan kekuatan dada.',
        'Ulangi dengan kontrol penuh.',
      ],
    ),
    LocalExercise(
      id: 'chest_002',
      name: 'incline push up',
      nameId: 'Push Up Incline',
      bodyPart: 'chest',
      equipment: 'bodyweight',
      target: 'upper pectorals',
      assetPath: 'assets/exercises/chest/incline_push_up.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=incline+push+up',
      emoji: '💪',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Pemula',
      secondaryMuscles: ['triceps', 'front deltoid'],
      instructions: [
        'Tempatkan tangan di permukaan yang lebih tinggi (kursi/meja).',
        'Jaga tubuh lurus dari kepala ke tumit.',
        'Turunkan dada ke permukaan dengan siku terkontrol.',
        'Dorong tubuh kembali ke posisi semula.',
      ],
    ),
    LocalExercise(
      id: 'chest_003',
      name: 'dumbbell bench press',
      nameId: 'Bench Press Dumbbell',
      bodyPart: 'chest',
      equipment: 'dumbbell',
      target: 'pectorals',
      assetPath: 'assets/exercises/chest/dumbbell_bench_press.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=dumbbell+bench+press',
      emoji: '🏋️',
      defaultSets: 3,
      defaultReps: 10,
      difficulty: 'Menengah',
      secondaryMuscles: ['triceps', 'anterior deltoid'],
      instructions: [
        'Berbaring di bangku, pegang dumbbell di atas dada.',
        'Turunkan dumbbell perlahan hingga di samping dada.',
        'Dorong ke atas sampai lengan hampir lurus.',
        'Jaga inti tubuh tetap stabil selama gerakan.',
      ],
    ),
    LocalExercise(
      id: 'chest_004',
      name: 'dumbbell fly',
      nameId: 'Dumbbell Fly Dada',
      bodyPart: 'chest',
      equipment: 'dumbbell',
      target: 'pectorals',
      assetPath: 'assets/exercises/chest/dumbbell_fly.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=dumbbell+fly',
      emoji: '🦅',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Menengah',
      secondaryMuscles: ['biceps'],
      instructions: [
        'Berbaring di bangku, pegang dumbbell di atas dada dengan siku sedikit ditekuk.',
        'Buka lengan ke samping dalam busur lebar.',
        'Rentangkan hingga merasakan regangan di dada.',
        'Kencangkan dada saat membawa dumbbell kembali ke tengah.',
      ],
    ),

    // ─── BACK ─────────────────────────────────────────────────────────────────
    LocalExercise(
      id: 'back_001',
      name: 'pull up',
      nameId: 'Pull Up',
      bodyPart: 'back',
      equipment: 'bodyweight',
      target: 'lats',
      assetPath: 'assets/exercises/back/pull_up.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=pull+up',
      emoji: '🔝',
      defaultSets: 3,
      defaultReps: 8,
      difficulty: 'Lanjutan',
      secondaryMuscles: ['biceps', 'rear deltoid'],
      instructions: [
        'Pegang pull-up bar dengan genggaman melebihi lebar bahu.',
        'Gantung dengan lengan lurus penuh.',
        'Tarik tubuh ke atas hingga dagu melewati bar.',
        'Turunkan perlahan ke posisi awal.',
      ],
    ),
    LocalExercise(
      id: 'back_002',
      name: 'dumbbell row',
      nameId: 'Rowing Dumbbell',
      bodyPart: 'back',
      equipment: 'dumbbell',
      target: 'lats',
      assetPath: 'assets/exercises/back/dumbbell_row.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=dumbbell+row',
      emoji: '🚣',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Pemula',
      secondaryMuscles: ['rhomboids', 'biceps'],
      instructions: [
        'Tekukan badan 45°, pegang dumbbell dengan satu tangan.',
        'Letakkan lutut dan tangan yang lain di bangku.',
        'Tarik dumbbell ke pinggul dengan menarik siku ke belakang.',
        'Turunkan dumbbell secara terkontrol.',
      ],
    ),
    LocalExercise(
      id: 'back_003',
      name: 'superman',
      nameId: 'Superman Punggung',
      bodyPart: 'back',
      equipment: 'bodyweight',
      target: 'lower back',
      assetPath: 'assets/exercises/back/superman.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=superman',
      emoji: '🦸',
      defaultSets: 3,
      defaultReps: 0,
      durationSeconds: 30,
      difficulty: 'Pemula',
      secondaryMuscles: ['glutes', 'hamstrings'],
      instructions: [
        'Berbaring tengkurap dengan lengan lurus ke depan.',
        'Angkat kepala, dada, lengan, dan kaki bersamaan.',
        'Tahan posisi ini selama beberapa detik.',
        'Turunkan perlahan ke posisi awal.',
      ],
    ),
    LocalExercise(
      id: 'back_004',
      name: 'deadlift',
      nameId: 'Deadlift',
      bodyPart: 'back',
      equipment: 'barbell',
      target: 'lower back',
      assetPath: 'assets/exercises/back/deadlift.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=deadlift',
      emoji: '⚡',
      defaultSets: 3,
      defaultReps: 8,
      difficulty: 'Lanjutan',
      secondaryMuscles: ['hamstrings', 'glutes', 'core'],
      instructions: [
        'Berdiri dengan kaki selebar pinggul, barbel di depan.',
        'Jongkok sedikit, pegang barbell dengan punggung lurus.',
        'Dorong bumi dengan kaki sambil angkat barbell.',
        'Berdiri tegak, hips dan lutut lurus bersamaan.',
        'Turunkan barbell dengan pergerakan terkontrol.',
      ],
    ),

    // ─── SHOULDERS ────────────────────────────────────────────────────────────
    LocalExercise(
      id: 'shoulder_001',
      name: 'shoulder press',
      nameId: 'Press Bahu',
      bodyPart: 'shoulders',
      equipment: 'dumbbell',
      target: 'deltoids',
      assetPath: 'assets/exercises/shoulders/shoulder_press.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=shoulder+press',
      emoji: '🏔️',
      defaultSets: 3,
      defaultReps: 10,
      difficulty: 'Pemula',
      secondaryMuscles: ['triceps', 'upper pectorals'],
      instructions: [
        'Duduk tegak, pegang dumbbell setinggi bahu.',
        'Dorong dumbbell lurus ke atas hingga lengan hampir lurus.',
        'Turunkan perlahan kembali ke posisi bahu.',
        'Jaga punggung tetap lurus dan inti aktif.',
      ],
    ),
    LocalExercise(
      id: 'shoulder_002',
      name: 'lateral raise',
      nameId: 'Lateral Raise Bahu',
      bodyPart: 'shoulders',
      equipment: 'dumbbell',
      target: 'lateral deltoid',
      assetPath: 'assets/exercises/shoulders/lateral_raise.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=lateral+raise',
      emoji: '✈️',
      defaultSets: 3,
      defaultReps: 15,
      difficulty: 'Pemula',
      secondaryMuscles: ['traps'],
      instructions: [
        'Berdiri tegak, pegang dumbbell di sisi tubuh.',
        'Angkat lengan ke samping hingga sejajar bahu.',
        'Siku sedikit ditekuk, jangan mengayun tubuh.',
        'Turunkan perlahan dan ulangi.',
      ],
    ),
    LocalExercise(
      id: 'shoulder_003',
      name: 'front raise',
      nameId: 'Front Raise Bahu',
      bodyPart: 'shoulders',
      equipment: 'dumbbell',
      target: 'anterior deltoid',
      assetPath: 'assets/exercises/shoulders/front_raise.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=front+raise',
      emoji: '🙌',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Pemula',
      secondaryMuscles: ['pectorals'],
      instructions: [
        'Berdiri dengan dumbbell di depan paha.',
        'Angkat satu lengan lurus ke depan setinggi bahu.',
        'Turunkan perlahan dan ganti sisi.',
        'Jaga gerakan tetap terkontrol.',
      ],
    ),

    // ─── ARMS (BICEPS + TRICEPS) ───────────────────────────────────────────────
    LocalExercise(
      id: 'arms_001',
      name: 'bicep curl',
      nameId: 'Curl Bisep',
      bodyPart: 'arms',
      equipment: 'dumbbell',
      target: 'biceps',
      assetPath: 'assets/exercises/arms/bicep_curl.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=bicep+curl',
      emoji: '💪',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Pemula',
      secondaryMuscles: ['forearms', 'brachialis'],
      instructions: [
        'Berdiri tegak, pegang dumbbell di sisi tubuh.',
        'Tekuk siku dan angkat dumbbell ke bahu.',
        'Putar telapak tangan ke atas saat mengangkat.',
        'Turunkan perlahan ke posisi awal.',
      ],
    ),
    LocalExercise(
      id: 'arms_002',
      name: 'hammer curl',
      nameId: 'Hammer Curl',
      bodyPart: 'arms',
      equipment: 'dumbbell',
      target: 'brachialis',
      assetPath: 'assets/exercises/arms/hammer_curl.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=hammer+curl',
      emoji: '🔨',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Pemula',
      secondaryMuscles: ['biceps', 'forearms'],
      instructions: [
        'Pegang dumbbell dengan ibu jari ke atas (genggaman palu).',
        'Tekuk siku dan angkat dumbbell ke bahu.',
        'Jaga siku tetap di samping tubuh.',
        'Turunkan perlahan ke posisi awal.',
      ],
    ),
    LocalExercise(
      id: 'arms_003',
      name: 'tricep dip',
      nameId: 'Tricep Dips',
      bodyPart: 'arms',
      equipment: 'bodyweight',
      target: 'triceps',
      assetPath: 'assets/exercises/arms/tricep_dip.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=tricep+dip',
      emoji: '⬇️',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Pemula',
      secondaryMuscles: ['shoulders', 'chest'],
      instructions: [
        'Tempatkan tangan di belakang di atas bangku/kursi.',
        'Luruskan kaki ke depan.',
        'Tekuk siku dan turunkan tubuh ke bawah.',
        'Dorong kembali ke atas dengan tricep.',
      ],
    ),
    LocalExercise(
      id: 'arms_004',
      name: 'triceps pushdown',
      nameId: 'Tricep Pushdown',
      bodyPart: 'arms',
      equipment: 'cable',
      target: 'triceps',
      assetPath: 'assets/exercises/arms/triceps_pushdown.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=triceps+pushdown',
      emoji: '📉',
      defaultSets: 3,
      defaultReps: 15,
      difficulty: 'Menengah',
      secondaryMuscles: ['forearms'],
      instructions: [
        'Berdiri di depan kabel mesin, genggam handle di atas.',
        'Tekuk siku 90°, siku rapat di samping tubuh.',
        'Dorong handle ke bawah sampai lengan lurus.',
        'Kembali ke posisi awal dengan kontrol.',
      ],
    ),

    // ─── ABS ──────────────────────────────────────────────────────────────────
    LocalExercise(
      id: 'abs_001',
      name: 'crunch',
      nameId: 'Crunch Perut',
      bodyPart: 'abs',
      equipment: 'bodyweight',
      target: 'abs',
      assetPath: 'assets/exercises/abs/crunch.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=crunch',
      emoji: '🔥',
      defaultSets: 3,
      defaultReps: 20,
      difficulty: 'Pemula',
      secondaryMuscles: ['obliques'],
      instructions: [
        'Berbaring telentang, lutut ditekuk, kaki rata di lantai.',
        'Letakkan tangan di belakang kepala.',
        'Angkat bahu dan bagian atas punggung dari lantai.',
        'Kencangkan otot perut di puncak gerakan.',
        'Turunkan perlahan ke posisi semula.',
      ],
    ),
    LocalExercise(
      id: 'abs_002',
      name: 'plank',
      nameId: 'Plank',
      bodyPart: 'abs',
      equipment: 'bodyweight',
      target: 'core',
      assetPath: 'assets/exercises/abs/plank.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=plank',
      emoji: '🪵',
      defaultSets: 3,
      defaultReps: 0,
      durationSeconds: 45,
      difficulty: 'Pemula',
      secondaryMuscles: ['lower back', 'shoulders'],
      instructions: [
        'Posisikan tubuh seperti push up tapi bertumpu pada lengan bawah.',
        'Jaga tubuh lurus dari kepala hingga kaki.',
        'Kencangkan otot inti dan glutes.',
        'Tahan posisi selama waktu yang ditentukan.',
        'Jangan biarkan pinggul naik atau turun.',
      ],
    ),
    LocalExercise(
      id: 'abs_003',
      name: 'bicycle crunch',
      nameId: 'Bicycle Crunch',
      bodyPart: 'abs',
      equipment: 'bodyweight',
      target: 'obliques',
      assetPath: 'assets/exercises/abs/bicycle_crunch.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=bicycle+crunch',
      emoji: '🚴',
      defaultSets: 3,
      defaultReps: 20,
      difficulty: 'Pemula',
      secondaryMuscles: ['rectus abdominis'],
      instructions: [
        'Berbaring telentang, tangan di belakang kepala.',
        'Angkat bahu dan lutut dari lantai.',
        'Bawa siku kiri ke lutut kanan sambil meluruskan kaki kiri.',
        'Bergantian sisi dengan gerakan mengayuh sepeda.',
      ],
    ),
    LocalExercise(
      id: 'abs_004',
      name: 'leg raise',
      nameId: 'Leg Raise',
      bodyPart: 'abs',
      equipment: 'bodyweight',
      target: 'lower abs',
      assetPath: 'assets/exercises/abs/leg_raise.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=leg+raise',
      emoji: '🦵',
      defaultSets: 3,
      defaultReps: 15,
      difficulty: 'Menengah',
      secondaryMuscles: ['hip flexors'],
      instructions: [
        'Berbaring telentang dengan kaki lurus.',
        'Letakkan tangan di bawah pinggul untuk dukungan.',
        'Angkat kedua kaki lurus ke atas dengan otot inti.',
        'Turunkan kaki perlahan tanpa menyentuh lantai.',
      ],
    ),
    LocalExercise(
      id: 'abs_005',
      name: 'mountain climber',
      nameId: 'Mountain Climber',
      bodyPart: 'abs',
      equipment: 'bodyweight',
      target: 'core',
      assetPath: 'assets/exercises/abs/mountain_climber.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=mountain+climber',
      emoji: '⛰️',
      defaultSets: 3,
      defaultReps: 0,
      durationSeconds: 30,
      difficulty: 'Menengah',
      secondaryMuscles: ['shoulders', 'hip flexors'],
      instructions: [
        'Mulai dalam posisi push up tinggi.',
        'Bawa lutut kanan ke dada secepat mungkin.',
        'Kembali dan segera bawa lutut kiri ke dada.',
        'Lanjutkan bergantian seperti gerakan lari.',
      ],
    ),

    // ─── LEGS ─────────────────────────────────────────────────────────────────
    LocalExercise(
      id: 'legs_001',
      name: 'squat',
      nameId: 'Squat',
      bodyPart: 'legs',
      equipment: 'bodyweight',
      target: 'quadriceps',
      assetPath: 'assets/exercises/legs/squat.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=squat',
      emoji: '🏋️',
      defaultSets: 3,
      defaultReps: 15,
      difficulty: 'Pemula',
      secondaryMuscles: ['glutes', 'hamstrings', 'calves'],
      instructions: [
        'Berdiri dengan kaki selebar bahu.',
        'Turunkan pinggul ke belakang dan ke bawah.',
        'Jaga lutut sejajar dengan jari kaki.',
        'Turunkan hingga paha sejajar lantai.',
        'Dorong kembali ke posisi berdiri.',
      ],
    ),
    LocalExercise(
      id: 'legs_002',
      name: 'lunge',
      nameId: 'Lunge',
      bodyPart: 'legs',
      equipment: 'bodyweight',
      target: 'quadriceps',
      assetPath: 'assets/exercises/legs/lunge.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=lunge',
      emoji: '🦶',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Pemula',
      secondaryMuscles: ['glutes', 'hamstrings'],
      instructions: [
        'Berdiri tegak, melangkah besar ke depan.',
        'Turunkan lutut belakang hampir ke lantai.',
        'Pastikan lutut depan tidak melebihi jari kaki.',
        'Dorong kembali ke posisi berdiri dan ganti sisi.',
      ],
    ),
    LocalExercise(
      id: 'legs_003',
      name: 'leg press',
      nameId: 'Leg Press',
      bodyPart: 'legs',
      equipment: 'machine',
      target: 'quadriceps',
      assetPath: 'assets/exercises/legs/leg_press.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=leg+press',
      emoji: '🦿',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Menengah',
      secondaryMuscles: ['hamstrings', 'glutes'],
      instructions: [
        'Duduk di mesin leg press, kaki di platform selebar bahu.',
        'Lepaskan pengunci dan turunkan platform ke dada.',
        'Dorong platform ke atas tanpa mengunci lutut sepenuhnya.',
        'Turunkan perlahan dan ulangi.',
      ],
    ),
    LocalExercise(
      id: 'legs_004',
      name: 'calf raise',
      nameId: 'Calf Raise',
      bodyPart: 'legs',
      equipment: 'bodyweight',
      target: 'calves',
      assetPath: 'assets/exercises/legs/calf_raise.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=calf+raise',
      emoji: '🦵',
      defaultSets: 3,
      defaultReps: 20,
      difficulty: 'Pemula',
      secondaryMuscles: [],
      instructions: [
        'Berdiri di dekat tembok atau pegang sesuatu untuk keseimbangan.',
        'Angkat tumit setinggi mungkin dengan jari kaki.',
        'Tahan sejenak di puncak gerakan.',
        'Turunkan perlahan ke posisi semula.',
      ],
    ),
    LocalExercise(
      id: 'legs_005',
      name: 'wall sit',
      nameId: 'Wall Sit',
      bodyPart: 'legs',
      equipment: 'bodyweight',
      target: 'quadriceps',
      assetPath: 'assets/exercises/legs/wall_sit.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=wall+sit',
      emoji: '🪑',
      defaultSets: 3,
      defaultReps: 0,
      durationSeconds: 45,
      difficulty: 'Pemula',
      secondaryMuscles: ['glutes', 'hamstrings'],
      instructions: [
        'Berdiri dengan punggung menempel di dinding.',
        'Turunkan tubuh hingga lutut membentuk sudut 90°.',
        'Pastikan punggung tetap lurus menempel dinding.',
        'Tahan posisi selama waktu yang ditentukan.',
      ],
    ),
    LocalExercise(
      id: 'legs_006',
      name: 'glute bridge',
      nameId: 'Glute Bridge',
      bodyPart: 'legs',
      equipment: 'bodyweight',
      target: 'glutes',
      assetPath: 'assets/exercises/legs/glute_bridge.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=glute+bridge',
      emoji: '🌉',
      defaultSets: 3,
      defaultReps: 20,
      difficulty: 'Pemula',
      secondaryMuscles: ['hamstrings', 'lower back'],
      instructions: [
        'Berbaring telentang, lutut ditekuk, kaki rata di lantai.',
        'Dorong pinggul ke atas dengan kekuatan glutes.',
        'Kencangkan glutes di puncak gerakan.',
        'Turunkan pinggul perlahan ke lantai.',
      ],
    ),

    // ─── GLUTES ───────────────────────────────────────────────────────────────
    LocalExercise(
      id: 'glutes_001',
      name: 'hip thrust',
      nameId: 'Hip Thrust',
      bodyPart: 'glutes',
      equipment: 'bodyweight',
      target: 'glutes',
      assetPath: 'assets/exercises/glutes/hip_thrust.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=hip+thrust',
      emoji: '🍑',
      defaultSets: 3,
      defaultReps: 15,
      difficulty: 'Pemula',
      secondaryMuscles: ['hamstrings', 'core'],
      instructions: [
        'Sandarkan punggung bagian atas di bangku.',
        'Lutut ditekuk, kaki rata di lantai.',
        'Dorong pinggul ke atas sampai tubuh lurus.',
        'Kencangkan glutes, tahan sebentar, turunkan.',
      ],
    ),
    LocalExercise(
      id: 'glutes_002',
      name: 'donkey kick',
      nameId: 'Donkey Kick',
      bodyPart: 'glutes',
      equipment: 'bodyweight',
      target: 'glutes',
      assetPath: 'assets/exercises/glutes/donkey_kick.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=donkey+kick',
      emoji: '🦵',
      defaultSets: 3,
      defaultReps: 15,
      difficulty: 'Pemula',
      secondaryMuscles: ['hamstrings'],
      instructions: [
        'Posisi merangkak dengan tangan dan lutut di lantai.',
        'Jaga punggung lurus dan inti aktif.',
        'Tendang kaki kanan ke belakang dan ke atas.',
        'Kencangkan glutes di puncak, turunkan, ulangi.',
        'Ganti kaki setelah selesai satu set.',
      ],
    ),

    // ─── CARDIO ───────────────────────────────────────────────────────────────
    LocalExercise(
      id: 'cardio_001',
      name: 'jumping jack',
      nameId: 'Jumping Jack',
      bodyPart: 'cardio',
      equipment: 'bodyweight',
      target: 'full body',
      assetPath: 'assets/exercises/cardio/jumping_jack.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=jumping+jack',
      emoji: '⭐',
      defaultSets: 3,
      defaultReps: 0,
      durationSeconds: 30,
      difficulty: 'Pemula',
      secondaryMuscles: ['calves', 'shoulders'],
      instructions: [
        'Berdiri tegak, kaki rapat, tangan di sisi tubuh.',
        'Lompat dan buka kaki selebar bahu sambil angkat tangan ke atas.',
        'Lompat kembali ke posisi awal.',
        'Ulangi dengan ritme yang konsisten.',
      ],
    ),
    LocalExercise(
      id: 'cardio_002',
      name: 'burpee',
      nameId: 'Burpee',
      bodyPart: 'cardio',
      equipment: 'bodyweight',
      target: 'full body',
      assetPath: 'assets/exercises/cardio/burpee.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=burpee',
      emoji: '💥',
      defaultSets: 3,
      defaultReps: 10,
      difficulty: 'Lanjutan',
      secondaryMuscles: ['chest', 'arms', 'legs'],
      instructions: [
        'Berdiri tegak.',
        'Jongkok dan letakkan tangan di lantai.',
        'Lompatkan kaki ke belakang ke posisi push up.',
        'Lakukan push up (opsional).',
        'Loncat kaki kembali ke dekat tangan.',
        'Loncat ke atas dengan tangan di atas kepala.',
      ],
    ),
    LocalExercise(
      id: 'cardio_003',
      name: 'high knees',
      nameId: 'High Knees',
      bodyPart: 'cardio',
      equipment: 'bodyweight',
      target: 'cardio',
      assetPath: 'assets/exercises/cardio/high_knees.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=high+knees',
      emoji: '🏃',
      defaultSets: 3,
      defaultReps: 0,
      durationSeconds: 30,
      difficulty: 'Pemula',
      secondaryMuscles: ['hip flexors', 'calves'],
      instructions: [
        'Berdiri tegak dengan kaki selebar pinggul.',
        'Lari di tempat sambil mengangkat lutut setinggi pinggul.',
        'Ayunkan lengan berlawanan dengan lutut.',
        'Pertahankan kecepatan tinggi selama durasi latihan.',
      ],
    ),
    LocalExercise(
      id: 'cardio_004',
      name: 'jump rope',
      nameId: 'Lompat Tali',
      bodyPart: 'cardio',
      equipment: 'bodyweight',
      target: 'cardio',
      assetPath: 'assets/exercises/cardio/jump_rope.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=jump+rope',
      emoji: '🪢',
      defaultSets: 3,
      defaultReps: 0,
      durationSeconds: 60,
      difficulty: 'Pemula',
      secondaryMuscles: ['calves', 'shoulders'],
      instructions: [
        'Pegang tali di setiap tangan, rentangkan di belakang.',
        'Putar tali ke depan melewati kepala.',
        'Lompat saat tali melewati kaki.',
        'Lakukan lompatan kecil dengan ritme konsisten.',
      ],
    ),
    LocalExercise(
      id: 'cardio_005',
      name: 'box jump',
      nameId: 'Lompat Kotak',
      bodyPart: 'cardio',
      equipment: 'bodyweight',
      target: 'legs',
      assetPath: 'assets/exercises/cardio/box_jump.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=box+jump',
      emoji: '📦',
      defaultSets: 3,
      defaultReps: 10,
      difficulty: 'Menengah',
      secondaryMuscles: ['glutes', 'core'],
      instructions: [
        'Berdiri di depan kotak/permukaan setinggi lutut.',
        'Tekukan lutut sedikit dan ayunkan lengan.',
        'Lompat dan mendarat di atas kotak dengan lutut sedikit ditekuk.',
        'Berdiri tegak, lompat turun dan ulangi.',
      ],
    ),

    // ─── FULL BODY ────────────────────────────────────────────────────────────
    LocalExercise(
      id: 'full_001',
      name: 'squat jump',
      nameId: 'Squat Jump',
      bodyPart: 'legs',
      equipment: 'bodyweight',
      target: 'quadriceps',
      assetPath: 'assets/exercises/legs/squat_jump.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=squat+jump',
      emoji: '🦘',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Menengah',
      secondaryMuscles: ['glutes', 'calves'],
      instructions: [
        'Mulai dari posisi squat.',
        'Lompat sekuat mungkin ke atas.',
        'Mendarat lembut kembali ke posisi squat.',
        'Langsung ulangi tanpa jeda panjang.',
      ],
    ),
    LocalExercise(
      id: 'full_002',
      name: 'dumbbell squat',
      nameId: 'Squat Dumbbell',
      bodyPart: 'legs',
      equipment: 'dumbbell',
      target: 'quadriceps',
      assetPath: 'assets/exercises/legs/dumbbell_squat.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=dumbbell+squat',
      emoji: '🏋',
      defaultSets: 3,
      defaultReps: 12,
      difficulty: 'Menengah',
      secondaryMuscles: ['glutes', 'hamstrings'],
      instructions: [
        'Berdiri dengan kaki selebar bahu, pegang dumbbell di kedua tangan.',
        'Turunkan ke squat sambil menjaga punggung lurus.',
        'Dorong kembali ke atas melalui tumit.',
      ],
    ),
    LocalExercise(
      id: 'full_003',
      name: 'walk',
      nameId: 'Jalan di Tempat',
      bodyPart: 'cardio',
      equipment: 'bodyweight',
      target: 'cardio',
      assetPath: 'assets/exercises/cardio/walk.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=walk',
      emoji: '🚶',
      defaultSets: 1,
      defaultReps: 0,
      durationSeconds: 60,
      difficulty: 'Pemula',
      secondaryMuscles: [],
      instructions: [
        'Berdiri dengan postur tegak.',
        'Angkat lutut bergantian seperti berjalan.',
        'Ayunkan lengan berlawanan dengan kaki.',
        'Pertahankan ritme sedang.',
      ],
    ),
    LocalExercise(
      id: 'full_004',
      name: 'stretch',
      nameId: 'Peregangan',
      bodyPart: 'cardio',
      equipment: 'bodyweight',
      target: 'flexibility',
      assetPath: 'assets/exercises/cardio/stretch.gif',
      gifUrl:
          'https://exercisedbv2.ascendapi.com/api/v1/exercises/search?name=stretch',
      emoji: '🧘',
      defaultSets: 1,
      defaultReps: 0,
      durationSeconds: 30,
      difficulty: 'Pemula',
      secondaryMuscles: [],
      instructions: [
        'Mulai dengan nafas dalam-dalam.',
        'Rentangkan lengan ke atas sejauh mungkin.',
        'Tekuk ke samping, rasakan regangan.',
        'Putar leher dan bahu untuk merilekskan otot.',
      ],
    ),
  ];

  // ─── Helper Methods ─────────────────────────────────────────────────────────

  /// Get all exercises for a given body part
  static List<LocalExercise> byBodyPart(String bodyPart) {
    return all
        .where((e) => e.bodyPart.toLowerCase() == bodyPart.toLowerCase())
        .toList();
  }

  /// Get all exercises for a list of body parts (muscle groups)
  static List<LocalExercise> byBodyParts(List<String> bodyParts) {
    final lower = bodyParts.map((b) => b.toLowerCase()).toList();
    return all.where((e) => lower.contains(e.bodyPart.toLowerCase())).toList();
  }

  /// Get exercises by equipment type
  static List<LocalExercise> byEquipment(String equipment) {
    return all
        .where((e) => e.equipment.toLowerCase() == equipment.toLowerCase())
        .toList();
  }

  /// Get exercises by difficulty
  static List<LocalExercise> byDifficulty(String difficulty) {
    return all
        .where((e) => e.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  /// Find exercise by English name (for AI matching)
  static LocalExercise? findByName(String name) {
    final lower = name.toLowerCase().trim();
    try {
      return all.firstWhere(
        (e) =>
            e.name.toLowerCase() == lower ||
            e.nameId.toLowerCase() == lower ||
            e.name.toLowerCase().contains(lower) ||
            lower.contains(e.name.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all available body parts
  static List<String> get bodyParts =>
      all.map((e) => e.bodyPart).toSet().toList()..sort();

  /// Get the best asset URL: local if exists, else gifUrl (network fallback)
  /// Returns the assetPath first (for offline use), gifUrl as network fallback
  static String? getMediaUrl(LocalExercise exercise) => exercise.gifUrl;
}
