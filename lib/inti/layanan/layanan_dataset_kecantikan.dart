import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class BeautyDatasetInsight {
  final int acneSampleCount;
  final int acneScarSampleCount;

  const BeautyDatasetInsight({
    required this.acneSampleCount,
    required this.acneScarSampleCount,
  });

  String get promptContext => '''
REFERENSI DATASET LOKAL SEHATI-AI BEAUTY:
- Folder "jerawat" memuat sekitar $acneSampleCount contoh gambar untuk referensi jerawat aktif, komedo meradang, dan pola kemerahan/peradangan wajah.
- Folder "bekas jerawat" memuat sekitar $acneScarSampleCount contoh gambar untuk referensi noda pasca-jerawat, bekas kemerahan/kehitaman, dan tekstur bopeng ringan.
- Prioritaskan pemisahan dua kondisi ini: jerawat aktif vs bekas jerawat.
- Gunakan dataset ini sebagai referensi visual pendukung, tetapi tetap konservatif dan hanya laporkan yang benar-benar tampak di foto.
''';
}

class BeautyDatasetService {
  BeautyDatasetService._();
  static final BeautyDatasetService instance = BeautyDatasetService._();

  BeautyDatasetInsight? _cache;

  Future<BeautyDatasetInsight> getInsight() async {
    final existing = _cache;
    if (existing != null) return existing;

    int acneCount = 0;
    int scarCount = 0;

    try {
      final raw = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      final paths = manifest.keys;

      acneCount = paths
          .where((path) => path.startsWith('ai_workspace/dataset/jerawat/'))
          .where(_isImageAsset)
          .length;

      scarCount = paths
          .where(
              (path) => path.startsWith('ai_workspace/dataset/bekas jerawat/'))
          .where(_isImageAsset)
          .length;
    } catch (_) {
      // Optional enhancement only. Keep zero counts if manifest cannot be read.
    }

    final insight = BeautyDatasetInsight(
      acneSampleCount: acneCount,
      acneScarSampleCount: scarCount,
    );
    _cache = insight;
    return insight;
  }

  bool _isImageAsset(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }
}
