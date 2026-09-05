// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Fetches & caches animated GIF URLs from ExerciseDB RapidAPI.
/// Uses the existing API key from exercise_api_service.dart.
class ExerciseGifCache {
  static const String _baseUrl = 'https://exercisedb.p.rapidapi.com';
  static const String _apiKey =
      '881a442ac5msh3db597c658d6bedp16c9eejsn2bde14f733c6';
  static const String _apiHost = 'exercisedb.p.rapidapi.com';

  // In-memory cache: lowercase exercise name → gifUrl (empty string = not found)
  static final Map<String, String> _cache = {};

  // Fetches are tracked to avoid duplicate concurrent requests
  static final Map<String, Future<String?>> _pending = {};

  /// Returns an animated GIF URL for [exerciseName], or null if unavailable.
  ///
  /// Order of resolution:
  ///   1. In-memory cache
  ///   2. ExerciseDB API search by name (limit 1)
  static Future<String?> getGifUrl(String exerciseName) {
    final key = exerciseName.toLowerCase().trim();

    // 1. Cache hit
    if (_cache.containsKey(key)) {
      return Future.value(_cache[key]!.isEmpty ? null : _cache[key]);
    }

    // 2. Deduplicate concurrent calls for same exercise
    if (_pending.containsKey(key)) return _pending[key]!;

    final future = _fetchFromApi(key).then((url) {
      _cache[key] = url ?? '';
      _pending.remove(key);
      return url;
    });

    _pending[key] = future;
    return future;
  }

  static Future<String?> _fetchFromApi(String exerciseName) async {
    try {
      final encoded = Uri.encodeComponent(exerciseName);
      final uri =
          Uri.parse('$_baseUrl/exercises/name/$encoded?limit=1&offset=0');
      final response = await http.get(uri, headers: {
        'x-rapidapi-key': _apiKey,
        'x-rapidapi-host': _apiHost,
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final gifUrl = data.first['gifUrl'] as String? ?? '';
          if (gifUrl.isNotEmpty) return gifUrl;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ExerciseGifCache] fetch failed for "$exerciseName": $e');
      }
    }
    return null;
  }

  /// Pre-warm the cache for a list of exercise names.
  /// Call this when the workout starts to load all GIFs in parallel.
  static Future<void> preWarm(List<String> exerciseNames) async {
    await Future.wait(exerciseNames.map(getGifUrl));
  }

  static void clearCache() {
    _cache.clear();
    _pending.clear();
  }
}
