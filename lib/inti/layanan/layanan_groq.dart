// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Groq API Service — Fast LLM calls using Groq's API.
/// Replace [apiKey] with your actual Groq API key from console.groq.com
class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Groq API Key dikonfigurasi via environment variable atau asset config
  static const String _apiKey =
      String.fromEnvironment('NUBI_GROQ_KEYS', defaultValue: '');

  // Model options: llama3-8b-8192, llama3-70b-8192, mixtral-8x7b-32768, gemma-7b-it
  static const String _defaultModel = 'llama3-8b-8192';

  /// Chat completion with anti-hallucination system prompt
  static Future<String> chat({
    required String userMessage,
    String? systemPrompt,
    String model = _defaultModel,
    double temperature = 0.4,
  }) async {
    final effectiveSystem = systemPrompt ??
        '''Anda adalah SEHATI-AI, asisten kesehatan dan kebugaran pribadi dalam bahasa Indonesia.
Aturan ketat:
1. HANYA jawab pertanyaan terkait kesehatan, nutrisi, olahraga, dan kebugaran.
2. Jika ditanya di luar topik tersebut, tolak dengan sopan.
3. TIDAK boleh membuat data medis atau angka kalori yang tidak Anda yakini kebenarannya.
4. Selalu sarankan konsultasi dokter untuk masalah medis serius.
5. Jawab dengan singkat, jelas, dan praktis. Gunakan emoji yang relevan.
6. JANGAN hallucinate nama makanan, obat, atau suplemen yang tidak ada.''';

    if (_apiKey.isEmpty) {
      return 'Groq API Key belum dikonfigurasi. Harap tentukan via --dart-define=NUBI_GROQ_KEYS=...';
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': effectiveSystem},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': temperature,
          'max_tokens': 1024,
          'top_p': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else if (response.statusCode == 401) {
        return 'Error: API key tidak valid. Harap periksa konfigurasi Groq API key Anda.';
      } else {
        final errData = jsonDecode(response.body);
        return 'Error Groq API: ${errData['error']?['message'] ?? response.statusCode}';
      }
    } catch (e) {
      return 'Koneksi gagal: $e. Pastikan perangkat terhubung ke internet.';
    }
  }

  /// Quick food analysis — estimates nutrition from food name + portion
  static Future<String> analyzeFoodNutrition(String foodDescription) async {
    return chat(
      userMessage: 'Analisis nilai gizi singkat untuk: $foodDescription\n'
          'Format jawaban:\n'
          '🍽️ [Nama Makanan]\n'
          '⚡ Kalori: ~X kkal\n'
          '🥩 Protein: ~Xg | 🍞 Karbo: ~Xg | 🧈 Lemak: ~Xg\n'
          '💡 Tips: [1 kalimat saran]\n'
          'Jika tidak yakin, tulis "estimasi kasar" dan berikan range.',
      temperature: 0.2,
    );
  }

  /// Exercise recommendation based on profile
  static Future<String> getExerciseRecommendation({
    required String dietProgram,
    required double bmi,
    required int daysPerWeek,
  }) async {
    return chat(
      userMessage: 'Buat rencana olahraga mingguan singkat untuk:\n'
          '- Program diet: $dietProgram\n'
          '- IMT: ${bmi.toStringAsFixed(1)}\n'
          '- Frekuensi: $daysPerWeek hari/minggu\n'
          'Berikan jadwal singkat dengan durasi dan tipe latihan.',
      temperature: 0.3,
    );
  }

  /// Beauty & health skin analysis
  static Future<String> analyzeSkinHealth(String skinDescription) async {
    return chat(
      userMessage:
          'Tips singkat perawatan untuk kondisi kulit: $skinDescription\n'
          'Berikan: 1) Kemungkinan penyebab, 2) Rekomendasi perawatan alami, 3) Kapan ke dokter.',
      temperature: 0.3,
    );
  }

  static bool get isConfigured => _apiKey != 'YOUR_GROQ_API_KEY_HERE';
}
