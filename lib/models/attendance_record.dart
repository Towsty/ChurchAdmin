import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String? id;
  final DateTime date;
  final String meetingType;
  final int adults;
  final int youth;
  final int leaders;
  final String? notes;
  final String? enteredBy;
  final DateTime? enteredAt;
  final String? lastModifiedBy;
  final DateTime? lastModifiedAt;

  AttendanceRecord({
    this.id,
    required this.date,
    required this.meetingType,
    required this.adults,
    required this.youth,
    required this.leaders,
    this.notes,
    this.enteredBy,
    this.enteredAt,
    this.lastModifiedBy,
    this.lastModifiedAt,
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
      'enteredBy': enteredBy,
      'enteredAt':
          enteredAt != null
              ? Timestamp.fromDate(enteredAt!)
              : FieldValue.serverTimestamp(),
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedAt':
          lastModifiedAt != null
              ? Timestamp.fromDate(lastModifiedAt!)
              : FieldValue.serverTimestamp(),
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
    return AttendanceRecord(
      id: docId,
      date: (map['date'] as Timestamp).toDate(),
      meetingType: map['meetingType'],
      adults: map['adults'],
      youth: map['youth'],
      leaders: map['leaders'],
      notes: map['notes'],
      enteredBy: map['enteredBy'],
      enteredAt:
          map['enteredAt'] != null
              ? (map['enteredAt'] as Timestamp).toDate()
              : null,
      lastModifiedBy: map['lastModifiedBy'],
      lastModifiedAt:
          map['lastModifiedAt'] != null
              ? (map['lastModifiedAt'] as Timestamp).toDate()
              : null,
    );
  }

  int get total => adults + youth + leaders;

  AttendanceRecord copyWith({
    String? id,
    DateTime? date,
    String? meetingType,
    int? adults,
    int? youth,
    int? leaders,
    String? notes,
    String? enteredBy,
    DateTime? enteredAt,
    String? lastModifiedBy,
    DateTime? lastModifiedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      meetingType: meetingType ?? this.meetingType,
      adults: adults ?? this.adults,
      youth: youth ?? this.youth,
      leaders: leaders ?? this.leaders,
      notes: notes ?? this.notes,
      enteredBy: enteredBy ?? this.enteredBy,
      enteredAt: enteredAt ?? this.enteredAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }
}
