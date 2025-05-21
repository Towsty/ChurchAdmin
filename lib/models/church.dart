import 'package:cloud_firestore/cloud_firestore.dart';

class Church {
  final String id;
  final String name;
  final String zipCode;
  final String? location;
  final String? meetingTimes;
  final String? contactEmail;
  final String? phone;
  final String? website;
  final String? denomination;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> defaultMeetingTypes;

  Church({
    required this.id,
    required this.name,
    required this.zipCode,
    this.location,
    this.meetingTimes,
    this.contactEmail,
    this.phone,
    this.website,
    this.denomination,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.defaultMeetingTypes = const [
      'Sunday Service',
      'Bible Study',
      'Prayer Meeting',
    ],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'zipCode': zipCode,
      'location': location,
      'meetingTimes': meetingTimes,
      'contactEmail': contactEmail,
      'phone': phone,
      'website': website,
      'denomination': denomination,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'defaultMeetingTypes': defaultMeetingTypes,
    };
  }

  factory Church.fromMap(Map<String, dynamic> map, String id) {
    return Church(
      id: id,
      name: map['name'] ?? '',
      zipCode: map['zipCode'] ?? '',
      location: map['location'],
      meetingTimes: map['meetingTimes'],
      contactEmail: map['contactEmail'],
      phone: map['phone'],
      website: map['website'],
      denomination: map['denomination'],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt:
          map['updatedAt'] != null
              ? (map['updatedAt'] as Timestamp).toDate()
              : null,
      defaultMeetingTypes:
          (map['defaultMeetingTypes'] as List<dynamic>?)?.cast<String>() ??
          ['Sunday Service', 'Bible Study', 'Prayer Meeting'],
    );
  }
}
