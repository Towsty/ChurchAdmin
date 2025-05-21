import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/small_group.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Small Groups
  Future<List<SmallGroup>> getSmallGroups(String churchId) async {
    final snapshot =
        await _firestore
            .collection('churches')
            .doc(churchId)
            .collection('smallGroups')
            .get();

    return snapshot.docs
        .map((doc) => SmallGroup.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<SmallGroup?> getSmallGroup(String churchId, String groupId) async {
    final doc =
        await _firestore
            .collection('churches')
            .doc(churchId)
            .collection('smallGroups')
            .doc(groupId)
            .get();

    if (!doc.exists) return null;
    return SmallGroup.fromMap(doc.data()!, doc.id);
  }

  Future<void> createSmallGroup(String churchId, SmallGroup group) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('smallGroups')
        .add(group.toMap());
  }

  Future<void> updateSmallGroup(
    String churchId,
    String groupId,
    SmallGroup group,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('smallGroups')
        .doc(groupId)
        .update(group.toMap());
  }

  Future<void> deleteSmallGroup(String churchId, String groupId) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('smallGroups')
        .doc(groupId)
        .delete();
  }

  // Communication Groups
  Future<List<Map<String, dynamic>>> getCommunicationGroups(
    String churchId,
  ) async {
    final snapshot =
        await _firestore
            .collection('churches')
            .doc(churchId)
            .collection('communicationGroups')
            .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> createCommunicationGroup(
    String churchId,
    Map<String, dynamic> groupData,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('communicationGroups')
        .add({
          ...groupData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateCommunicationGroup(
    String churchId,
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('communicationGroups')
        .doc(groupId)
        .update({...groupData, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteCommunicationGroup(String churchId, String groupId) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('communicationGroups')
        .doc(groupId)
        .delete();
  }

  // Group Membership
  Future<void> addUserToGroup(
    String userId,
    String groupId,
    String groupType,
    String churchId,
  ) async {
    final batch = _firestore.batch();

    // Add to user's groups
    batch.update(_firestore.collection('users').doc(userId), {
      '${groupType}Groups': FieldValue.arrayUnion([groupId]),
    });

    // Add to group's members
    batch.update(
      _firestore
          .collection('churches')
          .doc(churchId)
          .collection(groupType)
          .doc(groupId),
      {
        'members': FieldValue.arrayUnion([userId]),
      },
    );

    await batch.commit();
  }

  Future<void> removeUserFromGroup(
    String userId,
    String groupId,
    String groupType,
    String churchId,
  ) async {
    final batch = _firestore.batch();

    // Remove from user's groups
    batch.update(_firestore.collection('users').doc(userId), {
      '${groupType}Groups': FieldValue.arrayRemove([groupId]),
    });

    // Remove from group's members
    batch.update(
      _firestore
          .collection('churches')
          .doc(churchId)
          .collection(groupType)
          .doc(groupId),
      {
        'members': FieldValue.arrayRemove([userId]),
      },
    );

    await batch.commit();
  }
}
