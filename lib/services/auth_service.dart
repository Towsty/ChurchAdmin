import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  bool _isSigningOut = false;
  bool _isSigningIn = false;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register with email & password
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create the user document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'role': 'member',
          'pending': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName('$firstName $lastName');
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email & password
  Future<UserCredential> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    if (_isSigningIn) return Future.error('Sign in already in progress');
    _isSigningIn = true;

    try {
      // Clear existing Firestore state
      await FirebaseFirestore.instance.terminate();

      // Reset Firestore settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );

      // Attempt sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Wait for initial data load
      await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user?.uid)
            .get(),
        Future.delayed(
          const Duration(milliseconds: 500),
        ), // Minimum loading time
      ]);

      return credential;
    } catch (e) {
      print('🔥 Error during sign in: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing in: $e')));
      }
      rethrow;
    } finally {
      _isSigningIn = false;
    }
  }

  /// Sign out
  Future<void> signOut(BuildContext context) async {
    if (_isSigningOut) return; // Prevent multiple sign-out attempts
    _isSigningOut = true;

    try {
      // Clear Firestore cache
      await FirebaseFirestore.instance.terminate();

      // Reset Firestore settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );

      // Sign out the user
      await _auth.signOut();

      if (context.mounted) {
        // Pop all routes and push the login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('🔥 Error during sign out: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    } finally {
      _isSigningOut = false;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (email != null) updates['email'] = email;

      await userRef.update(updates);

      // Update display name in Firebase Auth if name changed
      if (firstName != null || lastName != null) {
        final currentData =
            (await userRef.get()).data() as Map<String, dynamic>;
        final newFirstName = firstName ?? currentData['firstName'] as String;
        final newLastName = lastName ?? currentData['lastName'] as String;
        await _auth.currentUser?.updateDisplayName(
          '$newFirstName $newLastName',
        );
      }

      // Update email in Firebase Auth if changed
      if (email != null) {
        await _auth.currentUser?.updateEmail(email);
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get the current user's profile
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _userService.getUser(user.uid);
  }

  /// Check if currently signing out
  bool get isSigningOut => _isSigningOut;

  /// Check if currently signing in
  bool get isSigningIn => _isSigningIn;

  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'requires-recent-login':
          return 'This operation is sensitive and requires recent authentication. Please log in again.';
        default:
          return 'An error occurred: ${e.message}';
      }
    }
    return 'An unexpected error occurred.';
  }
}
