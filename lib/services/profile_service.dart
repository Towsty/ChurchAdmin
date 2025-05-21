import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadProfilePhoto(File photoFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    try {
      // Create a reference to the profile photo location
      final photoRef = _storage.ref().child('profile_photos/${user.uid}');

      // Upload the file
      final uploadTask = await photoRef.putFile(photoFile);

      // Get the download URL
      final photoUrl = await uploadTask.ref.getDownloadURL();

      // Update user profile in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return photoUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'storage/object-not-found') {
        // If the object doesn't exist, try creating the directory first
        final photoRef = _storage.ref().child('profile_photos/${user.uid}');
        await photoRef.putFile(photoFile);
        final photoUrl = await photoRef.getDownloadURL();

        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return photoUrl;
      }
      throw Exception('Failed to upload photo: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      ...profileData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> deleteProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    try {
      final photoRef = _storage.ref().child('profile_photos/${user.uid}');
      await photoRef.delete();

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'storage/object-not-found') {
        // If the photo doesn't exist, just update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      throw Exception('Failed to delete photo: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }
}
