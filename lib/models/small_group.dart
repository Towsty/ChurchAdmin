import 'package:cloud_firestore/cloud_firestore.dart';

class SmallGroup {
  final String id;
  final String name;
  final String description;
  final String churchId;
  final String leaderId;
  final List<String> members;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? meetingTime;
  final String? meetingLocation;
  final bool isActive;

  SmallGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.churchId,
    required this.leaderId,
    required this.members,
    required this.createdAt,
    this.updatedAt,
    this.meetingTime,
    this.meetingLocation,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'churchId': churchId,
      'leaderId': leaderId,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'meetingTime': meetingTime,
      'meetingLocation': meetingLocation,
      'isActive': isActive,
    };
  }

  factory SmallGroup.fromMap(Map<String, dynamic> map, String id) {
    return SmallGroup(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      churchId: map['churchId'] ?? '',
      leaderId: map['leaderId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt:
          map['updatedAt'] != null
              ? (map['updatedAt'] as Timestamp).toDate()
              : null,
      meetingTime: map['meetingTime'],
      meetingLocation: map['meetingLocation'],
      isActive: map['isActive'] ?? true,
    );
  }

  SmallGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? churchId,
    String? leaderId,
    List<String>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? meetingTime,
    String? meetingLocation,
    bool? isActive,
  }) {
    return SmallGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      churchId: churchId ?? this.churchId,
      leaderId: leaderId ?? this.leaderId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      meetingTime: meetingTime ?? this.meetingTime,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      isActive: isActive ?? this.isActive,
    );
  }
}
