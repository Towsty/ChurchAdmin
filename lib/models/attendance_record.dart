import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String? id;
  final DateTime date;
  final String meetingType;
  final int adults;
  final int youth;
  final int leaders;
  final String? notes;

  AttendanceRecord({
    this.id,
    required this.date,
    required this.meetingType,
    required this.adults,
    required this.youth,
    required this.leaders,
    this.notes,
  });

  Map<String, dynamic> toLocalJson() {
    return {
      'date': date.toIso8601String(),
      'meetingType': meetingType,
      'adults': adults,
      'youth': youth,
      'leaders': leaders,
      'notes': notes,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'date': Timestamp.fromDate(date),
      'meetingType': meetingType,
      'adults': adults,
      'youth': youth,
      'leaders': leaders,
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.parse(json['date']),
      meetingType: json['meetingType'],
      adults: json['adults'],
      youth: json['youth'],
      leaders: json['leaders'],
      notes: json['notes'],
    );
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String docId) {
    final dateField = map['date'];
    final date = dateField is Timestamp
        ? dateField.toDate()
        : DateTime.tryParse(dateField.toString()) ?? DateTime(2000);

    return AttendanceRecord(
      id: docId,
      date: date,
      meetingType: map['meetingType'] ?? '',
      adults: map['adults'] ?? 0,
      youth: map['youth'] ?? 0,
      leaders: map['leaders'] ?? 0,
      notes: map['notes'],
    );
  }
}
