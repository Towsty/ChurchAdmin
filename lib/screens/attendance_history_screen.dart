import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      userRole = userDoc.data()?['role'] ?? 'Visitor';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userRole != 'admin' && userRole != 'leader') {
      return const Scaffold(body: Center(child: Text('Access denied: insufficient permissions.')));
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final attendanceRef = FirebaseFirestore.instance
        .collectionGroup('attendance')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: attendanceRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final records = snapshot.data!.docs;
          if (records.isEmpty) return const Center(child: Text('No attendance records found.'));

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final data = records[index].data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              return ListTile(
                title: Text(data['meetingType'] ?? 'Unknown'),
                subtitle: Text(DateFormat.yMMMd().format(date)),
                trailing: Text(data['status'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
