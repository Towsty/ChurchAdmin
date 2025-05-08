import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('users');

  /// Save a new user document
  Future<void> saveUser(AppUser user) async {
    print('📝 Saving user to Firestore: ${user.uid}');
    await _collection.doc(user.uid).set(user.toMap());
  }

  /// Fetch user by UID
  Future<AppUser?> getUser(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (doc.exists) {
      print('✅ User found: ${doc.data()}');
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id); // ✅ pass uid
    }
    print('❌ No user document found for UID: $uid');
    return null;
  }

  /// Update user (e.g. role or pending status)
  Future<void> updateUser(AppUser user) async {
    await _collection.doc(user.uid).update(user.toMap());
  }

  /// Request to join a specific church
  Future<void> requestToJoinChurch(String uid, String churchId) async {
    await _collection.doc(uid).update({
      'joinRequest': {
        'churchId': churchId,
        'timestamp': Timestamp.now(),
      }
    });
  }

  /// Search for churches a user can request (returns user’s current church if not pending)
  Future<List<AppUser>> getUsersByChurch(String churchId) async {
    final snapshot =
    await _collection.where('churchId', isEqualTo: churchId).get();
    return snapshot.docs
        .map((doc) =>
        AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id)) // ✅ pass uid
        .toList();
  }

  /// (Optional) get all pending users for approval workflows
  Future<List<AppUser>> getPendingUsers(String churchId) async {
    final snapshot = await _collection
        .where('churchId', isEqualTo: churchId)
        .where('pending', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) =>
        AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id)) // ✅ pass uid
        .toList();
  }
}
