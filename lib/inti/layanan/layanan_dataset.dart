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
              'servingMl': servingMl,
            };
            _verifiedCategories.add(name);
          }
        }
        debugPrint('[DatasetService] Loaded beverages_id.csv entries.');
      } catch (e) {
        debugPrint('[DatasetService] Error loading beverages_id.csv: $e');
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

  /// Searches for exact or partial match in the nutrition dataset.

  Future<List<String>> search(String query, {int maxResults = 30}) async {
    await loadNutritionDataset();
    final q = query.toLowerCase();
    final results = _nutritionData.keys.where((k) => k.toLowerCase().contains(q)).take(maxResults).toList();
    return results;
  }

  Future<Map<String, dynamic>?> findNutrition(String query) async {
    if (!_isDataLoaded) await loadNutritionDataset();

    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return null;

    // 1. Exact match
    if (_nutritionData.containsKey(normalizedQuery)) {
      return _nutritionData[normalizedQuery];
    }

    // 2. Substring match
    for (final entry in _nutritionData.entries) {
      if (entry.key.contains(normalizedQuery) ||
          normalizedQuery.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
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
