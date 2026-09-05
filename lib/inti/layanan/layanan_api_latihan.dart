// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/model_latihan.dart';

class ExerciseApiService {
  static const String _baseUrl = "https://exercisedb.p.rapidapi.com";
  static const String _apiKey =
      "881a442ac5msh3db597c658d6bedp16c9eejsn2bde14f733c6"; // USER PROVIDED
  static const String _apiHost = "exercisedb.p.rapidapi.com";

  static final Map<String, String> _headers = {
    'x-rapidapi-key': _apiKey,
    'x-rapidapi-host': _apiHost,
  };

  /// Fetch a list of all exercises (paginated).
  static Future<List<ExerciseModel>> fetchExercises(
      {int limit = 50, int offset = 0}) async {
    final url = Uri.parse("$_baseUrl/exercises?limit=$limit&offset=$offset");
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExerciseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exercises: ${response.statusCode}');
    }
  }

  /// Fetch a list of exercises targeting a specific body part.
  static Future<List<ExerciseModel>> fetchExercisesByBodyPart(String bodyPart,
      {int limit = 50, int offset = 0}) async {
    final url = Uri.parse(
        "$_baseUrl/exercises/bodyPart/$bodyPart?limit=$limit&offset=$offset");
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExerciseModel.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load body part exercises: ${response.statusCode}');
    }
  }

  /// Fetch list of available body parts.
  static Future<List<String>> fetchBodyPartList() async {
    final url = Uri.parse("$_baseUrl/exercises/bodyPartList");
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to load body part list: ${response.statusCode}');
    }
  }

  /// Fetch exercises by name search
  static Future<List<ExerciseModel>> fetchExercisesByName(String name,
      {int limit = 50, int offset = 0}) async {
    final url =
        Uri.parse("$_baseUrl/exercises/name/$name?limit=$limit&offset=$offset");
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExerciseModel.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load exercises by name: ${response.statusCode}');
    }
  }
}
