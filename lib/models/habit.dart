import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String? id;
  final String name;
  final String icon;
  final String frequency;
  final DateTime createdAt;
  final List<DateTime> completedDates;

  Habit({
    this.id,
    required this.name,
    required this.icon,
    this.frequency = 'daily',
    required this.createdAt,
    this.completedDates = const [],
  });

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    final sorted = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime checkDate = DateTime.now();
    for (final date in sorted) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final checkOnly = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final diff = checkOnly.difference(dateOnly).inDays;
      if (diff <= 1) {
        streak++;
        checkDate = dateOnly;
      } else {
        break;
      }
    }
    return streak;
  }

  bool get isCompletedToday {
    final now = DateTime.now();
    return completedDates.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'frequency': frequency,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map, {String? id, List<DateTime>? completedDates}) {
    return Habit(
      id: id,
      name: map['name'] as String,
      icon: map['icon'] as String,
      frequency: map['frequency'] as String? ?? 'daily',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      completedDates: completedDates ?? [],
    );
  }
}
