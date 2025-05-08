import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  Future<String?> _getChurchId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['churchId'];
  }

  Future<CollectionReference<Map<String, dynamic>>?> _getAttendanceCollection() async {
    final churchId = await _getChurchId();
    if (churchId == null) return null;
    return FirebaseFirestore.instance.collection('churches').doc(churchId).collection('attendance');
  }

  Future<void> saveRecord(AttendanceRecord record) async {
    final collection = await _getAttendanceCollection();
    if (collection == null) return;

    await collection.add(record.toFirestoreMap());
  }

  Future<List<AttendanceRecord>> getAllRecords() async {
    final collection = await _getAttendanceCollection();
    if (collection == null) return [];

    final snapshot = await collection.get();
    return snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<AttendanceRecord>> getRecordsStream() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield [];
        return; // ✅ explicitly return to exit early
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final churchId = doc.data()?['churchId'];
      if (churchId == null) {
        yield [];
        return; // ✅ another safe early return
      }

      yield* FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('attendance')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList());
    });
  }

  Future<void> deleteRecord(String id) async {
    final collection = await _getAttendanceCollection();
    if (collection == null) return;

    await collection.doc(id).delete();
  }

  Future<void> clearAllRecords() async {
    final collection = await _getAttendanceCollection();
    if (collection == null) return;

    final snapshot = await collection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> updateRecord(AttendanceRecord record) async {
    if (record.id == null) return;

    final collection = await _getAttendanceCollection();
    if (collection == null) return;

    await collection.doc(record.id).update(record.toFirestoreMap());
  }
}
