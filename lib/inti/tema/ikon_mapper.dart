import 'package:flutter/material.dart';

/// Mapper emoji → Material Symbols (https://fonts.google.com/icons)
/// Profesional, konsisten, Trust Blue + Healing Mint palette.
/// Digunakan untuk menggantikan seluruh emoji di UI agar bebas AI Slop.
class IkonMapper {
  static IconData dariEmoji(String emoji) {
    // Normalisasi: hapus variation selector, trim
    final e = emoji.trim();
    switch (e) {
      // ── Health & Hydration ──
      case '💧':
      case '💦':
        return Icons.water_drop_rounded;
      case '🚶':
        return Icons.directions_walk_rounded;
      case '🏃':
      case '🏃‍♂️':
      case '🏃‍♀️':
        return Icons.directions_run_rounded;
      case '👟':
        return Icons.directions_walk_rounded;
      case '😴':
      case '💤':
        return Icons.bedtime_rounded;
      case '🥗':
      case '🍱':
      case '🍲':
      case '🍛':
      case '🍽️':
      case '🍽':
        return Icons.restaurant_rounded;
      case '🍎':
      case '🍏':
      case '🍊':
      case '🍇':
        return Icons.eco_rounded;
      case '🍔':
      case '🍕':
        return Icons.fastfood_rounded;
      case '🚭':
        return Icons.smoke_free_rounded;
      case '🔥':
        return Icons.local_fire_department_rounded;
      case '🧘':
      case '🧘‍♀️':
      case '🧘‍♂️':
        return Icons.self_improvement_rounded;
      case '📊':
      case '📈':
      case '📉':
        return Icons.bar_chart_rounded;
      case '🔔':
        return Icons.notifications_rounded;
      case '🎉':
      case '✨':
      case '🌟':
        return Icons.celebration_rounded;
      case '💪':
        return Icons.fitness_center_rounded;
      case '👍':
        return Icons.thumb_up_rounded;
      case '😔':
        return Icons.sentiment_dissatisfied_rounded;
      case '📅':
        return Icons.calendar_today_rounded;
      case '✅':
      case '✔️':
        return Icons.check_circle_rounded;
      case '⚖️':
      case '⚖':
        return Icons.monitor_weight_rounded;
      case '📏':
        return Icons.straighten_rounded;
      case '🎂':
        return Icons.cake_rounded;
      case '👨':
      case '👩':
      case '👤':
        return Icons.person_rounded;
      case '🧠':
        return Icons.psychology_rounded;
      case '⭐':
        return Icons.star_rounded;
      case '⚠️':
      case '⚠':
        return Icons.warning_rounded;
      case '☀️':
      case '☀':
        return Icons.wb_sunny_rounded;
      case '🏆':
        return Icons.emoji_events_rounded;
      case '💎':
        return Icons.diamond_rounded;
      case '🌱':
        return Icons.spa_rounded;
      case '👁️':
        return Icons.visibility_rounded;
      case '📍':
        return Icons.location_on_rounded;
      case '⏱️':
        return Icons.timer_rounded;
      case '❤️':
      case '💖':
      case '💓':
        return Icons.favorite_rounded;
      case '🩺':
        return Icons.medical_services_rounded;
      case '🏥':
        return Icons.local_hospital_rounded;
      case '💊':
        return Icons.medication_rounded;
      case '🧬':
        return Icons.biotech_rounded;
      case '📚':
        return Icons.menu_book_rounded;
      default:
        // Fallback: coba deteksi substring
        if (e.contains('💧') || e.contains('water')) return Icons.water_drop_rounded;
        if (e.contains('🔥')) return Icons.local_fire_department_rounded;
        if (e.contains('👟') || e.contains('🚶') || e.contains('🏃')) return Icons.directions_walk_rounded;
        if (e.contains('🍲') || e.contains('🍱') || e.contains('🥗') || e.contains('🍽')) return Icons.restaurant_rounded;
        if (e.contains('😴') || e.contains('💤')) return Icons.bedtime_rounded;
        if (e.contains('🧘')) return Icons.self_improvement_rounded;
        if (e.contains('📊') || e.contains('📈')) return Icons.bar_chart_rounded;
        if (e.contains('🔔')) return Icons.notifications_rounded;
        return Icons.health_and_safety_rounded;
    }
  }

  static IconData dariLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('air') || l.contains('hidrasi') || l.contains('water')) return Icons.water_drop_rounded;
    if (l.contains('langkah') || l.contains('jalan') || l.contains('step')) return Icons.directions_walk_rounded;
    if (l.contains('lari') || l.contains('run')) return Icons.directions_run_rounded;
    if (l.contains('kalori') || l.contains('makan') || l.contains('food')) return Icons.restaurant_rounded;
    if (l.contains('tidur') || l.contains('sleep')) return Icons.bedtime_rounded;
    if (l.contains('bakar') || l.contains('fire') || l.contains('burn')) return Icons.local_fire_department_rounded;
    if (l.contains('bmi') || l.contains('berat') || l.contains('weight')) return Icons.monitor_weight_rounded;
    if (l.contains('tinggi') || l.contains('height')) return Icons.straighten_rounded;
    if (l.contains('usia') || l.contains('age') || l.contains('cake')) return Icons.cake_rounded;
    if (l.contains('diet')) return Icons.restaurant_rounded;
    if (l.contains('konsisten') || l.contains('target')) return Icons.track_changes_rounded;
    if (l.contains('mbti') || l.contains('otak') || l.contains('psik')) return Icons.psychology_rounded;
    return Icons.health_and_safety_rounded;
  }
}

/// Extension helper untuk Text yang mengandung emoji di awal label
/// Contoh: '🥗 Diet Aktif' → 'Diet Aktif' + Icon
extension StringTanpaEmoji on String {
  String get tanpaEmoji {
    // Hapus semua emoji di awal string
    return replaceAll(RegExp(r'^[\u{1F000}-\u{1FFFF}\u2600-\u27BF\uFE00-\uFE0F\s]+', unicode: true), '').trim();
  }
}
