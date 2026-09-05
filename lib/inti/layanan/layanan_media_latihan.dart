// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../model/basis_data_latihan_lokal.dart';

class ExerciseMediaService {
  static const String _baseUrl =
      'https://exercisedbv2.ascendapi.com/api/v1/exercises/search';

  /// Returns the media URL (asset path or network GIF) for an exercise name.
  ///
  /// Priority:
  /// 1. Check local database -> return assetPath if GIF file exists locally
  /// 2. Check local database -> return gifUrl (network) as cached fallback
  /// 3. Call AscendAPI dynamically if no match in local DB
  Future<String?> fetchMediaUrl(String exerciseName) async {
    try {
      String query = exerciseName.replaceAll(RegExp(r'\(.*\)'), '').trim();

      // 1. Try local database first
      final local = LocalExerciseDatabase.findByName(query);
      if (local != null) {
        // Try to load the local asset to verify it exists
        try {
          await rootBundle.load(local.assetPath);
          return local.assetPath; // valid local asset
        } catch (_) {
          // Local asset not found, use network GIF from DB
          return local.gifUrl;
        }
      }

      // 2. Dynamic AscendAPI call if no local entry found
      final url = Uri.parse('$_baseUrl?name=${Uri.encodeComponent(query)}');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data[0]['gifUrl'] as String?;
        }
      }
    } catch (e) {
      print('[ExerciseMediaService] Error for $exerciseName: $e');
    }
    return null;
  }

  /// Returns the local asset path for an exercise (or null if not in DB).
  static String? localAssetPath(String exerciseName) {
    final local = LocalExerciseDatabase.findByName(exerciseName);
    return local?.assetPath;
  }

  /// Returns the network GIF URL from the local DB (for direct use).
  static String? localGifUrl(String exerciseName) {
    final local = LocalExerciseDatabase.findByName(exerciseName);
    return local?.gifUrl;
  }
}
