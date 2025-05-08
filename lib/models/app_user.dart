import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { Admin, Leader, Member }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String churchId;
  final UserRole role;
  final bool pending;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.churchId,
    required this.role,
    required this.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'churchId': churchId,
      'role': role.name,
      'pending': pending,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    print('🔍 Building AppUser from map: $map with UID: $uid');

    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      churchId: map['churchId'] ?? '',
      role: UserRole.values.firstWhere(
            (r) => r.name.toLowerCase() == (map['role'] ?? 'member').toString().toLowerCase(),
        orElse: () => UserRole.Member,
      ),
      pending: map['pending'] ?? false,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
