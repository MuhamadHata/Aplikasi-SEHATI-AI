// ============================================================
// MODEL DATA: CATATAN KADAR GULA DARAH (BLOOD GLUCOSE)
// SEHATI-AI Health Ecosystem
// Berdasarkan Standar PERKENI 2021, ADA 2024, & WHO Guidelines
// ============================================================

import 'package:flutter/material.dart';

/// Kondisi saat pengukuran gula darah dilakukan
enum KondisiPengukuran {
  puasa, // GDP (Gula Darah Puasa ≥8 jam)
  sebelumMakan, // Pre-prandial (sebelum sarapan/makan)
  setelahMakan, // GD2PP (1-2 jam setelah makan)
  sebelumTidur, // Bedtime
  sewaktu, // GDS (Gula Darah Sewaktu / Acak)
}

extension KondisiPengukuranExt on KondisiPengukuran {
  String get label {
    switch (this) {
      case KondisiPengukuran.puasa:
        return 'Puasa (GDP)';
      case KondisiPengukuran.sebelumMakan:
        return 'Sebelum Makan';
      case KondisiPengukuran.setelahMakan:
        return 'Setelah Makan (GD2PP)';
      case KondisiPengukuran.sebelumTidur:
        return 'Sebelum Tidur';
      case KondisiPengukuran.sewaktu:
        return 'Sewaktu (GDS)';
    }
  }

  String get shortLabel {
    switch (this) {
      case KondisiPengukuran.puasa:
        return 'GDP';
      case KondisiPengukuran.sebelumMakan:
        return 'Pre-Meal';
      case KondisiPengukuran.setelahMakan:
        return 'GD2PP';
      case KondisiPengukuran.sebelumTidur:
        return 'Tidur';
      case KondisiPengukuran.sewaktu:
        return 'GDS';
    }
  }

  String get iconEmoji {
    switch (this) {
      case KondisiPengukuran.puasa:
        return '🌅';
      case KondisiPengukuran.sebelumMakan:
        return '🍽️';
      case KondisiPengukuran.setelahMakan:
        return '🍱';
      case KondisiPengukuran.sebelumTidur:
        return '🌙';
      case KondisiPengukuran.sewaktu:
        return '⏱️';
    }
  }

  String get keyName {
    switch (this) {
      case KondisiPengukuran.puasa:
        return 'puasa';
      case KondisiPengukuran.sebelumMakan:
        return 'sebelum_makan';
      case KondisiPengukuran.setelahMakan:
        return 'setelah_makan';
      case KondisiPengukuran.sebelumTidur:
        return 'sebelum_tidur';
      case KondisiPengukuran.sewaktu:
        return 'sewaktu';
    }
  }

  static KondisiPengukuran fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'puasa':
      case 'gdp':
        return KondisiPengukuran.puasa;
      case 'sebelum_makan':
      case 'pre_meal':
        return KondisiPengukuran.sebelumMakan;
      case 'setelah_makan':
      case 'gd2pp':
      case 'post_meal':
        return KondisiPengukuran.setelahMakan;
      case 'sebelum_tidur':
      case 'bedtime':
        return KondisiPengukuran.sebelumTidur;
      case 'sewaktu':
      case 'gds':
      default:
        return KondisiPengukuran.sewaktu;
    }
  }
}

/// Status klasifikasi medis gula darah
enum StatusGulaDarah {
  hipoglikemia, // Terlalu Rendah (< 70 mg/dL)
  normal, // Rentang Normal
  prediabetes, // Waspada / Toleransi Glukosa Terganggu
  tinggi, // Hiperglikemia / Diabetes
  sangatTinggi, // Hiperglikemia Kritis (≥ 250 mg/dL)
}

extension StatusGulaDarahExt on StatusGulaDarah {
  String get label {
    switch (this) {
      case StatusGulaDarah.hipoglikemia:
        return 'Hipoglikemia (Rendah)';
      case StatusGulaDarah.normal:
        return 'Normal (Optimal)';
      case StatusGulaDarah.prediabetes:
        return 'Waspada (Prediabetes)';
      case StatusGulaDarah.tinggi:
        return 'Tinggi (Hiperglikemia)';
      case StatusGulaDarah.sangatTinggi:
        return 'Sangat Tinggi (Kritis)';
    }
  }

  Color get warna {
    switch (this) {
      case StatusGulaDarah.hipoglikemia:
        return const Color(0xFF0284C7); // Sky blue
      case StatusGulaDarah.normal:
        return const Color(0xFF10B981); // Emerald green
      case StatusGulaDarah.prediabetes:
        return const Color(0xFFF59E0B); // Amber / Kuning Waspada
      case StatusGulaDarah.tinggi:
        return const Color(0xFFEF4444); // Red
      case StatusGulaDarah.sangatTinggi:
        return const Color(0xFF991B1B); // Dark deep red
    }
  }

