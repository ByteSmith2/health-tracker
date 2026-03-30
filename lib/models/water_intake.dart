import 'package:cloud_firestore/cloud_firestore.dart';

class WaterIntake {
  final String? id;
  final int amount;
  final DateTime dateTime;

  WaterIntake({
    this.id,
    required this.amount,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'dateTime': Timestamp.fromDate(dateTime),
      };

  factory WaterIntake.fromMap(Map<String, dynamic> map, {String? id}) =>
      WaterIntake(
        id: id,
        amount: map['amount'] as int,
        dateTime: (map['dateTime'] is Timestamp)
            ? (map['dateTime'] as Timestamp).toDate()
            : DateTime.parse(map['dateTime'] as String),
      );
}
