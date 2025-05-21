import 'package:cloud_firestore/cloud_firestore.dart';

class SmallGroupPost {
  final String id;
  final String groupId;
  final String authorId;
  final String message;
  final DateTime createdAt;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;

  SmallGroupPost({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.message,
    required this.createdAt,
    this.attachments = const [],
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'authorId': authorId,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  factory SmallGroupPost.fromMap(Map<String, dynamic> map, String id) {
    return SmallGroupPost(
      id: id,
      groupId: map['groupId'] ?? '',
      authorId: map['authorId'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      attachments: (map['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: map['metadata'],
    );
  }
}
