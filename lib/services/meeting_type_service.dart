import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingTypeService {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('meeting_types');

  /// ✅ Returns a list of meeting type strings from Firestore
  Future<List<String>> getMeetingTypes() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => doc['name'].toString()).toList();
  }

  /// ✅ Adds a new meeting type to Firestore
  Future<void> addMeetingType(String type) async {
    await _collection.add({'name': type});
  }

  /// ✅ Deletes a meeting type by its document ID
  Future<void> deleteMeetingType(String docId) async {
    await _collection.doc(docId).delete();
  }

  /// ✅ Gets all documents with their IDs and names
  Future<List<Map<String, String>>> getMeetingTypesWithIds() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name'].toString()})
        .toList();
  }

  /// Stream of meeting type names (strings)
  Stream<List<String>> getMeetingTypesStream() {
    return _collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc['name'].toString()).toList());
  }
}
