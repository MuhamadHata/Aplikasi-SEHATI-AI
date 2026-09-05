import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../inti/model/catatan_gula_darah.dart';
import '../inti/layanan/layanan_gemini.dart';

class BloodGlucoseProvider extends ChangeNotifier {
  static const String _prefKey = 'sehati_blood_glucose_logs_v1';
  static const String _insightPrefKey = 'sehati_blood_glucose_ai_insight_v1';

  List<CatatanGulaDarah> _daftarCatatan = [];
  bool _isLoading = false;
  bool _isAiAnalyzing = false;
  String? _aiInsight;

  BloodGlucoseProvider() {
    init();
  }

  bool get isLoading => _isLoading;
  bool get isAiAnalyzing => _isAiAnalyzing;
  String? get aiInsight => _aiInsight;
  List<CatatanGulaDarah> get daftarCatatan => List.unmodifiable(_daftarCatatan);

  CatatanGulaDarah? get catatanTerbaru =>
      _daftarCatatan.isNotEmpty ? _daftarCatatan.first : null;

  List<CatatanGulaDarah> filterByKondisi(KondisiPengukuran? k) {
    if (k == null) return List.unmodifiable(_daftarCatatan);
    return _daftarCatatan.where((e) => e.kondisi == k).toList();
  }

  List<CatatanGulaDarah> get catatan7HariTerakhir {
    final threshold = DateTime.now().subtract(const Duration(days: 7));
    return _daftarCatatan.where((e) => e.waktu.isAfter(threshold)).toList();
  }

  List<CatatanGulaDarah> get catatan30HariTerakhir {
    final threshold = DateTime.now().subtract(const Duration(days: 30));
    return _daftarCatatan.where((e) => e.waktu.isAfter(threshold)).toList();
  }

  double get rataRataTotal {
    if (_daftarCatatan.isEmpty) return 0.0;
    final total = _daftarCatatan.fold<double>(0.0, (sum, e) => sum + e.nilai);
    return total / _daftarCatatan.length;
  }

  double get persentaseTimeInRange {
    if (_daftarCatatan.isEmpty) return 0.0;
    final inRange = _daftarCatatan
        .where((e) => e.status == StatusGulaDarah.normal)
        .length;
    return ((inRange / _daftarCatatan.length) * 100).roundToDouble();
  }

  double get nilaiTertinggi {
    if (_daftarCatatan.isEmpty) return 0.0;
    return _daftarCatatan
        .map((e) => e.nilai)
        .reduce((max, val) => val > max ? val : max);
  }

  double get nilaiTerendah {
    if (_daftarCatatan.isEmpty) return 0.0;
    return _daftarCatatan
        .map((e) => e.nilai)
        .reduce((min, val) => val < min ? val : min);
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _muatDariLokal();
    _isLoading = false;
    notifyListeners();

    // Lakukan sinkronisasi data dari Supabase jika user telah login
    await sinkronkanDenganSupabase();
  }

