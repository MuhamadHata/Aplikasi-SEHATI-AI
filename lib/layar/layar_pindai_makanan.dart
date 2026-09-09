import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../inti/tema/design_tokens.dart';
import '../../penyedia/penyedia_aktivitas.dart';
import '../../inti/model/model.dart';
import '../../inti/layanan/layanan_gemini.dart';
import '../../inti/layanan/layanan_dataset.dart';
import '../../inti/layanan/layanan_referensi.dart';
import '../../inti/model/referensi.dart';
import '../../inti/layanan/layanan_feedback_ai.dart';
import '../../komponen/dialog_koreksi_nutrisi.dart';
import 'package:http/http.dart' as http;
import 'layar_referensi.dart';

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({super.key});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  bool _hasResult = false;
  bool _aiFeedbackSent = false;   // sudah kirim feedback untuk scan ini?
  FoodItem? _result;
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
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
    _scanLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, maxWidth: 800, imageQuality: 70);
      if (picked != null) {
        setState(() {
          _imageFile = picked;
        });
        _analyzeImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    await _startAnalysis(null, null);
  }


  Widget _miniMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style:
                TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _buildRecommendationFor(ParsedFoodNutrition parsed) {
    if (parsed.totalCalories > 700) {
      return 'Porsi ini memiliki asupan kalori cukup tinggi (${parsed.totalCalories} kkal). Seimbangkan dengan aktivitas fisik atau kurangi konsumsi camilan manis pada jadwal makan berikutnya. (Kemenkes RI, 2020)';
    } else if (parsed.totalProtein >= 20.0) {
      return 'Pilihan yang kaya protein (${parsed.totalProtein}g), sangat baik untuk pemulihan otot dan mempertahankan rasa kenyang lebih lama. (WHO, 2020)';
    } else {
      return 'Sesuai dengan komposisi pangan Indonesia. Pastikan asupan cairan dan serat tercukupi sepanjang hari. (Kemenkes RI, 2020)';
    }
  }

  Future<void> _showEditDialog() async {
    if (_result == null) return;

    final nameCtrl = TextEditingController(text: _result!.name);
    final servingCtrl = TextEditingController(text: _result!.serving);

    const quickAddons = [
      'Telur Ceplok',
      'Telur Dadar',
      'Tempe Goreng',
      'Tahu Goreng',
      'Kerupuk Putih',
      'Sambal Bawang',
      'Nasi Putih',
      'Pangsit Goreng',
      'Perkedel',
      'Sate Usus',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return FutureBuilder<ParsedFoodNutrition>(
              future: DatasetService.instance.parseFoodWithAddons(nameCtrl.text),
              builder: (context, snapshot) {
                final parsed = snapshot.data;

                return Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Koreksi & Tambah Lauk',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Nama Makanan (contoh: Mie Gacoan)',
                            hintText: 'Ketik nama makanan...',
                            prefixIcon: const Icon(Icons.restaurant_rounded),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        // Autocomplete suggestions from database
                        FutureBuilder<List<String>>(
                          future: DatasetService.instance.search(
                              nameCtrl.text.split('+').first.trim(),
                              maxResults: 4),
                          builder: (context, searchSnap) {
                            final suggestions = searchSnap.data ?? [];
                            if (suggestions.isEmpty ||
                                nameCtrl.text.trim().isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              margin: const EdgeInsets.only(top: 6),
                              constraints: const BoxConstraints(maxHeight: 120),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: suggestions.length,
                                itemBuilder: (context, i) {
                                  final s = suggestions[i];
                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(s,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    onTap: () {
                                      final parts = nameCtrl.text.split('+');
                                      if (parts.length > 1) {
                                        final addonsPart =
                                            parts.sublist(1).join('+');
                                        nameCtrl.text = '$s + $addonsPart';
                                      } else {
                                        nameCtrl.text = s;
                                      }
                                      setModalState(() {});
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Tambah Lauk / Pelengkap Cepat:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: quickAddons.map((addon) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  avatar: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 16),
                                  label: Text(addon,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  backgroundColor: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFF1F5F9),
                                  onPressed: () {
                                    final currentText = nameCtrl.text.trim();
                                    if (currentText.isEmpty) {
                                      nameCtrl.text = addon;
                                    } else {
                                      nameCtrl.text = '$currentText + $addon';
                                    }
                                    setModalState(() {});
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: servingCtrl,
                          decoration: InputDecoration(
                            labelText: 'Porsi / Kuantitas',
                            hintText: parsed?.serving ?? '1 Porsi',
                            prefixIcon: const Icon(Icons.lunch_dining_rounded),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Live Nutrition & Ingredients Preview Card
                        if (parsed != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(parsed.emoji,
                                        style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            parsed.formattedName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Poppins',
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${parsed.category} • ${parsed.serving}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${parsed.totalCalories} kkal',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _miniMacro('Protein', '${parsed.totalProtein}g',
                                        AppColors.primary),
                                    _miniMacro('Karbo', '${parsed.totalCarbs}g',
                                        AppColors.warning),
                                    _miniMacro('Lemak', '${parsed.totalFat}g',
                                        AppColors.accent),
                                    _miniMacro('Gula', '${parsed.totalSugar}g',
                                        AppColors.error),
                                  ],
                                ),
                                if (parsed.combinedIngredients.isNotEmpty) ...[
                                  const Divider(height: 18),
                                  Text(
                                    'Komposisi & Bahan (${parsed.combinedIngredients.length}):',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    parsed.combinedIngredients.join(', '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final cName = nameCtrl.text.trim();
                                  final cServe = servingCtrl.text.trim();
                                  Navigator.pop(ctx);
                                  if (cName.isNotEmpty) {
                                    _startAnalysis(cName, cServe);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const FittedBox(
                                  child: Text('Scan Ulang AI',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final cName = nameCtrl.text.trim();
                                  final cServe = servingCtrl.text.trim();
                                  if (cName.isEmpty) return;

                                  Navigator.pop(ctx);

                                  if (parsed != null &&
                                      (parsed.isMatchedInDb ||
                                          parsed.addons.isNotEmpty)) {
                                    setState(() {
                                      _result = FoodItem(
                                        id: DateTime.now()
                                            .millisecondsSinceEpoch,
                                        name: parsed.formattedName,
                                        emoji: parsed.emoji,
                                        serving: cServe.isNotEmpty
                                            ? cServe
                                            : parsed.serving,
                                        calories: parsed.totalCalories,
                                        protein: parsed.totalProtein,
                                        carbs: parsed.totalCarbs,
                                        fat: parsed.totalFat,
                                        fiber: parsed.totalFiber,
                                        sugarGrams: parsed.totalSugar,
                                        caffeineMg: parsed.totalCaffeine,
                                        category: parsed.category,
                                        ingredients:
                                            parsed.combinedIngredients,
                                        recommendation:
                                            _buildRecommendationFor(parsed),
                                        citationCodes: const [
                                          'DKPI-KEMKES-2020'
                                        ],
                                      );
                                      _hasResult = true;
                                      _scanning = false;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '✅ Nutrisi diperbarui dari database: ${parsed.formattedName} (${parsed.totalCalories} kkal)'),
                                        backgroundColor: AppColors.success,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  } else {
                                    _startAnalysis(cName, cServe);
                                  }
                                },
                                icon: const Icon(Icons.check_circle_rounded,
                                    size: 18),
                                label: const Text('Simpan (Database)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _startAnalysis(String? forceName, String? forceServing) async {
    if (_imageFile == null) return;

    final activityProvider = context.read<ActivityProvider>();
    final target = activityProvider.calorieTarget;
    final consumed = activityProvider.calorieConsumed;
    final burned = activityProvider.caloriesBurned;
    final remaining = target - consumed + burned;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final fastingMode = activityProvider.fastingMode;
    final fastingPhase = activityProvider.fastingPhaseLabel;
    final isFastingNow = activityProvider.isFastingNow;

    setState(() {
      _scanning = true;
      _hasResult = false;
      _result = null;
    });

    try {
      final bytes = await File(_imageFile!.path).readAsBytes();
      final verifiedCatsList =
          await DatasetService.instance.getVerifiedCategories();
      final verifiedCatsStr = verifiedCatsList.join(', ');
      final visualClues = await DatasetService.instance.getVisualClues();

      String foodName;
      String? yoloServing;
      if (forceName != null && forceName.isNotEmpty) {
        foodName = forceName;
      } else {
        // Step 1A: Identify food using Custom Deep Learning YOLO Model
        String yoloDetectedName = '';
        try {
          // IP 10.0.2.2 is loopback for Android Emulator to host machine
          final uri = Uri.parse('http://10.0.2.2:8000/detect');
          var request = http.MultipartRequest('POST', uri)
            ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
          
          final response = await request.send().timeout(const Duration(milliseconds: 1500));
          if (response.statusCode == 200) {
            final respStr = await response.stream.bytesToString();
            final respJson = jsonDecode(respStr);
            if (respJson['success'] == true && respJson['detected_raw'] != null) {
              final rawMap = respJson['detected_raw'] as Map;
              if (rawMap.isNotEmpty) {
                // Get the most confidently frequently detected item
                var maxEntry = rawMap.entries.first;
                for (var e in rawMap.entries) {
                  if ((e.value as num) > (maxEntry.value as num)) maxEntry = e;
                }
                yoloDetectedName = maxEntry.key.toString();
                yoloServing = "${maxEntry.value} potong/porsi";
              }
            }
          }
        } catch (e) {
          debugPrint('YOLO API skip/timeout (using AI Vision): $e');
        }

        if (yoloDetectedName.isNotEmpty) {
          foodName = yoloDetectedName;
        } else {
          // Step 1B: Fallback using Vision Model
          final namePrompt =
              'Apa nama hidangan atau makanan utama dalam gambar ini?\n'
              'PENTING: Pilih HANYA SATU nama dari daftar "Kategori Terverifikasi" berikut jika cocok secara visual: [$verifiedCatsStr].\n'
              'Gunakan panduan visual berikut untuk membedakan kategori:\n$visualClues\n'
              'Jika tidak ada yang cocok, berikan nama yang paling akurat.\n'
              'Sangat penting: bedakan dengan teliti antara "Martabak Manis" (pancake tebal berpori) dan "Martabak Telur" (isian telur/daging gurih).\n'
              'Jawab HANYA dengan nama makanannya saja tanpa teks tambahan.';

          final nameResponse =
              await GeminiService.instance.generateWithImage(namePrompt, bytes);
          foodName = (nameResponse ?? 'Makanan Terdeteksi')
              .replaceAll('\n', ' ')
              .replaceAll('```', '')
              .trim();
        }
      }

      // Step 2: Search Dataset locally (RAG)
      final datasetData = await DatasetService.instance.findNutrition(foodName);

      // Sources allowed for AI citations (must cite as: (Sumber, Tahun)).
      final List<ReferenceItem> refItems =
          await ReferenceService.instance.getByTags(
        const ['diet', 'sugar', 'beverages', 'activity', 'diabetes', 'fasting'],
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

      // Build sugar/caffeine context based on food name for explicit injection
      final lowerFoodName = foodName.toLowerCase();
      final bool isSweetDrink = lowerFoodName.contains('manis') ||
          lowerFoodName.contains('sirup') ||
          lowerFoodName.contains('soda') ||
          lowerFoodName.contains('susu') ||
          lowerFoodName.contains('jeruk') ||
          lowerFoodName.contains('jus') ||
          lowerFoodName.contains('thai tea') ||
          lowerFoodName.contains('boba') ||
          lowerFoodName.contains('bubble');
      final bool isTea = lowerFoodName.contains('teh') || lowerFoodName.contains('tea');
      final bool isCoffee = lowerFoodName.contains('kopi') || lowerFoodName.contains('coffee') || lowerFoodName.contains('espresso');
      final bool isPlainWater = (lowerFoodName.contains('air') && lowerFoodName.contains('putih')) ||
          lowerFoodName == 'air';

      String sugarHint = '';
      String caffeineHint = '';
      if (!isPlainWater) {
        if (isSweetDrink && isTea) {
          sugarHint = 'NILAI GULA WAJIB: "$foodName" adalah minuman manis yang PASTI mengandung gula tambahan. '
              'sugarGrams HARUS antara 25-35 gram per gelas 250ml. DILARANG KERAS mengisi sugarGrams dengan 0.';
          caffeineHint = 'KAFEIN: Teh mengandung kafein sekitar 40-50mg per 250ml. caffeineMg HARUS antara 40-50.';
        } else if (isSweetDrink) {
          sugarHint = 'NILAI GULA WAJIB: "$foodName" adalah minuman/makanan manis yang mengandung gula signifikan. '
              'sugarGrams HARUS > 15 gram. DILARANG KERAS mengisi sugarGrams dengan 0.';
        } else if (isTea) {
          sugarHint = 'NILAI GULA: Jika teh ini plain/tawar, sugarGrams bisa rendah (1-3g dari gula alami). '
              'Jika ada indikasi manis dari gambar, gunakan 20-35g.';
          caffeineHint = 'KAFEIN: Teh hitam ~47mg, teh hijau ~28mg per 250ml. Isi caffeineMg dengan nilai yang sesuai.';
        } else if (isCoffee) {
          caffeineHint = 'KAFEIN: Kopi hitam ~95-150mg, kopi susu ~60-80mg per 250ml. Isi caffeineMg dengan nilai realistis.';
          if (lowerFoodName.contains('manis') || lowerFoodName.contains('susu') || lowerFoodName.contains('latte')) {
            sugarHint = 'NILAI GULA WAJIB: Kopi manis/susu mengandung 15-25g gula per sajian. sugarGrams HARUS > 10.';
          }
        }
      }

      String systemPrompt =
          'Anda adalah Ahli Gizi Profesional Indonesia dengan pengetahuan mendalam tentang komposisi pangan lokal Indonesia.\n'
          'ATURAN MUTLAK YANG TIDAK BOLEH DILANGGAR:\n'
          '1. Nilai "sugarGrams" adalah gula TOTAL (gula tambahan + gula alami). JANGAN pernah mengembalikan 0 untuk minuman atau makanan yang jelas mengandung gula.\n'
          '2. Gunakan Database Komposisi Pangan Indonesia (DKPI/TKPI) sebagai basis referensi nutrisi.\n'
          '3. Jika nama makanan mengandung kata "manis", "sirup", "susu", atau terlihat berwarna/pekat, sugarGrams PASTI > 10g.\n'
          '4. Untuk minuman teh atau kopi, caffeineMg HARUS diisi dengan nilai nyata (BUKAN 0), kecuali decaf.';

      if (datasetData != null) {
        final dataJson = jsonEncode(datasetData);
        systemPrompt +=
            '\n\nDATA TERVERIFIKASI dari database lokal untuk "$foodName": $dataJson\n'
            'Gunakan angka ini sebagai referensi utama. Sesuaikan dengan konteks gambar.';
      } else {
        systemPrompt +=
            '\n\nREFERENSI GIZI STANDAR INDONESIA (DKPI/TKPI/panganku.org):\n'
            '- Es Teh Manis (1 gelas): kalori ~132 kkal, gula ~30g, kafein ~47mg\n'
            '- Teh Manis Panas (1 gelas): kalori ~60 kkal, gula ~15g, kafein ~47mg\n'
            '- Es Jeruk Manis (1 gelas): kalori ~80 kkal, gula ~22g\n'
            '- Kopi Susu Manis (1 gelas): kalori ~120 kkal, gula ~20g, kafein ~70mg\n'
            '- Nasi Putih (1 porsi 200g): kalori ~260 kkal, protein ~4.8g, karbo ~57g, lemak ~0.5g, gula ~0g\n'
            '- Ayam Goreng (1 potong ~100g): kalori ~250 kkal, protein ~27g, lemak ~15g, karbo ~10g\n'
            'WAJIB menggunakan referensi ini sebagai basis dan menyesuaikan dengan porsi aktual yang terlihat.';
      }

      systemPrompt += '\n\nATURAN KUTIPAN WAJIB:\n'
          '- Setiap kalimat saran kesehatan HARUS menyertakan kutipan format (Sumber, Tahun), contoh: (WHO, 2015).\n'
          '- Anda hanya boleh menggunakan sumber dari daftar ini (gunakan nama & tahun yang sesuai):\n$allowedSources\n'
          '- Jangan membuat sumber baru.\n'
          '- Kembalikan juga array "citations" berisi kode sumber yang Anda gunakan (misal ["WHO-SUGAR-2015"]).';

      // Step 3: Generate detailed nutrition profile using Vision Model (again) to count items
      String servingInstruction = 'PERINTAH PENTING: Lihat kembali gambar makanan tersebut. HITUNG Kuantitas/Jumlah porsi atau potongannya secara spesifik (misalnya jika ada 7 potong martabak telur di piring, maka jumlahnya 7).\nKALIKAN semua angka nutrisi (kalori, protein, lemak, karbohidrat, dll) dengan jumlah yang Anda lihat di gambar.';
      if (forceServing != null && forceServing.isNotEmpty) {
        servingInstruction = 'PERINTAH PENTING: Pengguna telah mengoreksi porsi menjadi "$forceServing". Abaikan perhitungan porsi visual, dan GUNAKAN porsi "$forceServing" ini untuk menghitung total nutrisi.\nKALIKAN semua angka nutrisi (kalori, dll) sesuai dengan porsi "$forceServing" tersebut secara proporsional.';
      } else if (yoloServing != null && yoloServing.isNotEmpty) {
        servingInstruction = 'PERINTAH PENTING: Deteksi AI telah menemukan bahwa makanan ini berjumlah tepat "$yoloServing". JANGAN hitung ulang dari gambar visual. Anda WAJIB menggunakan porsi "$yoloServing" ini sebagai kebenaran mutlak.\nKALIKAN semua angka nutrisi (kalori, dll) dengan jumlah porsi "$yoloServing" tersebut secara proporsional.';
      }

      // Build explicit sugar/caffeine override rules for this specific food
      final String sugarCaffeineRules = (sugarHint.isNotEmpty || caffeineHint.isNotEmpty)
          ? '\n⚠️ ATURAN KHUSUS UNTUK "$foodName" YANG WAJIB DIIKUTI:\n'
              '${sugarHint.isNotEmpty ? "- $sugarHint\n" : ""}'
              '${caffeineHint.isNotEmpty ? "- $caffeineHint\n" : ""}'
          : '';

      final prompt = '''
Berikan profil nutrisi AKURAT berdasarkan Data Komposisi Pangan Indonesia untuk: "$foodName".
$servingInstruction
GABUNGKAN jumlah tersebut ke dalam properti "name" (Contoh: "7 Potong Martabak Telur").
$sugarCaffeineRules
ATURAN KRITIS UNTUK SEMUA FIELD:
- "sugarGrams" = total gula (gula tambahan + gula alami dari bahan). JANGAN isi 0 jika ada bahan manis.
- "caffeineMg" = kandungan kafein nyata. JANGAN isi 0 untuk teh/kopi/minuman berenergi.
- Semua nilai nutrisi HARUS realistis sesuai standar DKPI/TKPI Indonesia.
- "sugarGrams" contoh wajib: Es Teh Manis 1 gelas = 28-32g, Es Jeruk Manis = 22g, Nasi = 0g, Buah Segar = bervariasi.

Kembalikan HANYA JSON valid (tanpa ```json atau teks tambahan):
{
  "name": "Nama Makanan beserta Kuantitas",
  "emoji": "🍵",
  "serving": "1 Gelas (250ml)",
  "calories": 132,
  "protein": 0.3,
  "carbs": 33.0,
  "fat": 0.1,
  "fiber": 0.2,
  "ingredients": ["Teh Hitam", "Gula Pasir", "Es Batu"],
  "sugarGrams": 30.0,
  "caffeineMg": 47,
  "category": "Minuman",
  "recommendation": "Saran gizi. WAJIB sertakan kutipan (Sumber, Tahun) setiap kalimat.",
  "citations": ["WHO-SUGAR-2015"]
}

Konteks Pengguna:
- Waktu: $timeStr
- Sisa kalori: $remaining kkal (Target: $target, Masuk: $consumed, Terbakar: $burned)
- Mode puasa: $fastingMode (${isFastingNow ? 'sedang puasa' : 'jendela makan'}) - Fase: $fastingPhase

Jika malam hari dan makanan tinggi kalori, berikan peringatan ramah.
Jika sugarGrams tinggi (>20g), tambahkan peringatan khusus penderita diabetes.
Jika bukan makanan/minuman, isi semua nilai 0 dan jelaskan di recommendation.
''';

      final responseText = await GeminiService.instance
          .generateWithImage(prompt, bytes, systemPrompt: systemPrompt);

      if (responseText != null) {
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
        final textJson = (match?.group(0) ?? responseText).trim();
        final Map<String, dynamic> data = jsonDecode(textJson);
        if (mounted) {
          setState(() {
            _hasResult = true;
            _result = FoodItem(
              id: DateTime.now().millisecondsSinceEpoch,
              name: data['name'] ?? 'Tidak Dikenali',
              emoji: data['emoji'] ?? '🍽️',
              serving: data['serving'] ?? '-',
              calories: (data['calories'] as num?)?.toInt() ?? 0,
              protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
              carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
              fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
              fiber: (data['fiber'] as num?)?.toDouble() ?? 0.0,
              ingredients: List<String>.from(data['ingredients'] ?? []),
              sugarGrams: (data['sugarGrams'] as num?)?.toDouble() ?? 0.0,
              caffeineMg: (data['caffeineMg'] as num?)?.toInt() ?? 0,
              category: data['category'] ?? 'Umum',
              recommendation: data['recommendation'] ?? 'Tidak ada info.',
              citationCodes: List<String>.from(data['citations'] ?? const []),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Food Scan Error: $e');
      if (mounted) {
        final errStr = e.toString();
        final bool isQuota =
            errStr.toLowerCase().contains('quota') || errStr.contains('429');
        final String msg = isQuota
            ? '⚠️ Kuota AI habis.'
            : '❌ Terjadi kesalahan pada layanan AI. Coba lagi.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: isQuota ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _imageFile = null;
      _hasResult = false;
      _result = null;
      _scanning = false;
      _aiFeedbackSent = false;
    });
  }

  // ── Simpan foto makanan ke direktori lokal ──────────────────────────────
  Future<String?> _saveFoodPhoto(String sourcePath, String foodName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${directory.path}/food_photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = foodName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_')
          .substring(0, foodName.length.clamp(0, 20));
      final extension = sourcePath.split('.').last;
      final newFileName = '${sanitizedName}_$timestamp.$extension';
      final newPath = '${photosDir.path}/$newFileName';

      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(newPath);
        debugPrint('[FoodScan] Foto disimpan: $newPath');
        return newPath;
      }
      return null;
    } catch (e) {
      debugPrint('[FoodScan] Error menyimpan foto: $e');
      return null;
    }
  }

  // ── Tombol feedback AI (konfirmasi / koreksi) ─────────────────────────
  Widget _buildFeedbackRow() {
    final theme = Theme.of(context);
    if (_aiFeedbackSent) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.psychology_outlined, size: 18, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Terima kasih! Koreksi Anda membantu AI belajar lebih baik.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Apakah data AI sudah akurat?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Row(
          children: [
            // Konfirmasi — data benar
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (_result == null) return;
                  final prediction = AIFeedbackService.foodItemToMap(
                    name: _result!.name,
                    serving: _result!.serving,
                    calories: _result!.calories,
                    protein: _result!.protein,
                    carbs: _result!.carbs,
                    fat: _result!.fat,
                    fiber: _result!.fiber,
                    sugarGrams: _result!.sugarGrams,
                    caffeineMg: _result!.caffeineMg,
                  );
                  final ok = await AIFeedbackService.instance.submitConfirmation(
                    foodName: _result!.name,
                    aiPrediction: prediction,
                  );
                  if (ok && mounted) {
                    setState(() => _aiFeedbackSent = true);
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text(
                  'Data Benar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Koreksi — data salah
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (_result == null) return;
                  final prediction = AIFeedbackService.foodItemToMap(
                    name: _result!.name,
                    serving: _result!.serving,
                    calories: _result!.calories,
                    protein: _result!.protein,
                    carbs: _result!.carbs,
                    fat: _result!.fat,
                    fiber: _result!.fiber,
                    sugarGrams: _result!.sugarGrams,
                    caffeineMg: _result!.caffeineMg,
                  );
                  final sent = await tampilkanDialogKoreksiNutrisi(
                    context,
                    foodName: _result!.name,
                    aiPrediction: prediction,
                  );
                  if (sent && mounted) {
                    setState(() => _aiFeedbackSent = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Koreksi dikirim! Terima kasih.'),
                        backgroundColor: AppColors.primary,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'Koreksi AI',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Makanan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sumber',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReferencesScreen(
                  tags: ['diet', 'sugar', 'beverages', 'diabetes'],
                  title: 'Sumber: Gizi & Gula',
                ),
              ),
            ),
            icon: const Icon(Icons.menu_book_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // Camera area
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
                        : theme.dividerColor.withValues(alpha: 0.2),
                    width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient (mock camera) OR Image preview
                  if (_imageFile != null)
                    Image.file(
                      File(_imageFile!.path),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.surface,
                            theme.dividerColor.withValues(alpha: 0.1)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 60,
                              color: theme.hintColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Arahkan Kamera ke Makanan',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Corner brackets
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScanBracketsPainter(
                        color: _scanning ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  ),
                  // Scan line
                  if (_scanning)
                    AnimatedBuilder(
                      animation: _scanLineAnim,
                      builder: (context, child) => Positioned(
                        top: MediaQuery.of(context).size.height * 0.025 +
                            _scanLineAnim.value * 260,
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary,
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  // Scanning indicator — FOOD NUTRITION AI (sesuai desain)
                  if (_scanning)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
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
                                      Icon(Icons.circle, size: 6, color: Color(0xFF38BDF8)),
                                      SizedBox(width: 6),
                                      Text(
                                        'FOOD NUTRITION AI',
                                        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontFamily: 'Poppins'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Memindai objek makanan...',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Scan button or result
          if (!_hasResult) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: _scanning
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.18), shape: BoxShape.circle),
                            child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Menganalisis Nutrisi Makanan...',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
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
                                  colors: AppColors.gradientPrimary,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
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
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: theme.dividerColor
                                        .withValues(alpha: 0.2),
                                    width: 1.5),
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '🖼️  Galeri',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
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
            ),
          ] else if (_result != null) ...[
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      Row(
                        children: [
                          Text(
                            _result!.emoji,
                            style: const TextStyle(fontSize: 43),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _result!.name,
                                        style: TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.onSurface,
                                          fontFamily: 'Poppins',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _showEditDialog,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_note,
                                              size: 26,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Edit',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.primary,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_result!.category} • ${_result!.serving}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_result!.calories} kkal',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _MacroChip(
                            label: 'Protein',
                            value: '${_result!.protein}g',
                            color: AppColors.primary,
                          ),
                          _MacroChip(
                            label: 'Karbo',
                            value: '${_result!.carbs}g',
                            color: AppColors.warning,
                          ),
                          _MacroChip(
                            label: 'Lemak',
                            value: '${_result!.fat}g',
                            color: AppColors.accent,
                          ),
                          _MacroChip(
                            label: 'Serat',
                            value: '${_result!.fiber}g',
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, size: 22, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _result!.recommendation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      if (_result!.ingredients.isNotEmpty) ...[
                        const Text('Bahan Utama:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _result!.ingredients.join(', '),
                          style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DetailChip(
                              icon: '🍬',
                              label: 'Gula',
                              value: '${_result!.sugarGrams}g',
                              color: _result!.sugarGrams > 20
                                  ? AppColors.error
                                  : AppColors.info),
                          if (_result!.caffeineMg > 0)
                            _DetailChip(
                                icon: '☕',
                                label: 'Kafein',
                                value: '${_result!.caffeineMg}mg',
                                color: AppColors.warning),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // ── Feedback AI row ─────────────────────────────
                      _buildFeedbackRow(),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _reset,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: theme.dividerColor
                                          .withValues(alpha: 0.1)),
                                ),
                                child: Center(
                                  child: Text(
                                    '🔄 Ulang',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () async {
                                final ap = context.read<ActivityProvider>();

                                // Deteksi tipe makanan berdasarkan waktu
                                final hour = DateTime.now().hour;
                                String mealType = 'camilan';
                                if (hour >= 4 && hour < 10) {
                                  mealType = 'sarapan';
                                } else if (hour >= 10 && hour < 15) {
                                  mealType = 'makan_siang';
                                } else if (hour >= 17 && hour < 21) {
                                  mealType = 'makan_malam';
                                }

                                // Save foto ke direktori lokal
                                String? savedPhotoPath;
                                if (_imageFile != null) {
                                  savedPhotoPath = await _saveFoodPhoto(
                                    _imageFile!.path,
                                    _result!.name
                                  );
                                }

                                final ok = ap.addFoodLog(
                                  _result!.name,
                                  _result!.calories,
                                  emoji: _result!.emoji,
                                  protein: _result!.protein,
                                  carbs: _result!.carbs,
                                  fat: _result!.fat,
                                  fiber: _result!.fiber,
                                  sugarGrams: _result!.sugarGrams,
                                  caffeineMg: _result!.caffeineMg,
                                  photoPath: savedPhotoPath,
                                  serving: _result!.serving,
                                  ingredients: _result!.ingredients,
                                  category: _result!.category,
                                  mealType: mealType,
                                );
                                if (!context.mounted) return;
                                if (!ok) {
                                  final msg = (ap.fastingMode == 'ramadan' &&
                                          ap.isFastingNow)
                                      ? 'Sedang puasa: catat makanan saat berbuka/sahur.'
                                      : 'Gagal mencatat makanan.';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Berhasil mencatat ${_result!.calories} kkal! 📸'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppColors.gradientPrimary,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    '✅ Catat Makanan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  }
}


class _DetailChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 19)),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
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
