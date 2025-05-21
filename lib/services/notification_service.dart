import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all notifications for a user
  Stream<List<Notification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Notification.fromFirestore(doc))
              .toList();
        });
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print(
        'Successfully marked ${notifications.docs.length} notifications as read',
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw e;
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('Successfully deleted notification: $notificationId');
    } catch (e) {
      print('Error deleting notification: $e');
      throw e;
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final notifications =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .get();

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Successfully deleted ${notifications.docs.length} notifications');
    } catch (e) {
      print('Error deleting all notifications: $e');
      throw e;
    }
  }

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': data,
      });
      print('Notification created successfully');
    } catch (e) {
      print('Error creating notification: $e');
      throw e;
    }
  }

  // Check if user profile is complete and create notification if not
  Future<void> checkProfileCompletion(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    final requiredFields = ['phone', 'address'];
    final missingFields =
        requiredFields
            .where(
              (field) =>
                  userData[field] == null ||
                  userData[field].toString().trim().isEmpty,
            )
            .toList();

    if (missingFields.isNotEmpty) {
      await createNotification(
        userId: userId,
        title: 'Complete Your Profile',
        message:
            'Please complete your profile by adding: ${missingFields.join(", ")}',
        type: 'profile',
        data: {'missingFields': missingFields},
      );
    }
  }
}
