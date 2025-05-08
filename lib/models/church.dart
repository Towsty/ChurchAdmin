import 'package:cloud_firestore/cloud_firestore.dart';

class Church {
  final String id;
  final String name;
  final String zipCode;
  final String createdBy;
  final DateTime createdAt;

  Church({
    required this.id,
    required this.name,
    required this.zipCode,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'zipCode': zipCode,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Church.fromMap(Map<String, dynamic> map, String id) {
    return Church(
      id: id,
      name: map['name'] ?? '',
      zipCode: map['zipCode'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
