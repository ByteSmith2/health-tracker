import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  final String? id;
  final String name;
  final int calories;
  final String? imagePath;
  final DateTime dateTime;
  final String mealType;

  Meal({
    this.id,
    required this.name,
    required this.calories,
    this.imagePath,
    required this.dateTime,
    required this.mealType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'imagePath': imagePath,
      'dateTime': Timestamp.fromDate(dateTime),
      'mealType': mealType,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map, {String? id}) {
    return Meal(
      id: id,
      name: map['name'] as String,
      calories: map['calories'] as int,
      imagePath: map['imagePath'] as String?,
      dateTime: (map['dateTime'] is Timestamp)
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.parse(map['dateTime'] as String),
      mealType: map['mealType'] as String,
    );
  }
}
