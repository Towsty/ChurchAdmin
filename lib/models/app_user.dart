import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { Admin, Leader, Member }

class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String churchId;
  final UserRole role;
  final bool pending;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.churchId,
    required this.role,
    required this.pending,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'churchId': churchId,
      'role': role.name.toLowerCase(),
      'pending': pending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    print('🔍 Building AppUser from map: $map with UID: $uid');

    // Handle legacy data that might only have 'name'
    String firstName = map['firstName'] ?? '';
    String lastName = map['lastName'] ?? '';
    if (firstName.isEmpty && lastName.isEmpty && map['name'] != null) {
      final nameParts = (map['name'] as String).split(' ');
      firstName = nameParts.first;
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    return AppUser(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      email: map['email'] ?? '',
      churchId: map['churchId'] ?? '',
      role: UserRole.values.firstWhere(
        (r) =>
            r.name.toLowerCase() ==
            (map['role'] ?? 'member').toString().toLowerCase(),
        orElse: () => UserRole.Member,
      ),
      pending: map['pending'] ?? false,
      createdAt:
          (map['createdAt'] is Timestamp)
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
