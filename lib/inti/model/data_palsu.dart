// ==========================================
// BAGIAN: MODEL DATA
// Berisi definisi struktur data dan objek yang digunakan dalam aplikasi.
// ==========================================

import 'dart:math';
import 'model.dart';

class MockData {
  static final List<FoodItem> foods = [
    const FoodItem(
      id: 1,
      name: 'Nasi Goreng',
      emoji: '🍳',
      calories: 356,
      protein: 8.5,
      carbs: 52,
      fat: 13,
      fiber: 2,
      category: 'Makanan Berat',
      serving: '1 porsi (200g)',
      recommendation: 'Kurangi minyak, tambahkan sayuran lebih banyak.',
    ),
    const FoodItem(
      id: 2,
      name: 'Ayam Bakar',
      emoji: '🍗',
      calories: 215,
      protein: 28,
      carbs: 3,
      fat: 10,
      fiber: 0,
      category: 'Protein',
      serving: '1 potong (120g)',
      recommendation: 'Sumber protein yang baik. Hindari kulit ayam.',
    ),
    const FoodItem(
      id: 3,
      name: 'Gado-Gado',
      emoji: '🥗',
      calories: 290,
      protein: 12,
      carbs: 28,
      fat: 14,
      fiber: 8,
      category: 'Sayuran',
      serving: '1 porsi (250g)',
      recommendation: 'Pilihan sehat! Kaya serat dan vitamin.',
    ),
    const FoodItem(
      id: 4,
      name: 'Mie Goreng',
      emoji: '🍜',
      calories: 375,
      protein: 9,
      carbs: 58,
      fat: 12,
      fiber: 3,
      category: 'Makanan Berat',
      serving: '1 porsi (200g)',
      recommendation: 'Tinggi karbohidrat. Tambahkan telur untuk protein.',
    ),
    const FoodItem(
      id: 5,
      name: 'Pisang',
      emoji: '🍌',
      calories: 89,
      protein: 1.1,
      carbs: 23,
      fat: 0.3,
      fiber: 2.6,
      category: 'Buah',
      serving: '1 buah sedang (118g)',
      recommendation: 'Sumber energi cepat. Baik dikonsumsi sebelum olahraga.',
    ),
    const FoodItem(
      id: 6,
      name: 'Soto Ayam',
      emoji: '🍲',
      calories: 187,
      protein: 18,
      carbs: 12,
      fat: 7,
      fiber: 2,
      category: 'Sup',
      serving: '1 mangkuk (300ml)',
      recommendation: 'Pilihan rendah kalori. Kurangi nasi pendamping.',
    ),
    const FoodItem(
      id: 7,
      name: 'Tempe Goreng',
      emoji: '🫘',
      calories: 193,
      protein: 17,
      carbs: 7,
      fat: 11,
      fiber: 4,
      category: 'Protein Nabati',
      serving: '2 potong (100g)',
      recommendation: 'Superfood lokal! Sumber protein nabati & probiotik.',
    ),
    const FoodItem(
      id: 8,
      name: 'Smoothie Alpukat',
      emoji: '🥑',
      calories: 220,
      protein: 4,
      carbs: 18,
      fat: 15,
      fiber: 7,
      category: 'Minuman',
      serving: '1 gelas (250ml)',
      recommendation: 'Lemak sehat dari alpukat. Kurangi gula tambahan.',
    ),
  ];

  static FoodItem get randomFood => foods[Random().nextInt(foods.length)];

  static final List<BeautyResult> beautyResults = [
    const BeautyResult(
      hydration: 72,
      fatigue: 35,
      skinTone: 'Seimbang',
      acneRisk: 'Rendah',
      activeAcneLevel: 'Ringan',
      acneScarLevel: 'Tidak Tampak',
      lesionEstimate: '1-5',
      scarType: 'Tidak tampak',
      detectedZones: ['dahi'],
      agingScore: 85,
      estimatedAge: 25,
      recommendations: [
        'Tingkatkan konsumsi air putih 8 gelas/hari',
        'Gunakan pelembab dengan SPF 30 setiap pagi',
        'Tidur 7-8 jam untuk regenerasi kulit',
        'Kurangi konsumsi makanan berminyak',
      ],
    ),
    const BeautyResult(
      hydration: 45,
      fatigue: 70,
      skinTone: 'Kurang Cerah',
      acneRisk: 'Sedang',
      activeAcneLevel: 'Sedang',
      acneScarLevel: 'Ringan',
      lesionEstimate: '6-15',
      scarType: 'Noda kemerahan ringan',
      detectedZones: ['pipi kanan', 'pipi kiri'],
      agingScore: 68,
      estimatedAge: 32,
      recommendations: [
        'Perbanyak minum air putih (minimal 2L/hari)',
        'Istirahat cukup, hindari begadang',
        'Konsumsi buah-buahan kaya antioksidan',
        'Rutin bersihkan wajah 2x sehari',
      ],
    ),
    const BeautyResult(
      hydration: 88,
      fatigue: 15,
      skinTone: 'Cerah dan Sehat',
      acneRisk: 'Sangat Rendah',
      activeAcneLevel: 'Tidak Tampak',
      acneScarLevel: 'Ringan',
      lesionEstimate: '0',
      scarType: 'Bekas samar',
      detectedZones: ['pipi kiri'],
      agingScore: 95,
      estimatedAge: 20,
      recommendations: [
        'Pertahankan rutinitas perawatan kulit',
        'Tetap aktif berolahraga minimal 30 menit/hari',
        'Konsumsi makanan kaya omega-3',
        'Lindungi kulit dari paparan sinar UV',
      ],
    ),
  ];

