import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/small_group_post.dart';

class SmallGroupPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get posts for a specific group
  Stream<List<SmallGroupPost>> getGroupPosts(String churchId, String groupId) {
    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('smallGroups')
        .doc(groupId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => SmallGroupPost.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Get posts for all groups a user is a member of
  Stream<List<SmallGroupPost>> getUserGroupPosts(
    String churchId,
    List<String> groupIds,
  ) {
    if (groupIds.isEmpty) return Stream.value([]);

    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('smallGroups')
        .where(FieldPath.documentId, whereIn: groupIds)
        .snapshots()
        .asyncMap((groupsSnapshot) async {
          final allPosts = <SmallGroupPost>[];

          for (var groupDoc in groupsSnapshot.docs) {
            final postsSnapshot =
                await groupDoc.reference
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .limit(5) // Limit to most recent 5 posts per group
                    .get();

            allPosts.addAll(
              postsSnapshot.docs.map(
                (doc) => SmallGroupPost.fromMap(doc.data(), doc.id),
              ),
            );
          }

          // Sort all posts by creation date
          allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return allPosts;
        });
  }

  // Create a new post
  Future<void> createPost(String churchId, SmallGroupPost post) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('smallGroups')
        .doc(post.groupId)
        .collection('posts')
        .add(post.toMap());
  }

  // Update a post
  Future<void> updatePost(String churchId, SmallGroupPost post) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('smallGroups')
        .doc(post.groupId)
        .collection('posts')
        .doc(post.id)
        .update(post.toMap());
  }

  // Delete a post
  Future<void> deletePost(
    String churchId,
    String groupId,
    String postId,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('smallGroups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .delete();
  }
}
