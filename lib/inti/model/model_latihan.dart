// ==========================================
// BAGIAN: MODEL DATA
// Berisi definisi struktur data dan objek yang digunakan dalam aplikasi.
// ==========================================

class ExerciseModel {
  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String target;
  final String gifUrl;
  final List<String> secondaryMuscles;
  final List<String> instructions;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.target,
    required this.gifUrl,
    required this.secondaryMuscles,
    required this.instructions,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      bodyPart: json['bodyPart'] as String? ?? 'Unknown',
      equipment: json['equipment'] as String? ?? 'Unknown',
      target: json['target'] as String? ?? 'Unknown',
      gifUrl: json['gifUrl'] as String? ?? '',
      secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bodyPart': bodyPart,
      'equipment': equipment,
      'target': target,
      'gifUrl': gifUrl,
      'secondaryMuscles': secondaryMuscles,
      'instructions': instructions,
    };
  }
}