  static BeautyResult get randomBeautyResult =>
      beautyResults[Random().nextInt(beautyResults.length)];

  static const List<Article> articles = [
    Article(
      id: 1,
      title: 'Nutrisi Penting: Superfood Pembentuk Otot dan Energi',
      subtitle: 'Nutrisi & Gizi',
      emoji: '🥑',
      readTime: '5 menit',
      colorHex: 0xFF43E97B,
      imageUrl:
          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=800&auto=format&fit=crop',
      content:
          'Membentuk otot perut (abs) bukan hanya tentang berapa ribu kali Anda melakukan sit-up, tapi justru bergantung besar pada apa yang masuk ke dalam perut Anda! "Abs are made in the kitchen," begitulah pepatah kebugaran populer. Berikut adalah bahan makanan super yang harus Anda prioritaskan:\n\n'
          '1. Telur Utuh (Whole Eggs)\n'
          'Sangat kaya akan leusin, asam amino yang krusial untuk perbaikan jaringan otot. Telur juga tinggi akan kolin dan vitamin B.\n\n'
          '2. Dada Ayam & Dada Kalkun\n'
          'Sumber protein hewani paling efisien tanpa tambahan lemak jahat. Setiap 100 gram daging putih ayam menyumbang rata-rata 31 gram protein berkualitas tinggi.\n\n'
          '3. Yoghurt Yunani (Greek Yogurt)\n'
          'Kombinasi luar biasa dari kasein (protein cerna lambat) dan whey (protein cerna cepat). Sangat baik dikonsumsi sebelum tidur agar tubuh terus memperbaiki otot saat istirahat.\n\n'
          '4. Alpukat & Kacang Almond\n'
          'Jangan takut lemak! Lemak tak jenuh tunggal sangat penting untuk menjaga keseimbangan hormon testosteron, hormon utama pembentuk massa otot pada tubuh.\n\n'
          'Dengan menggabungkan pola makan kaya akan zat di atas, dibarengi istirahat cukup, energi Anda untuk berolahraga akan selalu maksimal!',
    ),
    Article(
      id: 2,
      title: 'HIIT vs Lari Jarak Jauh: Mana yang Lebih Baik Bakar Lemak?',
      subtitle: 'Kebugaran',
      emoji: '🏃',
      readTime: '4 menit',
      colorHex: 0xFF6C63FF,
      imageUrl:
          'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?q=80&w=800&auto=format&fit=crop',
      content:
          'Perdebatan abadi di dunia fitness: Apakah lebih baik melakukan kardio intensitas tinggi (HIIT) selama 15 menit, atau jogging lambat (LISS) selama 1 jam?\n\n'
          'HIIT (High-Intensity Interval Training)\n'
          'Metode ini melibatkan gerakan meledak-ledak dengan durasi pendek, diikuti istirahat singkat. Kelebihan utama HIIT adalah "Afterburn Effect" atau EPOC. Artinya, tubuh Anda akan terus membakar kalori secara tinggi hingga 24 jam SETELAH Anda selesai berolahraga, karena tingginya utang oksigen tubuh.\n\n'
          'Lari Lambat (LISS Cardio)\n'
          'Kardio jenis ini menjaga detak jantung Anda di zona pembakaran lemak (Fat-burn zone) (sekitar 60-70% detak jantung maksimal). Ini sangat aman untuk persendian dan bisa dilakukan lebih lama, membakar kalori masif secara perlahan saat itu juga.\n\n'
          'Kesimpulan:\n'
          'Jika waktu Anda sempit tapi Anda masih bertenaga tinggi, lakukan HIIT. Jika Anda ingin mengistirahatkan sendi dari benturan ekstrem tapi memiliki waktu luang, lari jarak jauh sangat disarankan. Kombinasikan keduanya dalam satu minggu (misal: 2 kali HIIT, 1 kali Jogging) untuk hasil komposisi tubuh paling ideal!',
    ),
    Article(
      id: 3,
      title: 'Pentingnya Tidur Malam Untuk Pemulihan Tubuh',
      subtitle: 'Pemulihan Otot',
      emoji: '😴',
      readTime: '3 menit',
      colorHex: 0xFFFF6584,
      imageUrl:
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?q=80&w=800&auto=format&fit=crop',
      content:
          'Pernahkah Anda sudah makan ekstra sehat, berlatih mati-matian, tapi berat badan tak kunjung turun dan performa olahraga malah memburuk? Bisa jadi, Anda kurang tidur.\n\n'
          'Saat Anda tidur nyenyak, kelenjar pituitari melepaskan Human Growth Hormone (HGH). Hormon perbaikan nomor satu inilah yang merestorasi kembali serat saraf dan merajut kembali otot yang robek (MicroTears) saat Anda latihan angkat beban. Kurang tidur secara drastis menurunkan hormon ini.\n\n'
          'Lebih buruknya, kurang tidur kronis meningkatkan hormon Kortisol! Kortisol bersifat katabolik; yang artinya ia memerintahkan tubuh untuk memecah bongkahan protein (yaitu otot Anda) untuk dijadikan energi cadangan darurat, sekaligus menyimpan lemak di bagian perut tengah.\n\n'
          'Targetkan 7-8 jam per malam. Matikan layar gadget 30 menit sebelum mata terpejam, dan pastikan kondisi ruangan segelap mungkin agar otak Anda memproduksi Melatonin maksimal.',
    ),
    Article(
      id: 4,
      title: 'Rahasia Air Putih Sebagai Pembakar Lemak Alami',
      subtitle: 'Hidrasi',
      emoji: '💧',
      readTime: '2 menit',
      colorHex: 0xFF4FC3F7,
      imageUrl:
          'https://images.unsplash.com/photo-1523362628745-0c100150b504?q=80&w=800&auto=format&fit=crop',
      content:
          'Sering diabaikan, cairan tubuh kita (yang 60%-nya terdiri dari air) memegang peranan vital dalam laju metabolisme.\n\n'
          'Penelitian di The Journal of Clinical Endocrinology & Metabolism menemukan bahwa meminum ekstra 500 mL air putih akan memompa "Mesin Pembakar Lemak" basal tingkat sel dalam badan manusia hingga 30% selama kurang lebih 60-90 menit ke depan.\n\n'
          'Apalagi bila Anda mengonsumsi air es (Suhu dingin). Kenapa?\n'
          'Karena tubuh secara konstan dipaksa membakar ekstra kalori dari stok lemak untuk memanaskan air tersebut hingga menyesuaikan dengan hangat suhu batang tubuh Anda (sekitar 37 derajat Celsius).\n\n'
          'Target Hidrasi\n'
          'Minumlah setidaknya 1 gelas setiap kali Anda bangun tidur, dan selalu minum setiap 15 menit selama Anda berolahraga aktif. Haus adalah tanda Anda sudah TERLAMBAT hidrasi!',
    ),
  ];

