import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MeetingTypeService {
  Future<String?> _getChurchId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('🚫 No user logged in');
        return null;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final churchId = doc.data()?['churchId'];
      debugPrint('🏢 Got churchId: $churchId');
      return churchId;
    } catch (e) {
      debugPrint('❌ Error getting churchId: $e');
      rethrow;
    }
  }

  /// Returns a list of meeting types with their IDs from the church document
  Future<List<Map<String, dynamic>>> getMeetingTypes() async {
    try {
      final churchId = await _getChurchId();
      if (churchId == null) {
        debugPrint('🚫 No churchId available');
        return [];
      }

      final churchDoc =
          await FirebaseFirestore.instance
              .collection('churches')
              .doc(churchId)
              .get();

      final types =
          (churchDoc.data()?['defaultMeetingTypes'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      debugPrint('📝 Got ${types.length} meeting types');
      return types
          .asMap()
          .entries
          .map((entry) => {'id': entry.key.toString(), 'name': entry.value})
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting meeting types: $e');
      rethrow;
    }
  }

  /// Adds a new meeting type to the church document
  Future<void> addMeetingType(String type) async {
    try {
      final churchId = await _getChurchId();
      if (churchId == null) {
        debugPrint('🚫 Cannot add meeting type: no church selected');
        throw Exception('No church selected');
      }

      final churchRef = FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId);

      debugPrint('➕ Adding new meeting type: $type');
      await churchRef.update({
        'defaultMeetingTypes': FieldValue.arrayUnion([type]),
      });
      debugPrint('✅ Successfully added meeting type');
    } catch (e) {
      debugPrint('❌ Error adding meeting type: $e');
      rethrow;
    }
  }

  /// Removes a meeting type from the church document
  Future<void> deleteMeetingType(String typeId) async {
    try {
      final churchId = await _getChurchId();
      if (churchId == null) {
        debugPrint('🚫 Cannot delete meeting type: no church selected');
        throw Exception('No church selected');
      }

      // Get current types
      final churchRef = FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId);
      final churchDoc = await churchRef.get();
      final types =
          (churchDoc.data()?['defaultMeetingTypes'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      // Remove the type at the specified index
      final index = int.tryParse(typeId);
      if (index != null && index >= 0 && index < types.length) {
        final typeToRemove = types[index];
        debugPrint('🗑️ Removing meeting type: $typeToRemove');
        await churchRef.update({
          'defaultMeetingTypes': FieldValue.arrayRemove([typeToRemove]),
        });
        debugPrint('✅ Successfully removed meeting type');
      }
    } catch (e) {
      debugPrint('❌ Error deleting meeting type: $e');
      rethrow;
    }
  }

  /// Stream of meeting types from the church document
  Stream<List<Map<String, dynamic>>> getMeetingTypesStream() {
    debugPrint('🔄 Initializing meeting types stream');
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        debugPrint('🚫 No user in stream');
        yield [];
        return;
      }

      try {
        debugPrint('👤 User authenticated: ${user.uid}');
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        final churchId = doc.data()?['churchId'];
        if (churchId == null) {
          debugPrint('🚫 No churchId in stream');
          yield [];
          return;
        }

        debugPrint('🔄 Starting meeting types stream for church: $churchId');
        yield* FirebaseFirestore.instance
            .collection('churches')
            .doc(churchId)
            .snapshots()
            .map((snapshot) {
              final types =
                  (snapshot.data()?['defaultMeetingTypes'] as List<dynamic>?)
                      ?.cast<String>() ??
                  [];
              debugPrint('📝 Stream update: ${types.length} meeting types');
              return types
                  .asMap()
                  .entries
                  .map(
                    (entry) => {
                      'id': entry.key.toString(),
                      'name': entry.value,
                    },
                  )
                  .toList();
            });
      } catch (e) {
        debugPrint('❌ Error in meeting types stream: $e');
        yield [];
      }
    });
  }
}