  Color get warnaBg {
    switch (this) {
      case StatusGulaDarah.hipoglikemia:
        return const Color(0xFFE0F2FE);
      case StatusGulaDarah.normal:
        return const Color(0xFFD1FAE5);
      case StatusGulaDarah.prediabetes:
        return const Color(0xFFFEF3C7);
      case StatusGulaDarah.tinggi:
        return const Color(0xFFFEE2E2);
      case StatusGulaDarah.sangatTinggi:
        return const Color(0xFFFEE2E2);
    }
  }

  IconData get icon {
    switch (this) {
      case StatusGulaDarah.hipoglikemia:
        return Icons.arrow_downward_rounded;
      case StatusGulaDarah.normal:
        return Icons.check_circle_outline_rounded;
      case StatusGulaDarah.prediabetes:
        return Icons.warning_amber_rounded;
      case StatusGulaDarah.tinggi:
        return Icons.arrow_upward_rounded;
      case StatusGulaDarah.sangatTinggi:
        return Icons.error_outline_rounded;
    }
  }
}

/// Definisi Faktor-Faktor yang Memengaruhi Kadar Gula Darah
class FaktorPengaruhItem {
  final String key;
  final String label;
  final String emoji;
  final String deskripsi;
  final bool isPenaik; // Menimbulkan lonjakan vs menstabilkan/menurunkan

  const FaktorPengaruhItem({
    required this.key,
    required this.label,
    required this.emoji,
    required this.deskripsi,
    this.isPenaik = true,
  });

  static const List<FaktorPengaruhItem> daftarPilihan = [
    FaktorPengaruhItem(
      key: 'karbo_tinggi',
      label: 'Makan Karbo / Manis',
      emoji: '🍚',
      deskripsi: 'Nasi putih, tepung, minuman manis, boba, kue',
      isPenaik: true,
    ),
    FaktorPengaruhItem(
      key: 'jalan_kaki',
      label: 'Jalan Santai / Olahraga',
      emoji: '🏃',
      deskripsi: 'Jalan kaki 10-15 menit atau olahraga membakar glukosa',
      isPenaik: false,
    ),
    FaktorPengaruhItem(
      key: 'kurang_tidur',
      label: 'Kurang Tidur / Begadang',
      emoji: '😴',
      deskripsi: 'Tidur <6 jam meningkatkan resistensi insulin & kortisol',
      isPenaik: true,
    ),
    FaktorPengaruhItem(
      key: 'stres',
      label: 'Stres / Beban Pikiran',
      emoji: '🧠',
      deskripsi: 'Hormon kortisol dan adrenalin memicu pelepasan glukosa hepar',
      isPenaik: true,
    ),
    FaktorPengaruhItem(
      key: 'minum_obat',
      label: 'Minum Obat / Insulin',
      emoji: '💊',
      deskripsi: 'Konsumsi obat dokter (metformin dll) atau suntik insulin',
      isPenaik: false,
    ),
    FaktorPengaruhItem(
      key: 'dehidrasi',
      label: 'Kurang Minum Air',
      emoji: '💧',
      deskripsi:
          'Dehidrasi membuat konsentrasi glukosa dalam darah lebih pekat',
      isPenaik: true,
    ),
    FaktorPengaruhItem(
      key: 'sedang_sakit',
      label: 'Demam / Sedang Sakit',
      emoji: '🤒',
      deskripsi: 'Respon imun & inflamasi menaikkan gula darah sementara',
      isPenaik: true,
    ),
  ];

  static FaktorPengaruhItem? cariByKey(String key) {
    for (final it in daftarPilihan) {
      if (it.key == key) return it;
    }
    return null;
  }
}

/// Model Entitas Catatan Gula Darah
class CatatanGulaDarah {
  final String id;
  final double nilai; // dalam mg/dL
  final KondisiPengukuran kondisi;
  final List<String>
      faktorPengaruh; // List key faktor (e.g. ['karbo_tinggi', 'jalan_kaki'])
  final DateTime waktu;
  final String? catatan; // Catatan bebas pengguna
  final StatusGulaDarah status;

  CatatanGulaDarah({
    required this.id,
    required this.nilai,
    required this.kondisi,
    this.faktorPengaruh = const [],
    required this.waktu,
    this.catatan,
    StatusGulaDarah? status,
  }) : status = status ?? evaluasiStatus(nilai, kondisi);