  Future<void> _muatDariLokal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _aiInsight = prefs.getString(_insightPrefKey);
      final rawData = prefs.getString(_prefKey);
      if (rawData != null && rawData.isNotEmpty) {
        final List decoded = jsonDecode(rawData);
        _daftarCatatan = decoded
            .map((item) => CatatanGulaDarah.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _daftarCatatan.sort((a, b) => b.waktu.compareTo(a.waktu));
      }
    } catch (e) {
      debugPrint('[BloodGlucoseProvider] Simpan lokal gagal dimuat: $e');
    }
  }

  Future<void> _simpanKeLokal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_daftarCatatan.map((e) => e.toJson()).toList());
      await prefs.setString(_prefKey, encoded);
      if (_aiInsight != null) {
        await prefs.setString(_insightPrefKey, _aiInsight!);
      }
    } catch (e) {
      debugPrint('[BloodGlucoseProvider] Simpan lokal gagal: $e');
    }
  }

  Future<void> sinkronkanDenganSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('catatan_gula_darah')
          .select()
          .eq('user_id', user.id)
          .order('waktu', ascending: false);

      if (data.isNotEmpty) {
        final remoteLogs = data
            .map((row) => CatatanGulaDarah.fromJson(Map<String, dynamic>.from(row)))
            .toList();

        // Gabungkan dan hindari duplikasi id
        final Map<String, CatatanGulaDarah> merged = {};
        for (final item in _daftarCatatan) {
          merged[item.id] = item;
        }
        for (final item in remoteLogs) {
          merged[item.id] = item;
        }

        _daftarCatatan = merged.values.toList();
        _daftarCatatan.sort((a, b) => b.waktu.compareTo(a.waktu));
        await _simpanKeLokal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[BloodGlucoseProvider] Supabase sync gagal (lanjut lokal): $e');
    }
  }

  Future<void> tambahCatatan({
    required dynamic nilai,
    required dynamic kondisi,
    dynamic faktorPengaruh,
    DateTime? waktu,
    String? catatan,
    String? userName,
    dynamic a,
    dynamic b,
    dynamic c,
    dynamic d,
    CatatanGulaDarah? data,
  }) async {
    CatatanGulaDarah item;
    if (data != null) {
      item = data;
    } else if (a is CatatanGulaDarah) {
      item = a;
    } else {
      final double doubleNilai = nilai is num
          ? nilai.toDouble()
          : (double.tryParse(nilai.toString()) ?? 100.0);

      KondisiPengukuran kondisiEnum = KondisiPengukuran.sewaktu;
      if (kondisi is KondisiPengukuran) {
        kondisiEnum = kondisi;
      } else if (kondisi is String) {
        kondisiEnum = KondisiPengukuranExt.fromKey(kondisi);
      }

      List<String> faktorList = [];
      if (faktorPengaruh is List) {
        faktorList = faktorPengaruh.map((e) => e.toString()).toList();
      }

      item = CatatanGulaDarah(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nilai: doubleNilai,
        kondisi: kondisiEnum,
        faktorPengaruh: faktorList,
        waktu: waktu ?? DateTime.now(),
        catatan: catatan,
      );
    }

    _daftarCatatan.removeWhere((e) => e.id == item.id);
    _daftarCatatan.insert(0, item);
    _daftarCatatan.sort((a, b) => b.waktu.compareTo(a.waktu));
    notifyListeners();
    await _simpanKeLokal();

    // Unggah ke Supabase
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('catatan_gula_darah').upsert({
          'id': item.id,
          'user_id': user.id,
          'nilai': item.nilai,
          'kondisi': item.kondisi.keyName,
          'faktor_pengaruh': item.faktorPengaruh,
          'waktu': item.waktu.toIso8601String(),
          'catatan': item.catatan,
          'status': item.status.name,
        });
      }
    } catch (e) {
      debugPrint('[BloodGlucoseProvider] Supabase insert error: $e');
    }
  }

  Future<void> hapusCatatan([dynamic id]) async {
    final String targetId = id is CatatanGulaDarah ? id.id : id.toString();
    _daftarCatatan.removeWhere((e) => e.id == targetId);
    notifyListeners();
    await _simpanKeLokal();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('catatan_gula_darah')
            .delete()
            .eq('id', targetId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      debugPrint('[BloodGlucoseProvider] Supabase delete error: $e');
    }
  }

  Future<String> generateAiAnalysis({
    String? userName,
    dynamic a,
    dynamic b,
    dynamic list,
  }) async {
    if (_daftarCatatan.isEmpty) {
      _aiInsight =
          'Belum ada catatan gula darah yang cukup untuk dianalisis. Silakan masukkan minimal 1–3 catatan pengukuran untuk evaluasi AI.';
      notifyListeners();
      return _aiInsight!;
    }

    _isAiAnalyzing = true;
    notifyListeners();

    try {
      final name = userName ?? 'Sahabat Sehat';
      final count = _daftarCatatan.length;
      final avg = rataRataTotal.toStringAsFixed(1);
      final tir = persentaseTimeInRange.toStringAsFixed(0);
      final minVal = nilaiTerendah.toStringAsFixed(0);
      final maxVal = nilaiTertinggi.toStringAsFixed(0);

      final buffer = StringBuffer();
      for (final it in _daftarCatatan.take(10)) {
        buffer.writeln(
            '- ${it.waktu.toString().substring(0, 16)} | ${it.kondisi.label}: ${it.nilai} mg/dL (${it.status.label})${it.faktorPengaruh.isNotEmpty ? ' [Faktor: ${it.faktorPengaruh.join(', ')}]' : ''}${it.catatan != null && it.catatan!.isNotEmpty ? ' "${it.catatan}"' : ''}');
      }

      final prompt = '''
Anda adalah Nubi, Konsultan Medis & Glycemic Advisor cerdas di SEHATI-AI.
Standar acuan medis: PERKENI 2021 (Pedoman Pengelolaan dan Pencegahan Diabetes Melitus Tipe 2 di Indonesia) dan ADA 2024 (Standards of Care in Diabetes).

Nama Pengguna: $name
Total Catatan: $count
Rata-rata Gula Darah: $avg mg/dL
Time in Range (TIR Normal): $tir%
Rentang Nilai: $minVal - $maxVal mg/dL

Daftar 10 Pengukuran Terkini:
${buffer.toString()}

Berikan evaluasi glikemik ringkas, terstruktur, ramah, dan solutif (maksimal 3-4 paragraf) yang memuat:
1. Ringkasan status stabilitas gula darah saat ini (apakah stabil, sering spike pasca-makan, atau ada risiko hipoglikemia).
2. Analisis korelasi faktor pemicu (makanan, kurang tidur, stres, atau kurang olahraga) jika tampak dari data.
3. 2-3 Rekomendasi gaya hidup praktis harian yang aplikatif (urutan makan sayur-protein-karbo, jalan santai 15 menit pasca makan, hidrasi).
4. Pengingat edukasi bahwa analisis ini bukan diagnosis pengganti dokter.

Sertakan emoji ramah dan format yang mudah dibaca dengan bullet points.
''';

      final response = await GeminiService.instance.generateText(prompt);
      if (response != null && response.trim().isNotEmpty) {
        _aiInsight = response.trim();
      } else {
        _aiInsight =
            'Hasil analisis AI belum tersedia saat ini. Silakan periksa koneksi internet Anda atau coba beberapa saat lagi.';
      }
      await _simpanKeLokal();
    } catch (e) {
      debugPrint('[BloodGlucoseProvider] AI analysis error: $e');
      _aiInsight =
          'Terjadi kendala saat menganalisis data gula darah. Silakan coba kembali nanti.';
    } finally {
      _isAiAnalyzing = false;
      notifyListeners();
    }

    return _aiInsight ?? '';
  }
}

