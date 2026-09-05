// ==========================================
// LAYANAN FOOD LOG
// Menyimpan log makanan dengan foto ke database lokal
// Mendukung continual learning untuk improve AI
// ==========================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/model.dart';

class FoodLogService {
  FoodLogService._();
  static final FoodLogService instance = FoodLogService._();

  SupabaseClient get _sb => Supabase.instance.client;

  // ─── Direktori untuk menyimpan foto makanan ─────────────────────────────────
  Future<String> get _foodPhotosDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/food_photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir.path;
  }

  // ─── Simpan foto makanan ke direktori lokal ─────────────────────────────────
  Future<String?> saveFoodPhoto(String sourcePath, String foodName) async {
    try {
      final photosDir = await _foodPhotosDir;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = foodName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_')
          .substring(0, foodName.length.clamp(0, 20));
      final extension = sourcePath.split('.').last;
      final newFileName = '${sanitizedName}_$timestamp.$extension';
      final newPath = '$photosDir/$newFileName';

      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(newPath);
        return newPath;
      }
      return null;
    } catch (e) {
      debugPrint('[FoodLogService] Error saving photo: $e');
      return null;
    }
  }

  // ─── Hapus foto makanan ─────────────────────────────────────────────────────
  Future<void> deleteFoodPhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[FoodLogService] Error deleting photo: $e');
    }
  }

  // ─── Tambah entri log makanan ───────────────────────────────────────────────
  Future<int?> addFoodLog({
    required FoodItem foodItem,
    String? photoPath,
    required String mealType, // sarapan, makan_siang, makan_malam, camilan
    DateTime? loggedAt,
  }) async {
    try {
      final userId = _sb.auth.currentUser?.id;

      // Simpan foto jika ada
      String? savedPhotoPath;
      if (photoPath != null) {
        savedPhotoPath = await saveFoodPhoto(photoPath, foodItem.name);
      }

      final now = loggedAt ?? DateTime.now();

      // Simpan ke Supabase
      final data = await _sb.from('food_logs').insert({
        'user_id': userId,
        'food_name': foodItem.name,
        'photo_path': savedPhotoPath,
        'calories': foodItem.calories,
        'protein': foodItem.protein,
        'carbs': foodItem.carbs,
        'fat': foodItem.fat,
        'fiber': foodItem.fiber,
        'sugar_grms': foodItem.sugarGrams,
        'serving': foodItem.serving,
        'ingredients': foodItem.ingredients.join('|'),
        'category': foodItem.category,
        'emoji': foodItem.emoji,
        'meal_type': mealType,
        'logged_at': now.toIso8601String(),
      }).select('id');

      final id = data.first['id'] as int?;

      // JIKA photo_path ADA, simpan juga ke local cache untuk continual learning
      if (savedPhotoPath != null && id != null) {
        await _cacheFoodScan(
          foodItem: foodItem,
          photoPath: savedPhotoPath,
          logId: id,
        );
      }

      debugPrint('[FoodLogService] ✅ Food log added: ${foodItem.name}');
      return id;
    } catch (e) {
      debugPrint('[FoodLogService] ❌ Error adding food log: $e');
      return null;
    }
  }

  // ─── Ambil semua log makanan user ───────────────────────────────────────────
  Future<List<FoodLogEntry>> getFoodLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? mealType,
    int limit = 50,
  }) async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) return [];

      // Build query with filters
      var query = _sb.from('food_logs').select();

      // Get all logs for this user first, then filter in Dart
      final allData = await query.eq('user_id', userId).order('logged_at', ascending: false).limit(limit);

      List<Map<String, dynamic>> filteredData = List<Map<String, dynamic>>.from(allData);

      // Filter by date range
      if (startDate != null) {
        final startStr = startDate.toIso8601String();
        filteredData = filteredData.where((item) {
          final loggedAt = item['logged_at'] as String?;
          return loggedAt != null && loggedAt.compareTo(startStr) >= 0;
        }).toList();
      }
      if (endDate != null) {
        final endStr = endDate.toIso8601String();
        filteredData = filteredData.where((item) {
          final loggedAt = item['logged_at'] as String?;
          return loggedAt != null && loggedAt.compareTo(endStr) <= 0;
        }).toList();
      }
      if (mealType != null && mealType.isNotEmpty) {
        filteredData = filteredData.where((item) => item['meal_type'] == mealType).toList();
      }

      return filteredData.map((item) {
        final loggedAt = DateTime.tryParse(item['logged_at'] ?? '');
        final time = loggedAt != null
            ? '${loggedAt.hour.toString().padLeft(2, '0')}:${loggedAt.minute.toString().padLeft(2, '0')}'
            : '';

        return FoodLogEntry(
          time: time,
          name: item['food_name'] ?? '',
          emoji: item['emoji'] ?? '🍽️',
          cal: item['calories'] ?? 0,
          meal: item['meal_type'] ?? '',
          photoPath: item['photo_path'],
          protein: (item['protein'] as num?)?.toDouble(),
          carbs: (item['carbs'] as num?)?.toDouble(),
          fat: (item['fat'] as num?)?.toDouble(),
          fiber: (item['fiber'] as num?)?.toDouble(),
          sugarGrams: (item['sugar_grms'] as num?)?.toDouble(),
          serving: item['serving'],
          ingredients: (item['ingredients'] as String?)?.split('|'),
          category: item['category'],
          loggedAt: loggedAt,
        );
      }).toList();
    } catch (e) {
      debugPrint('[FoodLogService] Error getting food logs: $e');
      return [];
    }
  }

  // ─── Hapus log makanan ───────────────────────────────────────────────────────
  Future<bool> deleteFoodLog(int id, {String? photoPath}) async {
    try {
      // Hapus foto jika ada
      if (photoPath != null) {
        await deleteFoodPhoto(photoPath);
      }

      await _sb.from('food_logs').delete().eq('id', id);
      debugPrint('[FoodLogService] ✅ Food log deleted: $id');
      return true;
    } catch (e) {
      debugPrint('[FoodLogService] ❌ Error deleting food log: $e');
      return false;
    }
  }

  // ─── Update log makanan ──────────────────────────────────────────────────────
  Future<bool> updateFoodLog(int id, Map<String, dynamic> updates) async {
    try {
      await _sb.from('food_logs').update(updates).eq('id', id);
      debugPrint('[FoodLogService] ✅ Food log updated: $id');
      return true;
    } catch (e) {
      debugPrint('[FoodLogService] ❌ Error updating food log: $e');
      return false;
    }
  }

  // ─── Get logs by date (untuk ringkasan harian) ─────────────────────────────
  Future<Map<String, List<FoodLogEntry>>> getLogsGroupedByMeal(
      DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final logs = await getFoodLogs(startDate: startOfDay, endDate: endOfDay);

    final grouped = <String, List<FoodLogEntry>>{
      'sarapan': [],
      'makan_siang': [],
      'makan_malam': [],
      'camilan': [],
    };

    for (final log in logs) {
      final meal = log.meal.toLowerCase();
      if (grouped.containsKey(meal)) {
        grouped[meal]!.add(log);
      } else {
        grouped['camilan']!.add(log);
      }
    }

    return grouped;
  }

  // ─── Get total kalori harian ─────────────────────────────────────────────────
  Future<int> getTodayCalories() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final logs = await getFoodLogs(startDate: startOfDay, endDate: endOfDay);
    int total = 0;
    for (final log in logs) {
      total += log.cal;
    }
    return total;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTINUAL LEARNING - Cache food scans for AI training
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Cache hasil scan makanan ──────────────────────────────────────────────
  Future<void> _cacheFoodScan({
    required FoodItem foodItem,
    required String photoPath,
    required int logId,
  }) async {
    try {
      // Simpan ke tabel local_scans untuk continual learning
      await _sb.from('local_scans').insert({
        'user_id': _sb.auth.currentUser?.id,
        'log_id': logId,
        'food_name': foodItem.name,
        'image_path': photoPath,
        'calories': foodItem.calories,
        'protein': foodItem.protein,
        'carbs': foodItem.carbs,
        'fat': foodItem.fat,
        'fiber': foodItem.fiber,
        'sugar_grms': foodItem.sugarGrams,
        'serving': foodItem.serving,
        'ingredients': foodItem.ingredients.join('|'),
        'category': foodItem.category,
        'is_user_corrected': false,
        'scanned_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[FoodLogService] ✅ Scan cached for continual learning');
    } catch (e) {
      debugPrint('[FoodLogService] ⚠️ Failed to cache scan: $e');
    }
  }

  // ─── Update cached scan dengan koreksi user ─────────────────────────────────
  Future<void> updateCachedScanWithCorrection(
    int logId,
    Map<String, dynamic> userCorrection,
  ) async {
    try {
      await _sb.from('local_scans').update({
        'is_user_corrected': true,
        'user_correction': userCorrection,
        'corrected_at': DateTime.now().toIso8601String(),
      }).eq('log_id', logId);

      debugPrint('[FoodLogService] ✅ Scan updated with user correction');
    } catch (e) {
      debugPrint('[FoodLogService] ⚠️ Failed to update cached scan: $e');
    }
  }

  // ─── Ambil cached scans untuk training dataset ─────────────────────────────
  Future<List<Map<String, dynamic>>> getCorrectedScans({
    int limit = 100,
  }) async {
    try {
      final data = await _sb
          .from('local_scans')
          .select()
          .eq('is_user_corrected', true)
          .order('corrected_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[FoodLogService] Error getting corrected scans: $e');
      return [];
    }
  }

  // ─── Get cached scan by food name (untuk improve future predictions) ────────
  Future<CachedFoodScan?> getCachedScanByName(String foodName) async {
    try {
      final data = await _sb
          .from('local_scans')
          .select()
          .ilike('food_name', '%$foodName%')
          .order('scanned_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data != null) {
        return CachedFoodScan.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('[FoodLogService] Error getting cached scan: $e');
      return null;
    }
  }

  // ─── Export dataset untuk training ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> exportTrainingDataset() async {
    try {
      final correctedScans = await getCorrectedScans(limit: 1000);
      final dataset = <Map<String, dynamic>>[];

      for (final scan in correctedScans) {
        final correction = scan['user_correction'] as Map<String, dynamic>?;
        if (correction != null) {
          dataset.add({
            'food_name': scan['food_name'],
            'image_path': scan['image_path'],
            'calories': correction['calories'] ?? scan['calories'],
            'protein': correction['protein'] ?? scan['protein'],
            'carbs': correction['carbs'] ?? scan['carbs'],
            'fat': correction['fat'] ?? scan['fat'],
            'fiber': correction['fiber'] ?? scan['fiber'],
            'sugar_grms': correction['sugarGrams'] ?? scan['sugar_grms'],
            'serving': correction['serving'] ?? scan['serving'],
            'ingredients': correction['ingredients'] ?? scan['ingredients'],
            'category': correction['category'] ?? scan['category'],
          });
        }
      }

      return dataset;
    } catch (e) {
      debugPrint('[FoodLogService] Error exporting training dataset: $e');
      return [];
    }
  }
}
