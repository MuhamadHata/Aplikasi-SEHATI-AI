// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle local dataset retrieval for RAG (Retrieval-Augmented Generation)
class DatasetService {
  DatasetService._();
  static final DatasetService instance = DatasetService._();

  // Cache for nutrition data to avoid re-parsing
  final Map<String, dynamic> _nutritionData = {};
  final List<String> _verifiedCategories = [];
  bool _isDataLoaded = false;

  /// Loads the nutrition dataset from assets into memory for fast searching.
  Future<void> loadNutritionDataset() async {
    if (_isDataLoaded) return;

    try {
      // 1. Load Master Food Data (Highest Priority - from YOLO labels)
      try {
        final masterJson = await rootBundle
            .loadString('ai_workspace/dataset/food_master.json');
        final Map<String, dynamic> masterMap = jsonDecode(masterJson);
        masterMap.forEach((key, value) {
          _nutritionData[key.toLowerCase()] = value;
          if (value['name'] != null) {
            _verifiedCategories.add(value['name'] as String);
          }
        });
        debugPrint(
            '[DatasetService] Loaded ${_verifiedCategories.length} master food entries.');
      } catch (e) {
        debugPrint('[DatasetService] Error loading food_master.json: $e');
      }

      // 2. Load nutrition.csv (Secondary)
      try {
        final csvString =
            await rootBundle.loadString('ai_workspace/dataset/nutrition.csv');
        final lines = const LineSplitter().convert(csvString);

        int startIndex = 0;
        if (lines.isNotEmpty &&
            (lines[0].toLowerCase().contains('id') ||
                lines[0].toLowerCase().contains('name'))) {
          startIndex = 1;
        }

        for (int i = startIndex; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final parts = _splitCsvLine(line);
          if (parts.length >= 6) {
            final foodName = parts[5].trim().toLowerCase();
            // Don't overwrite higher priority master data
            if (!_nutritionData.containsKey(foodName)) {
              _nutritionData[foodName] = {
                'name': parts[5].trim(),
                'calories': int.tryParse(parts[1]) ?? 0,
                'protein': double.tryParse(parts[2]) ?? 0.0,
                'fat': double.tryParse(parts[3]) ?? 0.0,
                'carbs': double.tryParse(parts[4]) ?? 0.0,
                'fiber': 0.0,
                'sugar': 0.0,
                'category': 'Umum'
              };
            }
          }
        }
      } catch (e) {
        debugPrint('[DatasetService] Error loading nutrition.csv: $e');
      }

      // 3. Load beverages_id.csv (Minuman)
      try {
        final csvString = await rootBundle
            .loadString('ai_workspace/dataset/beverages_id.csv');
        final lines = const LineSplitter().convert(csvString);

        int startIndex = 0;
        if (lines.isNotEmpty &&
            lines[0].toLowerCase().contains('name') &&
            lines[0].toLowerCase().contains('energy')) {
          startIndex = 1;
        }

        for (int i = startIndex; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final parts = _splitCsvLine(line);
          if (parts.length >= 6) {
            final name = parts[0].trim();
            final key = name.toLowerCase();
            if (_nutritionData.containsKey(key)) continue;

            final servingMl = int.tryParse(parts[1].trim()) ?? 0;
            final energyKcal = int.tryParse(parts[2].trim()) ?? 0;
            final sugarG = double.tryParse(parts[3].trim()) ?? 0.0;
            final caffeineMg = int.tryParse(parts[4].trim()) ?? 0;
            final category =
                parts[5].trim().isEmpty ? 'Minuman' : parts[5].trim();

            _nutritionData[key] = {
              'name': name,
              'calories': energyKcal,
              'protein': 0.0,
              'fat': 0.0,
              'carbs': sugarG,
              'fiber': 0.0,
              'sugar': sugarG,
              'caffeineMg': caffeineMg,
              'category': category,
              'serving': servingMl > 0 ? '$servingMl ml' : '1 gelas (250ml)',
            };
            _verifiedCategories.add(name);
          }
        }
        debugPrint('[DatasetService] Loaded beverages_id.csv entries.');
      } catch (e) {
        debugPrint('[DatasetService] Error loading beverages_id.csv: $e');
      }

      // 3B. Load nilai-gizi.csv (Kemenkes / Panganku Indonesian Food Composition)
      try {
        final csvString =
            await rootBundle.loadString('ai_workspace/dataset/nilai-gizi.csv');
        final lines = const LineSplitter().convert(csvString);

        int startIndex = 1; // skip header
        for (int i = startIndex; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final parts = _splitCsvLine(line);
          if (parts.length >= 7) {
            final name = parts[0].trim();
            final key = name.toLowerCase();
            if (_nutritionData.containsKey(key)) continue;

            final energyKcal = double.tryParse(parts[3].trim())?.round() ?? 0;
            final protein = double.tryParse(parts[4].trim()) ?? 0.0;
            final carbs = double.tryParse(parts[5].trim()) ?? 0.0;
            final fat = double.tryParse(parts[6].trim()) ?? 0.0;
            final sugar = parts.length > 7
                ? (double.tryParse(parts[7].trim()) ?? 0.0)
                : 0.0;
            final fiber = parts.length > 9
                ? (double.tryParse(parts[9].trim()) ?? 0.0)
                : 0.0;
            final serving = parts[2].trim();

            _nutritionData[key] = {
              'name': name,
              'calories': energyKcal,
              'protein': protein,
              'fat': fat,
              'carbs': carbs,
              'fiber': fiber,
              'sugar': sugar,
              'category': 'Pangan Lokal',
              'serving': serving.isNotEmpty ? serving : '100g',
            };
            _verifiedCategories.add(name);
          }
        }
        debugPrint('[DatasetService] Loaded nilai-gizi.csv entries.');
      } catch (e) {
        debugPrint('[DatasetService] Error loading nilai-gizi.csv: $e');
      }

      // 4. Load from Supabase User Contributions (Community Dataset)
      try {
        final List<dynamic> sbData =
            await Supabase.instance.client.from('food_dataset').select();
        for (var item in sbData) {
          final foodName = item['food_name'].toString().toLowerCase().trim();
          _nutritionData[foodName] = {
            'name': item['food_name'],
            'calories': item['calories'],
            'protein': item['protein'],
            'carbs': item['carbs'],
            'fat': item['fat'],
            'fiber': item['fiber'] ?? 0.0,
            'sugar': item['sugar'] ?? 0.0,
            'category': item['category'] ?? 'Umum',
            'serving': item['serving'] ?? '',
          };
          _verifiedCategories.add(item['food_name'].toString());
        }
        debugPrint(
            '[DatasetService] Loaded ${sbData.length} food_dataset entries from Supabase.');
      } catch (e) {
        debugPrint(
            '[DatasetService] Warning: Could not load food_dataset from Supabase: $e');
      }

      // Load user-corrected data untuk continual learning (HIGHEST PRIORITY)
      await loadUserCorrectedData();

      // Load local scan history (SECOND PRIORITY)
      await loadLocalScanHistory();

      _isDataLoaded = true;
      debugPrint(
          '[DatasetService] Total database size: ${_nutritionData.length} entries.');
    } catch (e) {
      debugPrint('[DatasetService] Critical error loading datasets: $e');
    }
  }