  static const List<WorkoutPlan> workouts = [
    WorkoutPlan(
      id: 1,
      name: 'Full Body Burn',
      emoji: '💪',
      duration: '30 min',
      level: 'Pemula',
      calories: 280,
      category: 'Kekuatan',
      exercises: ['Squat 3x15', 'Push-up 3x10', 'Plank 3x30s', 'Lunges 3x12'],
    ),
    WorkoutPlan(
      id: 2,
      name: 'Cardio Blast',
      emoji: '🏃',
      duration: '20 min',
      level: 'Menengah',
      calories: 320,
      category: 'Kardio',
      exercises: [
        'High Knees 4x45s',
        'Jumping Jacks 4x30',
        'Burpees 3x10',
        'Jump Rope 3x60s',
      ],
    ),
    WorkoutPlan(
      id: 3,
      name: 'Yoga & Stretch',
      emoji: '🧘',
      duration: '25 min',
      level: 'Semua Level',
      calories: 130,
      category: 'Fleksibilitas',
      exercises: [
        'Mountain Pose 2x60s',
        'Warrior I & II',
        "Child's Pose 3x30s",
        'Seated Forward Fold',
      ],
    ),
    WorkoutPlan(
      id: 4,
      name: 'HIIT Extreme',
      emoji: '⚡',
      duration: '25 min',
      level: 'Lanjut',
      calories: 450,
      category: 'HIIT',
      exercises: [
        'Sprint Interval 8x20s',
        'Box Jumps 4x12',
        'Kettlebell Swing 3x15',
        'Battle Rope 3x30s',
      ],
    ),
  ];

  static const List<FoodLogEntry> foodLog = [
    FoodLogEntry(
      time: '07:30',
      name: 'Nasi Goreng',
      emoji: '🍳',
      cal: 356,
      meal: 'Sarapan',
    ),
    FoodLogEntry(
      time: '10:00',
      name: 'Smoothie Alpukat',
      emoji: '🥑',
      cal: 220,
      meal: 'Snack',
    ),
    FoodLogEntry(
      time: '12:30',
      name: 'Gado-Gado',
      emoji: '🥗',
      cal: 290,
      meal: 'Makan Siang',
    ),
    FoodLogEntry(
      time: '15:30',
      name: 'Pisang',
      emoji: '🍌',
      cal: 89,
      meal: 'Snack',
    ),
    FoodLogEntry(
      time: '19:00',
      name: 'Soto Ayam',
      emoji: '🍲',
      cal: 187,
      meal: 'Makan Malam',
    ),
    FoodLogEntry(
      time: '20:00',
      name: 'Tempe Goreng',
      emoji: '🫘',
      cal: 193,
      meal: 'Makan Malam',
    ),
  ];
}
