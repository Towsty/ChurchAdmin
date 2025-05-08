import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinRequestService {
  Stream<int> joinRequestCountStream() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield 0;
        return;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(
          user.uid).get();
      final churchId = userDoc.data()?['churchId'];
      final role = userDoc.data()?['role'];

      if (churchId == null || role != 'admin') {
        yield 0;
        return;
      }

      yield* FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('joinRequests')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    });
  }
}