  List<String> _splitCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      var char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  /// Returns list of verified categories for AI prompting
  Future<List<String>> getVerifiedCategories() async {
    if (!_isDataLoaded) await loadNutritionDataset();
    return _verifiedCategories;
  }

  /// Returns visual clues for specific categories to reduce hallucinations
  Future<String> getVisualClues() async {
    if (!_isDataLoaded) await loadNutritionDataset();
    StringBuffer clues = StringBuffer();
    _nutritionData.forEach((key, value) {
      if (value['visual_clues'] != null) {
        clues.writeln(
            '- ${value['name']}: ${(value['visual_clues'] as List).join(", ")}');
      }
    });
    return clues.toString();
  }

  /// Searches for exact, prefix, substring, or alias match in the nutrition dataset.
  Future<List<String>> search(String query, {int maxResults = 30}) async {
    await loadNutritionDataset();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final exactMatches = <String>[];
    final prefixMatches = <String>[];
    final subMatches = <String>[];
    final aliasMatches = <String>[];
    final seen = <String>{};

    for (final entry in _nutritionData.entries) {
      final key = entry.key;
      final val = entry.value;
      final name = (val['name'] as String? ?? key);
      final nameLower = name.toLowerCase();

      // Collect aliases if any
      final aliases = <String>[];
      if (val['aliases'] != null && val['aliases'] is List) {
        for (final a in val['aliases'] as List) {
          aliases.add(a.toString().toLowerCase());
        }
      }

      if (key == q || nameLower == q) {
        if (seen.add(name)) exactMatches.add(name);
      } else if (key.startsWith(q) || nameLower.startsWith(q)) {
        if (seen.add(name)) prefixMatches.add(name);
      } else if (key.contains(q) || nameLower.contains(q)) {
        if (seen.add(name)) subMatches.add(name);
      } else if (aliases.any((a) => a == q || a.startsWith(q) || a.contains(q))) {
        if (seen.add(name)) aliasMatches.add(name);
      }
    }

    final combined = [
      ...exactMatches,
      ...prefixMatches,
      ...subMatches,
      ...aliasMatches,
    ];

    return combined.take(maxResults).toList();
  }

