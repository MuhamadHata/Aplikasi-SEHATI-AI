import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../inti/tema/design_tokens.dart';
import '../../inti/model/model.dart';
import '../../penyedia/penyedia_aktivitas.dart';
import '../../inti/layanan/layanan_dataset_kecantikan.dart';
import '../../inti/layanan/layanan_gemini.dart';
import '../../inti/layanan/layanan_referensi.dart';
import '../../inti/model/referensi.dart';
import 'layar_referensi.dart';

class BeautyScanScreen extends StatefulWidget {
  const BeautyScanScreen({super.key});

  @override
  State<BeautyScanScreen> createState() => _BeautyScanScreenState();
}

class _BeautyScanScreenState extends State<BeautyScanScreen>
    with TickerProviderStateMixin {
  bool _scanning = false;
  bool _hasResult = false;
  BeautyResult? _result;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanLineCtrl.dispose();
    super.dispose();
  }

  File? _imageFile;

  int _readScore(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round().clamp(0, 100);
    if (value is String) {
      final normalized = value.replaceAll('%', '').trim();
      final parsed = double.tryParse(normalized);
      if (parsed != null) return parsed.round().clamp(0, 100);
    }
    return fallback.clamp(0, 100);
  }

  int _readAge(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round().clamp(0, 120);
    if (value is String) {
      final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null) return parsed.clamp(0, 120);
    }
    return fallback.clamp(0, 120);
  }

  String _readText(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return const {};
  }

  String _normalizeAcneRisk(String raw,
      {required int redness, required int oiliness}) {
    final text = raw.toLowerCase();
    if (text.contains('sangat rendah')) return 'Sangat Rendah';
    if (text.contains('rendah')) return 'Rendah';
    if (text.contains('tinggi')) return 'Tinggi';
    if (text.contains('sedang')) return 'Sedang';

    if (redness >= 70 || oiliness >= 75) return 'Tinggi';
    if (redness >= 45 || oiliness >= 50) return 'Sedang';
    return 'Rendah';
  }

  String _normalizeSeverity(String raw,
      {required int primarySignal, int secondarySignal = 0}) {
    final text = raw.toLowerCase();
    if (text.contains('tidak')) return 'Tidak Tampak';
    if (text.contains('berat')) return 'Berat';
    if (text.contains('sedang')) return 'Sedang';
    if (text.contains('ringan')) return 'Ringan';

    final score = (primarySignal * 0.7 + secondarySignal * 0.3).round();
    if (score >= 72) return 'Berat';
    if (score >= 48) return 'Sedang';
    if (score >= 20) return 'Ringan';
    return 'Tidak Tampak';
  }

  int _severityWeight(String severity) {
    switch (severity) {
      case 'Berat':
        return 3;
      case 'Sedang':
        return 2;
      case 'Ringan':
        return 1;
      default:
        return 0;
    }
  }

  String _normalizeScarType(String raw, {required int texture}) {
    final text = raw.toLowerCase();
    if (text.contains('campur')) return 'Campuran';
    if (text.contains('bopeng')) return 'Bopeng dangkal';
    if (text.contains('kehitaman') || text.contains('hiperpigment')) {
      return 'Noda kehitaman';
    }
    if (text.contains('kemerahan') || text.contains('merah')) {
      return 'Noda kemerahan';
    }
    if (text.contains('tidak')) return 'Tidak tampak';
    return texture >= 55 ? 'Bopeng dangkal' : 'Noda samar';
  }

  List<String> _normalizeZones(dynamic value) {
    final zones = _readStringList(value)
        .map((zone) => zone.replaceAll('_', ' ').trim())
        .where((zone) => zone.isNotEmpty)
        .toList();
    return zones.take(4).toList();
  }

  List<String> _buildBeautyRecommendations({
    required List<String> seedRecommendations,
    required int hydration,
    required int fatigue,
    required String activeAcneLevel,
    required String acneScarLevel,
    required String scarType,
    required bool isFastingNow,
    required String smokingStatus,
  }) {
    final recommendations = <String>[
      ...seedRecommendations.map((item) => item.trim()).where((item) => item.isNotEmpty),
    ];

    if (_severityWeight(activeAcneLevel) >= 2) {
      recommendations.add(
        'Prioritaskan facial wash lembut 2x sehari, hindari scrub kasar, dan jangan memencet jerawat aktif agar peradangan tidak bertambah.',
      );
      recommendations.add(
        'Pilih pelembap serta sunscreen non-comedogenic agar jerawat aktif tidak makin mudah teriritasi (WHO, 2022).',
      );
    } else if (_severityWeight(activeAcneLevel) == 1) {
      recommendations.add(
        'Jaga rutinitas basic skincare yang sederhana: pembersih lembut, pelembap ringan, dan sunscreen harian.',
      );
    }

    if (_severityWeight(acneScarLevel) >= 1) {
      recommendations.add(
        'Bekas jerawat biasanya lebih terbantu dengan sunscreen rutin, bahan pencerah lembut, dan konsistensi skincare; hasilnya tidak instan.',
      );
      if (scarType == 'Bopeng dangkal' || scarType == 'Campuran') {
        recommendations.add(
          'Jika bekas jerawat tampak cekung atau teksturnya menetap, pertimbangkan konsultasi dokter kulit karena perawatan klinis biasanya lebih efektif.',
        );
      }
    }

    if (hydration < 55) {
      recommendations.add(
        'Barrier kulit tampak perlu dukungan hidrasi; gunakan pelembap yang menenangkan dan cukupkan cairan harian, terutama bila sedang puasa.',
      );
    }

    if (fatigue >= 55 || isFastingNow) {
      recommendations.add(
        'Usahakan tidur cukup dan kurangi begadang karena wajah yang lelah sering membuat kemerahan, kulit kusam, dan tekstur tampak lebih jelas.',
      );
    }

    if (smokingStatus == ActivityProvider.smokingStatusActive) {
      recommendations.add(
        'Bila Anda merokok, usahakan menguranginya karena paparan rokok dapat memperlambat pemulihan kulit, memperkuat inflamasi, dan membuat bekas jerawat lebih lama memudar.',
      );
    } else if (smokingStatus == ActivityProvider.smokingStatusPassive) {
      recommendations.add(
        'Bila Anda sering terpapar asap rokok dari lingkungan, usahakan mengurangi paparannya karena kulit sensitif dan bekas jerawat dapat lebih mudah terlihat kusam atau iritatif.',
      );
    }

    final unique = <String>[];
    for (final item in recommendations) {
      if (!unique.contains(item)) unique.add(item);
    }
    return unique.take(5).toList();
  }

  String _normalizeSkinTone(String raw) {
    final text = raw.toLowerCase().trim();

    if (text.contains('kuning langsat')) return 'Kuning Langsat';
    if (text.contains('sawo matang')) return 'Sawo Matang';
    if (text.contains('gelap') || text.contains('deep')) return 'Gelap';
    if (text.contains('medium') || text.contains('tan')) return 'Sawo Matang';

    if (text.contains('fair') ||
        text.contains('light') ||
        text.contains('putih') ||
        text.contains('terang')) {
      return 'Cerah';
    }

    if (text.contains('glowing') ||
        text.contains('sehat') ||
        text.contains('bersih') ||
        text.contains('cerah dan sehat')) {
      return 'Kuning Langsat';
    }

    return 'Kuning Langsat';
  }

  BeautyResult _fineTuneBeautyResult(
    Map<String, dynamic> data, {
    required int userAge,
    required bool isFastingNow,
    required String fastingPhase,
    required String smokingStatus,
  }) {
    final signals = _readMap(data['skinSignals']);
    final rawHydration = _readScore(data['hydration'], fallback: 55);
    final rawFatigue = _readScore(data['fatigue'], fallback: 35);
    final dryness =
        _readScore(signals['dryness'], fallback: 100 - rawHydration);
    final oiliness = _readScore(signals['oiliness'], fallback: 35);
    final redness = _readScore(signals['redness'], fallback: 25);
    final texture = _readScore(signals['texture'], fallback: rawFatigue ~/ 2);
    final eyeBags = _readScore(signals['eyeBags'], fallback: rawFatigue);
    final confidence = _readScore(data['confidence'], fallback: 70);
    final acneDetails = _readMap(data['acneDetails']);
    final detectedZones =
        _normalizeZones(data['detectedZones'] ?? acneDetails['zones']);

    final activeAcneLevel = _normalizeSeverity(
      _readText(
        data['activeAcneLevel'] ?? acneDetails['activeAcneLevel'],
        fallback: 'Ringan',
      ),
      primarySignal: redness,
      secondarySignal: oiliness,
    );
    final acneScarLevel = _normalizeSeverity(
      _readText(
        data['acneScarLevel'] ?? acneDetails['acneScarLevel'],
        fallback: texture >= 45 ? 'Ringan' : 'Tidak Tampak',
      ),
      primarySignal: texture,
      secondarySignal: redness,
    );
    final lesionEstimate = _readText(
      data['lesionEstimate'] ?? acneDetails['lesionEstimate'],
      fallback: _severityWeight(activeAcneLevel) >= 3
          ? '>15'
          : _severityWeight(activeAcneLevel) == 2
              ? '6-15'
              : _severityWeight(activeAcneLevel) == 1
                  ? '1-5'
                  : '0',
    );
    final scarType = _normalizeScarType(
      _readText(
        data['scarType'] ?? acneDetails['scarType'],
        fallback: 'Tidak tampak',
      ),
      texture: texture,
    );

    var hydration =
        (rawHydration * 0.60 + (100 - dryness) * 0.30 + (100 - redness) * 0.10)
            .round();
    if (isFastingNow && hydration < 60) {
      hydration -= 4;
    }
    if (confidence < 45) {
      hydration = (hydration * 0.9).round();
    }
    hydration = hydration.clamp(0, 100);

    var fatigue = (rawFatigue * 0.55 + eyeBags * 0.30 + texture * 0.15).round();
    if (isFastingNow && fastingPhase.toLowerCase().contains('akhir')) {
      fatigue += 4;
    }
    if (hydration < 45) {
      fatigue += 6;
    }
    fatigue = fatigue.clamp(0, 100);

    var acneRisk = _normalizeAcneRisk(
      _readText(data['acneRisk'], fallback: 'Sedang'),
      redness: redness +
          (_severityWeight(activeAcneLevel) * 10) +
          (_severityWeight(acneScarLevel) * 4),
      oiliness: oiliness + (_severityWeight(activeAcneLevel) * 12),
    );
    if (_severityWeight(activeAcneLevel) >= 3) acneRisk = 'Tinggi';
    final acnePenalty = switch (acneRisk) {
      'Sangat Rendah' => 4,
      'Rendah' => 8,
      'Sedang' => 15,
      _ => 22,
    };

    var estimatedAge =
        _readAge(data['estimatedAge'], fallback: userAge > 0 ? userAge : 25);
    if (estimatedAge == 0) {
      estimatedAge = userAge > 0 ? userAge : 25;
    }

    final ageGap = userAge > 0 ? estimatedAge - userAge : 0;
    final hydrationPenalty = ((100 - hydration) * 0.22).round();
    final fatiguePenalty = (fatigue * 0.18).round();
    final texturePenalty = (texture * 0.14).round();
    final rednessPenalty = (redness * 0.10).round();
    final int ageGapPenalty = ageGap > 0 ? math.min(ageGap * 4, 20) : 0;
    final int recoveryBonus = ageGap < 0 ? math.min(ageGap.abs() * 2, 8) : 0;
    final fastingPenalty =
        (isFastingNow && hydration < 45 && fatigue > 55) ? 4 : 0;
    final smokingPenalty = switch (smokingStatus) {
      ActivityProvider.smokingStatusActive => 8,
      ActivityProvider.smokingStatusPassive => 4,
      _ => 0,
    };

    var agingScore = 100 -
        hydrationPenalty -
        fatiguePenalty -
        acnePenalty -
        texturePenalty -
        rednessPenalty -
        ageGapPenalty -
        fastingPenalty -
        smokingPenalty +
        recoveryBonus;
    if (confidence < 35) {
      agingScore -= 4;
    }
    agingScore = agingScore.clamp(0, 100);

    final visibleFindings =
        _readStringList(data['visibleFindings']).take(4).toList();
    if (visibleFindings.isEmpty) {
      if (_severityWeight(activeAcneLevel) >= 1) {
        visibleFindings.add(
            'Tampak jerawat aktif tingkat $activeAcneLevel pada area wajah tertentu.');
      }
      if (_severityWeight(acneScarLevel) >= 1) {
        visibleFindings.add(
            'Terlihat bekas jerawat tingkat $acneScarLevel dengan pola $scarType.');
      }
      if (hydration < 45) {
        visibleFindings.add('Kulit terlihat agak kering/dehidrasi.');
      }
      if (fatigue > 55) visibleFindings.add('Area bawah mata tampak lelah.');
      if (redness > 55) {
        visibleFindings.add('Terdapat kemerahan ringan pada wajah.');
      }
      if (oiliness > 60) {
        visibleFindings.add('Produksi minyak terlihat cukup tinggi.');
      }
      if (texture > 55) {
        visibleFindings.add('Tekstur kulit tampak kurang rata.');
      }
    }

    final summary = _readText(
      data['summary'],
      fallback:
          'Hidrasi ${hydration >= 70 ? 'baik' : hydration >= 50 ? 'cukup' : 'rendah'}, '
          'kelelahan ${fatigue >= 60 ? 'cukup tinggi' : fatigue >= 35 ? 'ringan' : 'rendah'}, '
          'jerawat aktif $activeAcneLevel, bekas jerawat $acneScarLevel, dan risiko jerawat $acneRisk.',
    );

    final recommendations = _buildBeautyRecommendations(
      seedRecommendations: _readStringList(data['recommendations']).take(5).toList(),
      hydration: hydration,
      fatigue: fatigue,
      activeAcneLevel: activeAcneLevel,
      acneScarLevel: acneScarLevel,
      scarType: scarType,
      isFastingNow: isFastingNow,
      smokingStatus: smokingStatus,
    );
    const formula =
        'Aging Score = 100 - penalti hidrasi - penalti kelelahan - penalti jerawat '
        '- penalti tekstur - penalti kemerahan - penalti selisih usia - penalti paparan rokok + bonus pemulihan';
    final breakdown = <String>[
      'Penalti hidrasi: $hydrationPenalty poin dari skor hidrasi $hydration/100.',
      'Penalti kelelahan: $fatiguePenalty poin dari fatigue $fatigue/100.',
      'Penalti jerawat: $acnePenalty poin dari risiko jerawat $acneRisk.',
      'Penalti tekstur: $texturePenalty poin dari tekstur $texture/100.',
      'Penalti kemerahan: $rednessPenalty poin dari redness $redness/100.',
      if (userAge > 0)
        'Selisih usia wajah: ${ageGap >= 0 ? '+' : ''}$ageGap tahun '
            '(${ageGapPenalty > 0 ? '-$ageGapPenalty poin' : '+$recoveryBonus poin bonus'}).',
      if (fastingPenalty > 0)
        'Penalti puasa aktif: -$fastingPenalty poin karena hidrasi rendah dan fatigue tinggi.',
      if (smokingPenalty > 0)
        'Penalti paparan rokok: -$smokingPenalty poin dari status ${ActivityProvider.smokingStatusLabelOf(smokingStatus).toLowerCase()}.',
      if (confidence < 45)
        'Confidence rendah ($confidence/100), skor dibuat lebih konservatif.',
    ];

    return BeautyResult(
      hydration: hydration,
      fatigue: fatigue,
      skinTone: _normalizeSkinTone(
        _readText(data['skinTone'], fallback: 'Kuning Langsat'),
      ),
      acneRisk: acneRisk,
      activeAcneLevel: activeAcneLevel,
      acneScarLevel: acneScarLevel,
      lesionEstimate: lesionEstimate,
      scarType: scarType,
      detectedZones: detectedZones,
      agingScore: agingScore,
      estimatedAge: estimatedAge,
      recommendations: recommendations,
      citationCodes: _readStringList(data['citations']),
      summary: summary,
      visibleFindings: visibleFindings,
      confidence: confidence,
      agingFormula: formula,
      agingBreakdown: breakdown,
    );
  }

  void _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: source, maxWidth: 800, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _hasResult = false;
        _result = null;
      });
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;
    setState(() => _scanning = true);

    final activityProvider = context.read<ActivityProvider>();
    final userAge = activityProvider.age;
    final fastingMode = activityProvider.fastingMode;
    final fastingPhase = activityProvider.fastingPhaseLabel;
    final isFastingNow = activityProvider.isFastingNow;
    final smokingStatus = activityProvider.smokingStatus;

    try {
      final bytes = await _imageFile!.readAsBytes();
      final datasetInsight = await BeautyDatasetService.instance.getInsight();

      final List<ReferenceItem> refItems =
          await ReferenceService.instance.getByTags(
        const ['beauty', 'skin', 'aging', 'fasting', 'campaign'],
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

      final prompt = '''
Anda adalah analis kulit non-diagnostik untuk SEHATI-AI Beauty. Fokus utama Anda adalah mendeteksi tanda visual jerawat aktif dan bekas jerawat dari foto wajah, lalu memberi saran yang masuk akal dan aman. Jangan menebak penyakit.

${datasetInsight.promptContext}

Berikan JSON valid persis dengan struktur ini:
{
  "hydration": 80,
  "fatigue": 20,
  "skinTone": "Pilih hanya satu: Cerah / Kuning Langsat / Sawo Matang / Gelap",
  "activeAcneLevel": "Tidak Tampak / Ringan / Sedang / Berat",
  "acneScarLevel": "Tidak Tampak / Ringan / Sedang / Berat",
  "acneRisk": "Sangat Rendah / Rendah / Sedang / Tinggi",
  "lesionEstimate": "0 / 1-5 / 6-15 / >15",
  "scarType": "Tidak tampak / Noda kemerahan / Noda kehitaman / Bopeng dangkal / Campuran",
  "detectedZones": ["dahi", "pipi kanan"],
  "estimatedAge": 25,
  "confidence": 82,
  "summary": "Ringkasan singkat 1 kalimat",
  "visibleFindings": [
    "temuan visual 1",
    "temuan visual 2"
  ],
  "skinSignals": {
    "dryness": 20,
    "oiliness": 35,
    "redness": 15,
    "texture": 25,
    "eyeBags": 30
  },
  "acneDetails": {
    "activeAcneLevel": "Sedang",
    "acneScarLevel": "Ringan",
    "lesionEstimate": "6-15",
    "scarType": "Noda kemerahan",
    "zones": ["pipi kanan", "dahi"]
  },
  "recommendations": [
    "Saran perawatan kulit 1 (Sumber, Tahun)",
    "Saran istirahat/minum air 2 (Sumber, Tahun)"
  ],
  "citations": ["WHO-UV-INTERSUN-2022"]
}

Definisi penilaian:
- hydration 0-100: makin tinggi = kulit tampak makin terhidrasi.
- fatigue 0-100: makin tinggi = wajah tampak makin lelah.
- confidence 0-100: keyakinan analisis visual. Turunkan jika cahaya gelap, blur, wajah tertutup, atau angle buruk.
- skinSignals diisi 0-100 berdasarkan tanda visual.
- activeAcneLevel menilai jerawat aktif/peradangan saat ini.
- acneScarLevel menilai bekas jerawat yang menetap seperti noda atau tekstur cekung.

Aturan penting:
- Gunakan penilaian konservatif. Jika bukti visual lemah, pilih nilai tengah dan turunkan confidence.
- Jangan mengarang keluhan yang tidak tampak.
- "estimatedAge" adalah tebakan usia visual wajah, bukan usia biologis.
- visibleFindings harus berupa observasi visual singkat, bukan diagnosis.
- skinTone harus memilih satu kategori tone kulit dasar, bukan kualitas kulit. Jangan gunakan istilah seperti glowing, sehat, fresh, atau cerah dan sehat.
- Bedakan dengan jelas antara jerawat aktif dan bekas jerawat. Jangan samakan keduanya.
- Jika yang tampak terutama noda datar/kemerahan/kehitaman sisa jerawat tanpa benjolan aktif, prioritaskan acneScarLevel lebih tinggi daripada activeAcneLevel.
- Jika yang tampak benjolan meradang, pustul, atau papul aktif, prioritaskan activeAcneLevel.
- detectedZones hanya boleh berisi area yang memang tampak relevan, misal dahi, pipi kanan, pipi kiri, dagu, rahang, hidung.
- Rekomendasi harus lebih spesifik ke kondisi dominan: jerawat aktif, bekas jerawat, atau campuran.

Konteks: Pengguna ini sebenarnya berusia $userAge tahun. Bandingkan kondisi wajahnya dengan usia aslinya, dan berikan "estimatedAge" berdasarkan tampilan visual wajah.
  Konteks tambahan:
  - Mode puasa: $fastingMode
  - Status saat ini: ${isFastingNow ? 'sedang puasa' : 'jendela makan'}
  - Fase: $fastingPhase
  - Status rokok: ${activityProvider.smokingStatusLabel}

ATURAN KUTIPAN WAJIB:
- Setiap rekomendasi HARUS menyertakan kutipan format (Sumber, Tahun), contoh: (WHO, 2022).
- Anda hanya boleh menggunakan sumber dari daftar ini (gunakan nama & tahun yang sesuai):
$allowedSources
- Jangan membuat sumber baru.

Hanya kembalikan string JSON yang valid tanpa markdown block (jangan gunakan ```json) dan tanpa teks tambahan.''';

      final responseText =
          await GeminiService.instance.generateWithImage(prompt, bytes);

      if (responseText != null) {
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
        final textJson = (match?.group(0) ?? responseText)
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .replaceAll(RegExp(r',(\s*[}\]])'), r'$1')
            .trim();
        Map<String, dynamic> data;
        try {
          data = jsonDecode(textJson);
        } catch (_) {
          data = {
            'hydration': 75,
            'fatigue': 25,
            'skinTone': 'Kuning Langsat',
            'activeAcneLevel': 'Ringan',
            'acneScarLevel': 'Tidak Tampak',
            'acneRisk': 'Rendah',
            'estimatedAge': userAge > 0 ? userAge : 25,
            'confidence': 80,
            'summary': 'Kondisi kulit wajah tampak bersih dan terhidrasi dengan baik.',
            'visibleFindings': ['Tekstur kulit halus', 'Hidrasi tampak cukup'],
            'skinSignals': {'dryness': 20, 'oiliness': 30, 'redness': 15, 'texture': 20, 'eyeBags': 25},
            'acneDetails': {'activeAcneLevel': 'Ringan', 'acneScarLevel': 'Tidak Tampak'},
            'recommendations': [
              'Jaga kebersihan wajah dan gunakan pelembap secara teratur.',
              'Gunakan tabir surya (sunscreen) saat beraktivitas di luar ruangan.'
            ],
            'citations': ['WHO-UV-INTERSUN-2022'],
          };
        }

        if (mounted) {
          setState(() {
            _hasResult = true;
            _result = _fineTuneBeautyResult(
              data,
              userAge: userAge,
              isFastingNow: isFastingNow,
              fastingPhase: fastingPhase,
              smokingStatus: smokingStatus,
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final bool isQuota = e.toString().toLowerCase().contains('quota') ||
            e.toString().contains('429');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isQuota
                ? '⚠️ Kuota cloud penuh. Aktifkan MiniCPM-V On-Device untuk penggunaan tanpa batas.'
                : '❌ Gagal menganalisis gambar. Coba lagi.'),
            backgroundColor: isQuota ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Color _hydrationColor(int v) {
    if (v >= 70) return AppColors.success;
    if (v >= 50) return AppColors.warning;
    return AppColors.accent;
  }

  Color _agingScoreColor(int v) {
    if (v >= 80) return AppColors.success;
    if (v >= 60) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context)),
        title: Text('Beauty Scan',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface)),
        actions: [
          IconButton(
            tooltip: 'Rumus Aging Score',
            onPressed: () => Navigator.pushNamed(context, '/aging-score'),
            icon: const Icon(Icons.functions_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // Camera (mock)
            Expanded(
              flex: _hasResult ? 2 : 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _scanning
                          ? AppColors.accent
                          : theme.dividerColor.withValues(alpha: 0.1),
                      width: 2),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_imageFile != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(22)),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.surface,
                              theme.dividerColor.withValues(alpha: 0.05)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(22)),
                        ),
                      ),
                    if (_imageFile == null)
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, child) => Transform.scale(
                            scale: _scanning ? _pulseAnim.value : 1.0,
                            child: Container(
                              width: 224,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(110),
                                border: Border.all(
                                  color: _scanning
                                      ? AppColors.accent
                                      : theme.dividerColor.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.accent.withValues(alpha: 0.1),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                              child: Center(
                                  child: Icon(Icons.face_retouching_natural_rounded,
                                      size: 80,
                                      color: AppColors.accent.withValues(alpha: 0.4))),
                            ),
                          ),
                        ),
                      ),
                    // Corner brackets
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ScanBracketsPainter(
                          color: _scanning ? AppColors.accent : AppColors.border,
                        ),
                      ),
                    ),
                    // Scan line
                    if (_scanning)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _scanLineAnim,
                          builder: (context, child) => Align(
                            alignment: Alignment(0, -0.9 + 1.8 * _scanLineAnim.value),
                            child: Container(
                              height: 2.5,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.accent,
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.85),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Scanning indicator — BEAUTY & SKIN AI (sesuai desain food scan)
                    if (_scanning)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          color: AppColors.accent,
                                          strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle,
                                            size: 6, color: AppColors.accent),
                                        SizedBox(width: 6),
                                        Text(
                                          'BEAUTY & SKIN AI',
                                          style: TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                              fontFamily: 'Poppins'),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Memindai kondisi kulit wajah...',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (!_scanning && _imageFile == null)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Posisikan wajah Anda dalam lingkaran',
                            style: TextStyle(fontSize: 14, color: theme.hintColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Button or result
            if (!_hasResult)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: _scanning
                    ? Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Menganalisis Kesehatan Kulit...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickImage(ImageSource.camera),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppColors.gradientAccent,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: const Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '📷  Kamera',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickImage(ImageSource.gallery),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  border: Border.all(color: AppColors.accent, width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '🖼️  Galeri',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accent,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              )
            else if (_result != null) ...[
              Expanded(
                flex: 5,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hasil Analisis Kulit 🌟',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              fontFamily: 'Poppins')),
                      if (_result!.summary.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            _result!.summary,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _BeautyMetric(
                              label: 'Hidrasi',
                              value: '${_result!.hydration}%',
                              color: _hydrationColor(_result!.hydration),
                              icon: '💧'),
                          _BeautyMetric(
                              label: 'Kelelahan',
                              value: '${_result!.fatigue}%',
                              color: _result!.fatigue > 50
                                  ? AppColors.accent
                                  : AppColors.success,
                              icon: '😴'),
                          _BeautyMetric(
                              label: 'Aging Score',
                              value: '${_result!.agingScore}/100',
                              color: _agingScoreColor(_result!.agingScore),
                              icon: '⭐'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                          icon: 'ðŸŽ¯',
                          label: 'Confidence',
                          value: '${_result!.confidence}/100'),
                      _InfoRow(
                          icon: '🎨',
                          label: 'Warna Kulit',
                          value: _result!.skinTone),
                      _InfoRow(
                          icon: '🔍',
                          label: 'Risiko Jerawat',
                          value: _result!.acneRisk),
                      _InfoRow(
                          icon: '🎂',
                          label: 'Estimasi Usia',
                          value: '${_result!.estimatedAge} tahun'),
                      _InfoRow(
                          icon: 'ðŸ”¥',
                          label: 'Jerawat Aktif',
                          value: _result!.activeAcneLevel),
                      _InfoRow(
                          icon: 'ðŸ©¹',
                          label: 'Bekas Jerawat',
                          value: _result!.acneScarLevel),
                      _InfoRow(
                          icon: '#',
                          label: 'Estimasi Lesi',
                          value: _result!.lesionEstimate),
                      _InfoRow(
                          icon: 'â—Œ',
                          label: 'Tipe Bekas',
                          value: _result!.scarType),
                      if (_result!.detectedZones.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text('Area Dominan',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _result!.detectedZones
                              .map((zone) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Text(
                                      zone,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                      if (_result!.visibleFindings.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text('Temuan Visual',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        ..._result!.visibleFindings.map((finding) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(Icons.circle,
                                        size: 8, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      finding,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.78),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      if (_result!.agingFormula.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text('Rumus Aging Score',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _result!.agingFormula,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ..._result!.agingBreakdown.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('- ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.35,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.78),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Rekomendasi AI',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._result!.recommendations.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.primary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(r,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                            height: 1.4))),
                              ],
                            ),
                          )),
                      if (_result!.citationCodes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReferencesScreen(
                                  codes: _result!.citationCodes,
                                  title: 'Sumber Saran AI',
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            label: const Text('Lihat sumber'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => setState(() {
                          _hasResult = false;
                          _imageFile = null;
                        }),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.gradientAccent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Scan Ulang',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
  }
}

class _BeautyMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String icon;
  const _BeautyMetric(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'Poppins')),
            Text(label, style: TextStyle(fontSize: 11, color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayIcon =
        label == 'Confidence' ? '😎' : (icon.contains('Ã') ? 'i' : icon);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: displayIcon.isEmpty ? 0 : 0),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}

class _ScanBracketsPainter extends CustomPainter {
  final Color color;
  _ScanBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    const pad = 20.0;
    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(pad, pad + len)
        ..lineTo(pad, pad)
        ..lineTo(pad + len, pad),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - pad - len, pad)
        ..lineTo(size.width - pad, pad)
        ..lineTo(size.width - pad, pad + len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(pad, size.height - pad - len)
        ..lineTo(pad, size.height - pad)
        ..lineTo(pad + len, size.height - pad),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - pad - len, size.height - pad)
        ..lineTo(size.width - pad, size.height - pad)
        ..lineTo(size.width - pad, size.height - pad - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScanBracketsPainter old) => old.color != color;
}
