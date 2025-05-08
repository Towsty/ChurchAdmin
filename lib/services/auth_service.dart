import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  /// Sign up a new user
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      final newUser = AppUser(
        uid: user.uid,
        email: email,
        name: name,
        churchId: '',
        role: UserRole.Member,
        pending: true,
        createdAt: DateTime.now(),
      );
      await _userService.saveUser(newUser);
    }

    return credential;
  }

  /// Sign in an existing user
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get the current user's profile
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _userService.getUser(user.uid);
  }

  /// Stream of Auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
