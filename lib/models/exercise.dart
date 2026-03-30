import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String? id;
  final String name;
  final int durationMinutes;
  final int caloriesBurned;
  final String exerciseType;
  final DateTime dateTime;

  Exercise({
    this.id,
    required this.name,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.exerciseType,
    required this.dateTime,
  });

  String get exerciseTypeLabel {
    switch (exerciseType) {
      case 'cardio': return 'Cardio';
      case 'strength': return 'Sức mạnh';
      case 'flexibility': return 'Linh hoạt';
      case 'sports': return 'Thể thao';
      default: return exerciseType;
    }
  }

  static int calculateCalories(double metValue, double weightKg, int minutes) {
    return (metValue * weightKg * minutes / 60).round();
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'exerciseType': exerciseType,
        'dateTime': Timestamp.fromDate(dateTime),
      };

  factory Exercise.fromMap(Map<String, dynamic> map, {String? id}) =>
      Exercise(
        id: id,
        name: map['name'] as String,
        durationMinutes: map['durationMinutes'] as int,
        caloriesBurned: map['caloriesBurned'] as int,
        exerciseType: map['exerciseType'] as String,
        dateTime: (map['dateTime'] is Timestamp)
            ? (map['dateTime'] as Timestamp).toDate()
            : DateTime.parse(map['dateTime'] as String),
      );
}