  /// Evaluasi Status Medis Berdasarkan PERKENI & ADA
  static StatusGulaDarah evaluasiStatus(
      double nilai, KondisiPengukuran kondisi) {
    // 1. Hipoglikemia berlaku universal jika < 70 mg/dL
    if (nilai < 70) {
      return StatusGulaDarah.hipoglikemia;
    }

    // 2. Sangat Tinggi (Kritis) universal jika >= 250 mg/dL
    if (nilai >= 250) {
      return StatusGulaDarah.sangatTinggi;
    }

    switch (kondisi) {
      case KondisiPengukuran.puasa:
        // Standar GDP (PERKENI): Normal 70-99, Prediabetes 100-125, Diabetes >=126
        if (nilai <= 99) return StatusGulaDarah.normal;
        if (nilai <= 125) return StatusGulaDarah.prediabetes;
        return StatusGulaDarah.tinggi;

      case KondisiPengukuran.sebelumMakan:
        // Pre-prandial: Normal 70-110, Waspada 111-130, Tinggi >130
        if (nilai <= 110) return StatusGulaDarah.normal;
        if (nilai <= 130) return StatusGulaDarah.prediabetes;
        return StatusGulaDarah.tinggi;

      case KondisiPengukuran.setelahMakan:
        // GD2PP: Normal < 140, Prediabetes 140-199, Diabetes >= 200
        if (nilai < 140) return StatusGulaDarah.normal;
        if (nilai <= 199) return StatusGulaDarah.prediabetes;
        return StatusGulaDarah.tinggi;

      case KondisiPengukuran.sebelumTidur:
        // Bedtime target: 100-140 mg/dL
        if (nilai <= 140) return StatusGulaDarah.normal;
        if (nilai <= 160) return StatusGulaDarah.prediabetes;
        return StatusGulaDarah.tinggi;

      case KondisiPengukuran.sewaktu:
        // GDS: Normal < 140, Waspada 140-199, Tinggi >= 200
        if (nilai < 140) return StatusGulaDarah.normal;
        if (nilai <= 199) return StatusGulaDarah.prediabetes;
        return StatusGulaDarah.tinggi;
    }
  }

  /// Saran & Panduan Medis Singkat Sesuai Status & Kondisi
  String get saranSingkat {
    switch (status) {
      case StatusGulaDarah.hipoglikemia:
        return 'Gula darah terlalu rendah (<70 mg/dL). Segera konsumsi 15g karbohidrat cepat serap (contoh: 1 sendok makan gula pasir / ½ gelas jus buah / 3 butir permen) lalu cek kembali dalam 15 menit.';
      case StatusGulaDarah.normal:
        return 'Gula darah stabil dalam rentang aman. Pertahankan pola makan bergizi seimbang dan aktivitas fisik teratur.';
      case StatusGulaDarah.prediabetes:
        if (kondisi == KondisiPengukuran.setelahMakan) {
          return 'Kadar pasca makan sedikit meningkat. Disarankan berjalan santai 10-15 menit untuk membantu penyerapan glukosa oleh otot dan batasi konsumsi minuman manis.';
        }
        return 'Kadar gula berada di zona waspada. Kurangi asupan karbohidrat sederhana, perbanyak serat sayur, dan jaga jam tidur.';
      case StatusGulaDarah.tinggi:
        return 'Kadar gula darah di atas batas normal. Minum cukup air putih untuk mencegah dehidrasi, batasi makanan ber-GI tinggi, dan pastikan meminum obat dokter jika diresepkan.';
      case StatusGulaDarah.sangatTinggi:
        return 'Peringatan: Kadar gula darah sangat tinggi. Hindari aktivitas berat berlebih, perbanyak hidrasi air putih, dan segera konsultasikan dengan dokter jika disertai gejala pusing, mual, atau napas cepat.';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nilai': nilai,
      'kondisi': kondisi.keyName,
      'faktor_pengaruh': faktorPengaruh,
      'waktu': waktu.toIso8601String(),
      'catatan': catatan,
      'status': status.name,
    };
  }

  factory CatatanGulaDarah.fromJson(Map<String, dynamic> json) {
    final rawKondisi = json['kondisi']?.toString() ?? 'sewaktu';
    final rawNilai = (json['nilai'] as num?)?.toDouble() ?? 0.0;
    final rawFaktor =
        (json['faktor_pengaruh'] as List?)?.map((e) => e.toString()).toList() ??
            [];

    final kondisi = KondisiPengukuranExt.fromKey(rawKondisi);

    return CatatanGulaDarah(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nilai: rawNilai,
      kondisi: kondisi,
      faktorPengaruh: rawFaktor,
      waktu:
          DateTime.tryParse(json['waktu']?.toString() ?? '') ?? DateTime.now(),
      catatan: json['catatan']?.toString(),
    );
  }

  CatatanGulaDarah copyWith({
    String? id,
    double? nilai,
    KondisiPengukuran? kondisi,
    List<String> faktorPengaruh = const [],
    DateTime? waktu,
    String? catatan,
  }) {
    return CatatanGulaDarah(
      id: id ?? this.id,
      nilai: nilai ?? this.nilai,
      kondisi: kondisi ?? this.kondisi,
      faktorPengaruh:
          faktorPengaruh.isNotEmpty ? faktorPengaruh : this.faktorPengaruh,
      waktu: waktu ?? this.waktu,
      catatan: catatan ?? this.catatan,
    );
  }
}
