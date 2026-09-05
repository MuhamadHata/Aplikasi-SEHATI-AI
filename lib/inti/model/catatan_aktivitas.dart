// ==========================================
// BAGIAN: MODEL DATA
// Berisi definisi struktur data dan objek yang digunakan dalam aplikasi.
// ==========================================

import 'package:latlong2/latlong.dart';

class FoodLog {
  final String foodName;
  final int calories;
  final String time;
  final String emoji;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugarGrams;
  final int caffeineMg;
  final String? photoPath;
  final String? serving;
  final List<String>? ingredients;
  final String? category;
  final String mealType;

  FoodLog({
    required this.foodName,
    required this.calories,
    required this.time,
    this.emoji = '🍽️',
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.fiber = 0.0,
    this.sugarGrams = 0.0,
    this.caffeineMg = 0,
    this.photoPath,
    this.serving,
    this.ingredients,
    this.category,
    this.mealType = 'camilan',
  });

  Map<String, dynamic> toJson() => {
        'foodName': foodName,
        'calories': calories,
        'time': time,
        'emoji': emoji,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugarGrams': sugarGrams,
        'caffeineMg': caffeineMg,
        'photoPath': photoPath,
        'serving': serving,
        'ingredients': ingredients?.join('|'),
        'category': category,
        'mealType': mealType,
      };

  factory FoodLog.fromJson(Map<String, dynamic> json) => FoodLog(
        foodName: json['foodName'] ?? '',
        calories: json['calories'] ?? 0,
        time: json['time'] ?? '',
        emoji: json['emoji'] ?? '🍽️',
        protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
        sugarGrams: (json['sugarGrams'] as num?)?.toDouble() ?? 0.0,
        caffeineMg: json['caffeineMg'] ?? 0,
        photoPath: json['photoPath'],
        serving: json['serving'],
        ingredients: (json['ingredients'] as String?)?.split('|'),
        category: json['category'],
        mealType: json['mealType'] ?? 'camilan',
      );
}

class ActivityRecord {
  final String id;
  final String type; // 'Lari' or 'Jalan'
  final DateTime date;
  final int durationSeconds;
  final double distanceKm;
  final int calories;
  final int steps;
  final double averagePace; // min/km
  final List<LatLng> route;

  ActivityRecord({
    required this.id,
    required this.type,
    required this.date,
    required this.durationSeconds,
    required this.distanceKm,
    required this.calories,
    required this.steps,
    required this.averagePace,
    required this.route,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'distanceKm': distanceKm,
      'calories': calories,
      'steps': steps,
      'averagePace': averagePace,
      'route': route
          .map((latLng) => {
                'lat': latLng.latitude,
                'lng': latLng.longitude,
              })
          .toList(),
    };
  }

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['date'] ?? json['created_at'] ?? json['timestamp'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    final rawDistance =
        json['distanceKm'] ?? json['distance_km'] ?? json['distance'];
    final distance = (rawDistance is num)
        ? rawDistance.toDouble()
        : double.tryParse('$rawDistance') ?? 0.0;

    final rawDuration =
        json['durationSeconds'] ?? json['duration_seconds'] ?? json['duration'];
    final duration = (rawDuration is num)
        ? rawDuration.toInt()
        : int.tryParse('$rawDuration') ?? 0;

    final rawPace =
        json['averagePace'] ?? json['average_pace'] ?? json['pace'];
    final pace = (rawPace is num)
        ? rawPace.toDouble()
        : double.tryParse('$rawPace') ?? 0.0;

    final rawCalories = json['calories'] ?? json['calories_burned'];
    final calories = (rawCalories is num)
        ? rawCalories.toInt()
        : int.tryParse('$rawCalories') ?? 0;

    final rawSteps = json['steps'] ?? json['step_count'];
    final steps = (rawSteps is num)
        ? rawSteps.toInt()
        : int.tryParse('$rawSteps') ?? 0;

    final List<LatLng> parsedRoute = [];
    final rawRoute = json['route'] ?? json['route_coordinates'];
    if (rawRoute is List) {
      for (final p in rawRoute) {
        if (p is Map) {
          final lat = p['lat'] ?? p['latitude'];
          final lng = p['lng'] ?? p['longitude'];
          final latVal =
              (lat is num) ? lat.toDouble() : double.tryParse('$lat');
          final lngVal =
              (lng is num) ? lng.toDouble() : double.tryParse('$lng');
          if (latVal != null && lngVal != null) {
            parsedRoute.add(LatLng(latVal, lngVal));
          }
        }
      }
    }

    return ActivityRecord(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Lari',
      date: parsedDate,
      durationSeconds: duration,
      distanceKm: distance,
      calories: calories,
      steps: steps,
      averagePace: pace,
      route: parsedRoute,
    );
  }
}

