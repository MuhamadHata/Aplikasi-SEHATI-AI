// ==========================================
// BAGIAN: MODEL DATA
// Berisi definisi struktur data dan objek yang digunakan dalam aplikasi.
// ==========================================

import 'dart:convert';

// Mock data models for SEHATI-AI app

class FoodItem {
  final int id;
  final String name;
  final String emoji;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String category;
  final String serving;
  final String recommendation;
  final List<String> citationCodes;
  final List<String> ingredients;
  final double sugarGrams;
  final int caffeineMg;

  const FoodItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.category,
    required this.serving,
    required this.recommendation,
    this.citationCodes = const [],
    this.ingredients = const [],
    this.sugarGrams = 0.0,
    this.caffeineMg = 0,
  });
}

class BeautyResult {
  final int hydration;
  final int fatigue;
  final String skinTone;
  final String acneRisk;
  final String activeAcneLevel;
  final String acneScarLevel;
  final String lesionEstimate;
  final String scarType;
  final List<String> detectedZones;
  final int agingScore;
  final int estimatedAge;
  final List<String> recommendations;
  final List<String> citationCodes;
  final String summary;
  final List<String> visibleFindings;
  final int confidence;
  final String agingFormula;
  final List<String> agingBreakdown;

  const BeautyResult({
    required this.hydration,
    required this.fatigue,
    required this.skinTone,
    required this.acneRisk,
    this.activeAcneLevel = 'Tidak Tampak',
    this.acneScarLevel = 'Tidak Tampak',
    this.lesionEstimate = '-',
    this.scarType = '-',
    this.detectedZones = const [],
    required this.agingScore,
    required this.estimatedAge,
    required this.recommendations,
    this.citationCodes = const [],
    this.summary = '',
    this.visibleFindings = const [],
    this.confidence = 0,
    this.agingFormula = '',
    this.agingBreakdown = const [],
  });
}

class Article {
  final int id;
  final String title;
  final String subtitle;
  final String emoji;
  final String readTime;
  final int colorHex;
  final String content;
  final String? imageUrl;
  final String? url;

  const Article({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.readTime,
    required this.colorHex,
    required this.content,
    this.imageUrl,
    this.url,
  });
}

class WorkoutPlan {
  final int id;
  final String name;
  final String emoji;
  final String duration;
  final String level;
  final int calories;
  final String category;
  final List<String> exercises;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.emoji,
    required this.duration,
    required this.level,
    required this.calories,
    required this.category,
    required this.exercises,
  });
}

class FoodLogEntry {
  final String time;
  final String name;
  final String emoji;
  final int cal;
  final String meal;
  final String? photoPath;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sugarGrams;
  final String? serving;
  final List<String>? ingredients;
  final String? category;
  final DateTime? loggedAt;

  const FoodLogEntry({
    required this.time,
    required this.name,
    required this.emoji,
    required this.cal,
    required this.meal,
    this.photoPath,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugarGrams,
    this.serving,
    this.ingredients,
    this.category,
    this.loggedAt,
  });

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'name': name,
      'emoji': emoji,
      'cal': cal,
      'meal': meal,
      'photoPath': photoPath,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugarGrams': sugarGrams,
      'serving': serving,
      'ingredients': ingredients?.join(','),
      'category': category,
      'loggedAt': loggedAt?.toIso8601String(),
    };
  }

  /// Create from Map (database retrieval)
  factory FoodLogEntry.fromMap(Map<String, dynamic> map) {
    return FoodLogEntry(
      time: map['time'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '🍽️',
      cal: map['cal'] ?? 0,
      meal: map['meal'] ?? '',
      photoPath: map['photoPath'],
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble(),
      sugarGrams: (map['sugarGrams'] as num?)?.toDouble(),
      serving: map['serving'],
      ingredients: map['ingredients'] != null
          ? (map['ingredients'] as String).split(',')
          : null,
      category: map['category'],
      loggedAt: map['loggedAt'] != null
          ? DateTime.tryParse(map['loggedAt'])
          : null,
    );
  }
}

/// Model untuk hasil scan makanan yang di-cache untuk continual learning
class CachedFoodScan {
  final int id;
  final String foodName;
  final String imagePath;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugarGrams;
  final String serving;
  final List<String> ingredients;
  final String category;
  final DateTime scannedAt;
  final bool isUserCorrected;
  final Map<String, dynamic>? userCorrection;

  const CachedFoodScan({
    required this.id,
    required this.foodName,
    required this.imagePath,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugarGrams,
    required this.serving,
    required this.ingredients,
    required this.category,
    required this.scannedAt,
    this.isUserCorrected = false,
    this.userCorrection,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodName': foodName,
      'imagePath': imagePath,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugarGrams': sugarGrams,
      'serving': serving,
      'ingredients': ingredients.join('|'),
      'category': category,
      'scannedAt': scannedAt.toIso8601String(),
      'isUserCorrected': isUserCorrected ? 1 : 0,
      'userCorrection': userCorrection != null
          ? jsonEncode(userCorrection)
          : null,
    };
  }

  factory CachedFoodScan.fromMap(Map<String, dynamic> map) {
    return CachedFoodScan(
      id: map['id'] ?? 0,
      foodName: map['foodName'] ?? '',
      imagePath: map['imagePath'] ?? '',
      calories: map['calories'] ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0,
      sugarGrams: (map['sugarGrams'] as num?)?.toDouble() ?? 0,
      serving: map['serving'] ?? '',
      ingredients: (map['ingredients'] as String?)?.split('|') ?? [],
      category: map['category'] ?? 'Umum',
      scannedAt: DateTime.tryParse(map['scannedAt'] ?? '') ?? DateTime.now(),
      isUserCorrected: map['isUserCorrected'] == 1,
      userCorrection: map['userCorrection'] != null
          ? jsonDecode(map['userCorrection'])
          : null,
    );
  }
}
