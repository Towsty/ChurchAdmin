import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record.dart';


class AttendanceService {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('attendance');

  Future<void> saveRecord(AttendanceRecord record) async {
    await _collection.add(record.toFirestoreMap());
  }

  Future<List<AttendanceRecord>> getAllRecords() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) =>
        AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Stream<List<AttendanceRecord>> getRecordsStream() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return AttendanceRecord.fromMap(data, doc.id);
    }).toList());
  }

  Future<void> deleteRecord(String id) async {
    await _collection.doc(id).delete();
  }

  Future<void> clearAllRecords() async {
    final snapshot = await _collection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> updateRecord(AttendanceRecord record) async {
    if (record.id == null) return;
    await _collection.doc(record.id).update(record.toFirestoreMap());
  }

}