class DailySummary {
  final String date; // yyyy-MM-dd
  final int caloriesConsumed;
  final int caloriesBurned;
  final int steps;
  final int waterGlasses;
  final double sleepHours; // jam tidur hari itu
  final bool isSmoker; // status merokok hari itu
  final List<FoodLog> foodLogs; // detailed food items

  DailySummary({
    required this.date,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.steps,
    required this.waterGlasses,
    this.sleepHours = 0,
    this.isSmoker = false,
    this.foodLogs = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'caloriesConsumed': caloriesConsumed,
      'caloriesBurned': caloriesBurned,
      'steps': steps,
      'waterGlasses': waterGlasses,
      'sleepHours': sleepHours,
      'isSmoker': isSmoker,
      'foodLogs': foodLogs.map((e) => e.toJson()).toList(),
    };
  }

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: json['date'] ?? '',
      caloriesConsumed: json['caloriesConsumed'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      steps: json['steps'] ?? 0,
      waterGlasses: json['waterGlasses'] ?? 0,
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0,
      isSmoker: json['isSmoker'] as bool? ?? false,
      foodLogs: (json['foodLogs'] as List?)
              ?.map((e) => FoodLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ─── Sleep Record ─────────────────────────────────────────────────────────────
class SleepRecord {
  final String date; // yyyy-MM-dd
  final int bedtimeMinute; // menit dari tengah malam (0-1439)
  final int wakeMinute; // menit dari tengah malam (0-1439)
  final double durationHours;

  SleepRecord({
    required this.date,
    required this.bedtimeMinute,
    required this.wakeMinute,
    required this.durationHours,
  });

  /// Format jam tidur sebagai string HH:mm
  String get bedtimeLabel {
    final h = (bedtimeMinute ~/ 60).toString().padLeft(2, '0');
    final m = (bedtimeMinute % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Format jam bangun sebagai string HH:mm
  String get wakeLabel {
    final h = (wakeMinute ~/ 60).toString().padLeft(2, '0');
    final m = (wakeMinute % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Label durasi: "7j 30m"
  String get durationLabel {
    final totalMin = (durationHours * 60).round();
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}j';
    return '${h}j ${m}m';
  }

  bool get isAdequate => durationHours >= 7.0;

  Map<String, dynamic> toJson() => {
        'date': date,
        'bedtimeMinute': bedtimeMinute,
        'wakeMinute': wakeMinute,
        'durationHours': durationHours,
      };

  factory SleepRecord.fromJson(Map<String, dynamic> json) => SleepRecord(
        date: json['date'] ?? '',
        bedtimeMinute:
            (json['bedtimeMinute'] ?? json['bedtime_minute'] ?? 0) as int,
        wakeMinute: (json['wakeMinute'] ?? json['wake_minute'] ?? 420) as int,
        durationHours:
            (json['durationHours'] ?? json['duration_hours'] as num? ?? 0)
                .toDouble(),
      );
}

double _getMetValue(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('run') || lower.contains('lari')) return 8.0;
  if (lower.contains('jump') || lower.contains('lompat')) return 8.0;
  if (lower.contains('squat') || lower.contains('burpee')) return 7.0;
  if (lower.contains('push') || lower.contains('pull')) return 6.0;
  if (lower.contains('plank') || lower.contains('core')) return 4.0;
  if (lower.contains('walk') || lower.contains('jalan')) return 3.8;
  if (lower.contains('stretch') || lower.contains('yoga')) return 2.5;
  return 5.0; // Default MET
}

double calculateCaloriesMet({
  required String exerciseName,
  required double durationSeconds,
  required double weightKg,
}) {
  final met = _getMetValue(exerciseName);
  return met * weightKg * (durationSeconds / 3600.0);
}

double calculateCaloriesForReps({
  required String exerciseName,
  required int repsCompleted,
  required double weightKg,
}) {
  final estimatedSeconds = repsCompleted * 3.0;
  return calculateCaloriesMet(
    exerciseName: exerciseName,
    durationSeconds: estimatedSeconds,
    weightKg: weightKg,
  );
}

class ExerciseSetRecord {
  final String exerciseName;
  final String exerciseNameId;
  final int setNumber;
  final int repsCompleted;
  final int durationSeconds;
  final double caloriesBurned;
  final DateTime completedAt;

  ExerciseSetRecord({
    required this.exerciseName,
    required this.exerciseNameId,
    required this.setNumber,
    required this.repsCompleted,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.completedAt,
  });

  String get displayMetric {
    if (durationSeconds > 0) {
      final m = durationSeconds ~/ 60;
      final s = durationSeconds % 60;
      if (m > 0) return '${m}m ${s}s';
      return '${s}s';
    }
    return '${repsCompleted}x';
  }
}