  /// Finds nutrition data with support for alias matching and substring searching
  Future<Map<String, dynamic>?> findNutrition(String query) async {
    if (!_isDataLoaded) await loadNutritionDataset();

    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return null;

    // 1. Exact key match
    if (_nutritionData.containsKey(normalizedQuery)) {
      return _nutritionData[normalizedQuery];
    }

    // 2. Check aliases across all entries
    for (final entry in _nutritionData.entries) {
      final val = entry.value;
      if (val['aliases'] != null && val['aliases'] is List) {
        for (final a in val['aliases'] as List) {
          final alias = a.toString().toLowerCase().trim();
          if (alias == normalizedQuery) {
            return val;
          }
        }
      }
    }

    // 3. Exact name match
    for (final entry in _nutritionData.entries) {
      final name = (entry.value['name'] as String?)?.toLowerCase().trim();
      if (name != null && name == normalizedQuery) {
        return entry.value;
      }
    }

    // 4. Substring match in key, aliases, or name
    for (final entry in _nutritionData.entries) {
      final key = entry.key;
      final val = entry.value;
      final name = (val['name'] as String?)?.toLowerCase().trim() ?? '';

      if (key.contains(normalizedQuery) || normalizedQuery.contains(key)) {
        return val;
      }
      if (name.isNotEmpty &&
          (name.contains(normalizedQuery) || normalizedQuery.contains(name))) {
        return val;
      }

      if (val['aliases'] != null && val['aliases'] is List) {
        for (final a in val['aliases'] as List) {
          final alias = a.toString().toLowerCase().trim();
          if (alias.contains(normalizedQuery) || normalizedQuery.contains(alias)) {
            return val;
          }
        }
      }
    }

    // 5. Word-level match
    final queryWords = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
    if (queryWords.isNotEmpty) {
      for (final entry in _nutritionData.entries) {
        final key = entry.key;
        final allMatched = queryWords.every((w) => key.contains(w));
        if (allMatched) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Parses a food string containing potential extra lauk / add-on modifiers.
  /// Examples:
  /// - "Mie Gacoan" -> Mie Gacoan base (621 kkal, 2 pangsit in ingredients)
  /// - "Mie Gacoan + Telur Ceplok" -> 621 + 92 = 713 kkal, includes 2 pangsit + Telur Ceplok
  /// - "Mie Gacoan + 2 Telur Ceplok + Kerupuk Putih" -> 621 + 184 + 65 = 870 kkal
  /// - "Nasi Goreng dan Telur Dadar" -> 540 + 110 = 650 kkal
  Future<ParsedFoodNutrition> parseFoodWithAddons(String query) async {
    if (!_isDataLoaded) await loadNutritionDataset();

    final text = query.trim();
    if (text.isEmpty) {
      return const ParsedFoodNutrition(
        rawQuery: '',
        formattedName: 'Makanan Terdeteksi',
        emoji: '🍽️',
        totalCalories: 250,
        totalProtein: 10.0,
        totalCarbs: 30.0,
        totalFat: 8.0,
        totalFiber: 1.0,
        totalSugar: 2.0,
        totalCaffeine: 0,
        category: 'Umum',
        serving: '1 porsi',
        combinedIngredients: [],
        isMatchedInDb: false,
      );
    }

    // Split by delimiters: +, plus, dan, dengan, with, &, comma
    final rawParts = text.split(
        RegExp(r'\s*(?:\+|\bplus\b|\bdan\b|\bdengan\b|\bwith\b|&|,)\s*',
            caseSensitive: false));
    final parts = rawParts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) {
      return ParsedFoodNutrition(
        rawQuery: text,
        formattedName: text,
        emoji: '🍽️',
        totalCalories: 250,
        totalProtein: 10.0,
        totalCarbs: 30.0,
        totalFat: 8.0,
        totalFiber: 1.0,
        totalSugar: 2.0,
        totalCaffeine: 0,
        category: 'Umum',
        serving: '1 porsi',
        combinedIngredients: [text],
        isMatchedInDb: false,
      );
    }

    // 1. Identify base food
    final baseQuery = parts[0];
    final baseData = await findNutrition(baseQuery);
    final isMatched = baseData != null;

    final String baseName = baseData?['name'] as String? ?? baseQuery;
    final int baseCalories = (baseData?['calories'] as num?)?.toInt() ?? 250;
    final double baseProtein = (baseData?['protein'] as num?)?.toDouble() ?? 10.0;
    final double baseCarbs = (baseData?['carbs'] as num?)?.toDouble() ?? 30.0;
    final double baseFat = (baseData?['fat'] as num?)?.toDouble() ?? 8.0;
    final double baseFiber = (baseData?['fiber'] as num?)?.toDouble() ?? 1.0;
    final double baseSugar = (baseData?['sugar'] as num?)?.toDouble() ?? 2.0;
    final int baseCaffeine = (baseData?['caffeineMg'] as num?)?.toInt() ?? 0;
    final String baseEmoji = baseData?['emoji'] as String? ?? '🍽️';
    final String baseCategory = baseData?['category'] as String? ?? 'Makanan Utama';
    final String baseServing = baseData?['serving'] as String? ?? '1 porsi';

    List<String> baseIngredients = [];
    if (baseData != null && baseData['ingredients'] != null) {
      if (baseData['ingredients'] is List) {
        baseIngredients = List<String>.from(baseData['ingredients']);
      } else if (baseData['ingredients'] is String) {
        baseIngredients = (baseData['ingredients'] as String)
            .split('|')
            .map((s) => s.trim())
            .toList();
      }
    }
    if (baseIngredients.isEmpty) {
      baseIngredients = [baseName];
    }

    int totalCalories = baseCalories;
    double totalProtein = baseProtein;
    double totalCarbs = baseCarbs;
    double totalFat = baseFat;
    double totalFiber = baseFiber;
    double totalSugar = baseSugar;
    int totalCaffeine = baseCaffeine;

    final List<ParsedAddonItem> addons = [];
    final List<String> combinedIngredients = List<String>.from(baseIngredients);

    // 2. Parse any extra lauk / addons
    for (int i = 1; i < parts.length; i++) {
      final part = parts[i];
      int qty = 1;
      String addonQuery = part;

      // Match pattern like "2 Telur Ceplok" or "2x Kerupuk"
      final prefixMatch = RegExp(
              r'^(\d+)\s*(?:x|buah|butir|potong|lembar|porsi|tusuk|keping)?\s+(.*)$',
              caseSensitive: false)
          .firstMatch(part);
      if (prefixMatch != null) {
        qty = int.tryParse(prefixMatch.group(1) ?? '1') ?? 1;
        addonQuery = prefixMatch.group(2)?.trim() ?? part;
      } else {
        final suffixMatch = RegExp(
                r'^(.*?)\s+(\d+)\s*(?:x|buah|butir|potong|lembar|porsi|tusuk|keping)?$',
                caseSensitive: false)
            .firstMatch(part);
        if (suffixMatch != null) {
          addonQuery = suffixMatch.group(1)?.trim() ?? part;
          qty = int.tryParse(suffixMatch.group(2) ?? '1') ?? 1;
        }
      }

      if (qty <= 0) qty = 1;

      final addonData = await findNutrition(addonQuery);
      String aName = addonData?['name'] as String? ?? addonQuery;
      int aCal = 0;
      double aProt = 0.0;
      double aCarb = 0.0;
      double aFat = 0.0;
      double aSugar = 0.0;

      if (addonData != null) {
        aCal = ((addonData['calories'] as num?)?.toInt() ?? 80) * qty;
        aProt = ((addonData['protein'] as num?)?.toDouble() ?? 5.0) * qty;
        aCarb = ((addonData['carbs'] as num?)?.toDouble() ?? 5.0) * qty;
        aFat = ((addonData['fat'] as num?)?.toDouble() ?? 5.0) * qty;
        aSugar = ((addonData['sugar'] as num?)?.toDouble() ?? 0.5) * qty;
      } else {
        // Fallback realistic estimation for common side dish words
        final lowerA = addonQuery.toLowerCase();
        if (lowerA.contains('telur')) {
          aCal = 92 * qty;
          aProt = 6.3 * qty;
          aCarb = 0.6 * qty;
          aFat = 7.0 * qty;
        } else if (lowerA.contains('tempe')) {
          aCal = 110 * qty;
          aProt = 6.0 * qty;
          aCarb = 5.0 * qty;
          aFat = 7.5 * qty;
        } else if (lowerA.contains('tahu')) {
          aCal = 75 * qty;
          aProt = 5.0 * qty;
          aCarb = 2.5 * qty;
          aFat = 5.0 * qty;
        } else if (lowerA.contains('kerupuk')) {
          aCal = 65 * qty;
          aProt = 0.5 * qty;
          aCarb = 10.5 * qty;
          aFat = 2.5 * qty;
        } else if (lowerA.contains('sambal')) {
          aCal = 35 * qty;
          aProt = 0.5 * qty;
          aCarb = 2.5 * qty;
          aFat = 2.5 * qty;
        } else if (lowerA.contains('nasi')) {
          aCal = 130 * qty;
          aProt = 2.4 * qty;
          aCarb = 28.5 * qty;
          aFat = 0.2 * qty;
        } else if (lowerA.contains('pangsit')) {
          aCal = 117 * qty;
          aProt = 4.5 * qty;
          aCarb = 10.0 * qty;
          aFat = 6.5 * qty;
        } else {
          aCal = 80 * qty;
          aProt = 4.0 * qty;
          aCarb = 8.0 * qty;
          aFat = 4.0 * qty;
        }
      }

      totalCalories += aCal;
      totalProtein += aProt;
      totalCarbs += aCarb;
      totalFat += aFat;
      totalSugar += aSugar;

      final addonItem = ParsedAddonItem(
        name: aName,
        quantity: qty,
        calories: aCal,
        protein: aProt,
        carbs: aCarb,
        fat: aFat,
        sugar: aSugar,
      );
      addons.add(addonItem);

      final addonLabel = qty > 1 ? '$qty $aName' : aName;
      combinedIngredients.add('$addonLabel (+$aCal kkal)');
    }

    String formattedName = baseName;
    if (addons.isNotEmpty) {
      final addonNames = addons
          .map((a) => a.quantity > 1 ? '${a.quantity}x ${a.name}' : a.name)
          .join(' + ');
      formattedName = '$baseName + $addonNames';
    }

    return ParsedFoodNutrition(
      rawQuery: text,
      formattedName: formattedName,
      emoji: baseEmoji,
      totalCalories: totalCalories,
      totalProtein: double.parse(totalProtein.toStringAsFixed(1)),
      totalCarbs: double.parse(totalCarbs.toStringAsFixed(1)),
      totalFat: double.parse(totalFat.toStringAsFixed(1)),
      totalFiber: double.parse(totalFiber.toStringAsFixed(1)),
      totalSugar: double.parse(totalSugar.toStringAsFixed(1)),
      totalCaffeine: totalCaffeine,
      category: baseCategory,
      serving: baseServing,
      combinedIngredients: combinedIngredients,
      baseFoodData: baseData,
      addons: addons,
      isMatchedInDb: isMatched,
    );
  }

  /// Saves a user's manual correction to the Community Dataset in Supabase
  Future<void> saveCorrection(Map<String, dynamic> data) async {
    final key = data['name'].toString().toLowerCase().trim();
    // Save to local fast-cache immediately
    _nutritionData[key] = data;
    if (!_verifiedCategories.contains(data['name'])) {
      _verifiedCategories.add(data['name']);
    }

    // Persist to Supabase
    try {
      await Supabase.instance.client.from('food_dataset').upsert({
        'food_name': data['name'],
        'calories': data['calories'],
        'protein': data['protein'],
        'carbs': data['carbs'],
        'fat': data['fat'],
        'fiber': data['fiber'] ?? 0.0,
        'sugar': data['sugar'] ?? 0.0,
        'category': data['category'] ?? 'Umum',
        'serving': data['serving'] ?? '',
      }, onConflict: 'food_name');
    } catch (e) {
      debugPrint('[DatasetService] Error saving to food_dataset: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTINUAL LEARNING - User-corrected data gets priority
  // ═══════════════════════════════════════════════════════════════════════════

  /// Local cache untuk data yang sudah dikoreksi user
  /// Priority: User Corrections > Local Scans > Master Dataset > CSV
  final Map<String, Map<String, dynamic>> _userCorrectedData = {};
  final List<String> _localScanHistory = [];

  /// Load user-corrected data dari Supabase untuk continual learning
  Future<void> loadUserCorrectedData() async {
    try {
      final data = await Supabase.instance.client
          .from('local_scans')
          .select()
          .eq('is_user_corrected', true)
          .order('corrected_at', ascending: false)
          .limit(500);

      for (final item in data) {
        final foodName = item['food_name'].toString().toLowerCase().trim();
        final correction = item['user_correction'];
        if (correction != null && correction is Map) {
          _userCorrectedData[foodName] = {
            'name': correction['name'] ?? item['food_name'],
            'calories': correction['calories'] ?? item['calories'],
            'protein': correction['protein'] ?? item['protein'],
            'carbs': correction['carbs'] ?? item['carbs'],
            'fat': correction['fat'] ?? item['fat'],
            'fiber': correction['fiber'] ?? item['fiber'] ?? 0.0,
            'sugar': correction['sugarGrams'] ?? item['sugar_grms'] ?? 0.0,
            'category': correction['category'] ?? item['category'] ?? 'Umum',
            'serving': correction['serving'] ?? item['serving'] ?? '',
            'ingredients': correction['ingredients'] ?? item['ingredients'],
            'source': 'user_corrected',
            'confidence': 0.95, // High confidence for user-corrected
            'scan_count': 1,
          };
        }
      }

      debugPrint('[DatasetService] Loaded ${_userCorrectedData.length} user-corrected entries');
    } catch (e) {
      debugPrint('[DatasetService] Error loading user corrections: $e');
    }
  }

  /// Load local scan history (auto-cached from food logs)
  Future<void> loadLocalScanHistory() async {
    try {
      final data = await Supabase.instance.client
          .from('local_scans')
          .select()
          .eq('is_user_corrected', false)
          .order('scanned_at', ascending: false)
          .limit(1000);

      for (final item in data) {
        final foodName = item['food_name'].toString().toLowerCase().trim();
        // Don't overwrite user corrections
        if (!_userCorrectedData.containsKey(foodName)) {
          _localScanHistory.add(foodName);
          _nutritionData[foodName] = {
            'name': item['food_name'],
            'calories': item['calories'] ?? 0,
            'protein': item['protein'] ?? 0.0,
            'carbs': item['carbs'] ?? 0.0,
            'fat': item['fat'] ?? 0.0,
            'fiber': item['fiber'] ?? 0.0,
            'sugar': item['sugar_grms'] ?? 0.0,
            'category': item['category'] ?? 'Umum',
            'serving': item['serving'] ?? '',
            'ingredients': item['ingredients']?.toString().split('|') ?? [],
            'source': 'local_scan',
            'confidence': 0.80, // Medium confidence for auto-scanned
          };
        }
      }

      debugPrint('[DatasetService] Loaded ${_localScanHistory.length} local scan entries');
    } catch (e) {
      debugPrint('[DatasetService] Error loading local scans: $e');
    }
  }

  /// Enhanced search dengan prioritas continual learning:
  /// 1. User-corrected data (highest priority)
  /// 2. Local scan history
  /// 3. Master dataset
  /// 4. CSV fallback
  Future<Map<String, dynamic>?> findNutritionWithContinualLearning(String query) async {
    if (!_isDataLoaded) await loadNutritionDataset();

    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return null;

    // 1. Check user-corrected data first (highest priority)
    for (final key in _userCorrectedData.keys) {
      if (normalizedQuery.contains(key) || key.contains(normalizedQuery)) {
        debugPrint('[DatasetService] ✅ Found user-corrected data for: $key');
        return _userCorrectedData[key];
      }
    }

    // 2. Check exact match in user corrections
    if (_userCorrectedData.containsKey(normalizedQuery)) {
      return _userCorrectedData[normalizedQuery];
    }

    // 3. Check local scan history
    for (final key in _localScanHistory) {
      if (normalizedQuery.contains(key) || key.contains(normalizedQuery)) {
        if (_nutritionData.containsKey(key)) {
          debugPrint('[DatasetService] 📱 Found local scan data for: $key');
          return _nutritionData[key];
        }
      }
    }

    // 4. Exact match in main dataset
    if (_nutritionData.containsKey(normalizedQuery)) {
      return _nutritionData[normalizedQuery];
    }

    // 5. Substring match
    for (final entry in _nutritionData.entries) {
      if (entry.key.contains(normalizedQuery) ||
          normalizedQuery.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get data source info untuk debugging
  String getDataSourceInfo(String query) {
    final normalizedQuery = query.toLowerCase().trim();

    if (_userCorrectedData.containsKey(normalizedQuery)) {
      return 'user_corrected';
    }

    for (final key in _userCorrectedData.keys) {
      if (normalizedQuery.contains(key) || key.contains(normalizedQuery)) {
        return 'user_corrected';
      }
    }

    if (_localScanHistory.contains(normalizedQuery)) {
      return 'local_scan';
    }

    if (_nutritionData.containsKey(normalizedQuery)) {
      final data = _nutritionData[normalizedQuery];
      return data?['source'] ?? 'master_dataset';
    }

    return 'not_found';
  }

  /// Get confidence score untuk hasil pencarian
  double getConfidenceScore(String query) {
    final normalizedQuery = query.toLowerCase().trim();

    if (_userCorrectedData.containsKey(normalizedQuery)) {
      return 0.95; // High confidence
    }

    for (final key in _userCorrectedData.keys) {
      if (normalizedQuery.contains(key) || key.contains(normalizedQuery)) {
        return 0.95;
      }
    }

    if (_localScanHistory.contains(normalizedQuery)) {
      return 0.80; // Medium confidence
    }

    if (_nutritionData.containsKey(normalizedQuery)) {
      return 0.70; // Standard confidence
    }

    return 0.50; // Low confidence - AI will need to estimate
  }

  /// Get statistics untuk continual learning dashboard
  Map<String, int> getContinualLearningStats() {
    return {
      'userCorrected': _userCorrectedData.length,
      'localScans': _localScanHistory.length,
      'totalEntries': _nutritionData.length,
    };
  }
}

/// Model hasil parsing makanan beserta potensi lauk tambahan / add-on
class ParsedFoodNutrition {
  final String rawQuery;
  final String formattedName;
  final String emoji;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double totalSugar;
  final int totalCaffeine;
  final String category;
  final String serving;
  final List<String> combinedIngredients;
  final Map<String, dynamic>? baseFoodData;
  final List<ParsedAddonItem> addons;
  final bool isMatchedInDb;

  const ParsedFoodNutrition({
    required this.rawQuery,
    required this.formattedName,
    required this.emoji,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSugar,
    required this.totalCaffeine,
    required this.category,
    required this.serving,
    required this.combinedIngredients,
    this.baseFoodData,
    this.addons = const [],
    this.isMatchedInDb = false,
  });
}

/// Model untuk rincian 1 jenis lauk tambahan / pelengkap
class ParsedAddonItem {
  final String name;
  final int quantity;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;

  const ParsedAddonItem({
    required this.name,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar = 0.0,
  });
}
