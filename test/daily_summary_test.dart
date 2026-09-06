import 'package:flutter_test/flutter_test.dart';
import 'package:sehati_ai/inti/model/catatan_aktivitas.dart';

void main() {
  group('DailySummary Model Tests', () {
    test('Serializes to Supabase snake_case schema correctly', () {
      final summary = DailySummary(
        date: '2026-09-06',
        caloriesConsumed: 1850,
        caloriesBurned: 320,
        steps: 7500,
        waterGlasses: 8,
        sleepHours: 7.2,
        isSmoker: false,
        foodLogs: [],
      );

      final supabaseMap = summary.toSupabaseJson('user-uuid-123');

      expect(supabaseMap['user_id'], 'user-uuid-123');
      expect(supabaseMap['date'], '2026-09-06');
      expect(supabaseMap['steps'], 7500);
      expect(supabaseMap['calories_burned'], 320);
      expect(supabaseMap['calorie_consumed'], 1850);
      expect(supabaseMap['calories_consumed'], 1850);
      expect(supabaseMap['water_glasses'], 8);
      expect(supabaseMap['sleep_hours'], 7.2);
      expect(supabaseMap['is_smoker'], false);
      expect(supabaseMap.containsKey('caloriesBurned'), false);
      expect(supabaseMap.containsKey('caloriesConsumed'), false);
      expect(supabaseMap.containsKey('waterGlasses'), false);
    });

    test('Parses from Supabase snake_case without data loss', () {
      final serverJson = {
        'user_id': 'user-uuid-123',
        'date': '2026-09-01',
        'steps': 6200,
        'calories_burned': 280,
        'calorie_consumed': 1750,
        'water_glasses': 7,
        'sleep_hours': 6.8,
        'is_smoker': false,
        'food_logs': [],
      };

      final parsed = DailySummary.fromJson(serverJson);

      expect(parsed.date, '2026-09-01');
      expect(parsed.steps, 6200);
      expect(parsed.caloriesBurned, 280);
      expect(parsed.caloriesConsumed, 1750);
      expect(parsed.waterGlasses, 7);
      expect(parsed.sleepHours, 6.8);
      expect(parsed.isSmoker, false);
    });

    test('Parses from local SharedPreferences camelCase without data loss', () {
      final localJson = {
        'date': '2026-08-28',
        'caloriesConsumed': 2100,
        'caloriesBurned': 350,
        'steps': 8200,
        'waterGlasses': 9,
        'sleepHours': 7.5,
        'isSmoker': false,
        'foodLogs': [],
      };

      final parsed = DailySummary.fromJson(localJson);

      expect(parsed.date, '2026-08-28');
      expect(parsed.steps, 8200);
      expect(parsed.caloriesBurned, 350);
      expect(parsed.caloriesConsumed, 2100);
      expect(parsed.waterGlasses, 9);
      expect(parsed.sleepHours, 7.5);
    });

    test('ActivityRecord toSupabaseJson matches activity_history schema', () {
      final session = ActivityRecord(
        id: 'rec-123',
        type: 'Lari',
        date: DateTime.parse('2026-09-06T07:30:00.000Z'),
        durationSeconds: 1800,
        distanceKm: 4.5,
        calories: 320,
        steps: 5400,
        averagePace: 6.67,
        route: [],
      );

      final supabaseMap = session.toSupabaseJson('user-uuid-123');

      expect(supabaseMap['id'], 'rec-123');
      expect(supabaseMap['user_id'], 'user-uuid-123');
      expect(supabaseMap['duration_seconds'], 1800);
      expect(supabaseMap['distance_km'], 4.5);
      expect(supabaseMap['calories'], 320);
      expect(supabaseMap.containsKey('durationSeconds'), false);
      expect(supabaseMap.containsKey('distanceKm'), false);
    });
  });
}
