// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseDBService {
  static const String _baseUrl = 'https://exercisedbv2.ascendapi.com/api/v1';

  static Map<String, String> get _headers => {};

  /// Search for exercises by name
  Future<List<Map<String, dynamic>>> searchExercises(String name) async {
    try {
      final query = Uri.encodeComponent(name.toLowerCase());
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/search?name=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in ExerciseDBService.searchExercises: $e');
      return [];
    }
  }

  /// Get exercise by ID
  Future<Map<String, dynamic>?> getExerciseById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exercises/exercise/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception(
            'Failed to load exercise by ID: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in ExerciseDBService.getExerciseById: $e');
      return null;
    }
  }
}
