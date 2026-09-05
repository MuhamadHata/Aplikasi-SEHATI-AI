import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AIFeedbackService — Mengirim koreksi nutrisi user ke Supabase
//
// Filosofi: Koreksi user dikumpulkan di tabel `ai_feedback` (staging),
// lalu dipindahkan ke dataset fine-tuning Gemini melalui Python script.
// Pengetahuan akhirnya tersimpan di BOBOT MODEL AI, bukan di database.
// ═══════════════════════════════════════════════════════════════════════════
class AIFeedbackService {
  AIFeedbackService._();
  static final AIFeedbackService instance = AIFeedbackService._();

  SupabaseClient get _sb => Supabase.instance.client;

  // ─── Submit koreksi nutrisi (user mengoreksi data AI yang salah) ─────────
  Future<bool> submitCorrection({
    required String foodName,
    required Map<String, dynamic> aiPrediction,
    required Map<String, dynamic> userCorrection,
    String? scanImageHash,
    double? confidenceScore,
  }) async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[AIFeedback] User belum login, skip koreksi.');
        return false;
      }

      // Validasi: pastikan koreksi berbeda dari prediksi AI
      final bool hasDiff = _hasMeaningfulDifference(aiPrediction, userCorrection);
      if (!hasDiff) {
        debugPrint('[AIFeedback] Koreksi sama dengan prediksi, skip.');
        return false;
      }

      await _sb.from('ai_feedback').insert({
        'user_id': userId,
        'food_name': foodName.trim(),
        'ai_prediction': aiPrediction,
        'user_correction': userCorrection,
        'scan_image_hash': scanImageHash,
        'confidence_score': confidenceScore,
        'feedback_type': 'correction',
        'is_exported': false,
      });

      debugPrint('[AIFeedback] ✅ Koreksi "$foodName" berhasil dikirim.');
      return true;
    } catch (e) {
      debugPrint('[AIFeedback] ❌ Gagal kirim koreksi: $e');
      return false;
    }
  }

  // ─── Submit konfirmasi (user menyatakan data AI sudah benar) ─────────────
  Future<bool> submitConfirmation({
    required String foodName,
    required Map<String, dynamic> aiPrediction,
    String? scanImageHash,
  }) async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) return false;

      await _sb.from('ai_feedback').insert({
        'user_id': userId,
        'food_name': foodName.trim(),
        'ai_prediction': aiPrediction,
        'user_correction': aiPrediction, // sama = konfirmasi
        'scan_image_hash': scanImageHash,
        'confidence_score': 1.0,
        'feedback_type': 'confirmation',
        'is_exported': false,
      });

      debugPrint('[AIFeedback] ✅ Konfirmasi "$foodName" berhasil dikirim.');
      return true;
    } catch (e) {
      debugPrint('[AIFeedback] ❌ Gagal kirim konfirmasi: $e');
      return false;
    }
  }

  // ─── Statistik kontribusi user (untuk gamifikasi) ─────────────────────────
  Future<Map<String, int>> getMyStats() async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) return {'total': 0, 'corrections': 0, 'confirmations': 0};

      final data = await _sb
          .from('ai_feedback_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return {'total': 0, 'corrections': 0, 'confirmations': 0};

      return {
        'total': (data['total_feedbacks'] as num?)?.toInt() ?? 0,
        'corrections': (data['total_corrections'] as num?)?.toInt() ?? 0,
        'confirmations': (data['total_confirmations'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      debugPrint('[AIFeedback] Gagal ambil stats: $e');
      return {'total': 0, 'corrections': 0, 'confirmations': 0};
    }
  }

  // ─── Cek apakah ada perbedaan signifikan antara prediksi vs koreksi ───────
  bool _hasMeaningfulDifference(
    Map<String, dynamic> prediction,
    Map<String, dynamic> correction,
  ) {
    const keys = ['calories', 'protein', 'carbs', 'fat', 'fiber', 'sugarGrams'];
    for (final key in keys) {
      final pred = (prediction[key] as num?)?.toDouble() ?? 0.0;
      final corr = (correction[key] as num?)?.toDouble() ?? 0.0;
      // Anggap berbeda jika selisih > 5% atau > 1 unit
      if ((pred - corr).abs() > 1.0 || (pred > 0 && (pred - corr).abs() / pred > 0.05)) {
        return true;
      }
    }
    return false;
  }

  // ─── Konversi FoodItem ke Map untuk ai_prediction / user_correction ───────
  static Map<String, dynamic> foodItemToMap({
    required String name,
    required String serving,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    required double sugarGrams,
    required int caffeineMg,
  }) {
    return {
      'name': name,
      'serving': serving,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugarGrams': sugarGrams,
      'caffeineMg': caffeineMg,
    };
  }
}
