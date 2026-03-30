import 'package:cloud_firestore/cloud_firestore.dart';

class SleepRecord {
  final String? id;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int qualityRating;
  final String? notes;

  SleepRecord({
    this.id,
    required this.bedTime,
    required this.wakeTime,
    required this.qualityRating,
    this.notes,
  });

  Duration get duration => wakeTime.difference(bedTime);

  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String get qualityText {
    switch (qualityRating) {
      case 1: return 'Rất tệ';
      case 2: return 'Tệ';
      case 3: return 'Bình thường';
      case 4: return 'Tốt';
      case 5: return 'Rất tốt';
      default: return 'Không rõ';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'bedTime': Timestamp.fromDate(bedTime),
      'wakeTime': Timestamp.fromDate(wakeTime),
      'qualityRating': qualityRating,
      'notes': notes,
    };
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return SleepRecord(
      id: id,
      bedTime: (map['bedTime'] is Timestamp)
          ? (map['bedTime'] as Timestamp).toDate()
          : DateTime.parse(map['bedTime'] as String),
      wakeTime: (map['wakeTime'] is Timestamp)
          ? (map['wakeTime'] as Timestamp).toDate()
          : DateTime.parse(map['wakeTime'] as String),
      qualityRating: map['qualityRating'] as int,
      notes: map['notes'] as String?,
    );
  }
}
