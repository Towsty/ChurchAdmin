import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/role_permissions.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? userRole;
  String? churchId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      userRole = userDoc.data()?['role'] ?? 'Visitor';
      churchId = userDoc.data()?['churchId'];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null || churchId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userRole != 'admin' && userRole != 'leader') {
      return const Scaffold(
        body: Center(child: Text('Access denied: insufficient permissions.')),
      );
    }

    final attendanceRef = FirebaseFirestore.instance
        .collection('churches')
        .doc(churchId)
        .collection('attendance')
        .orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: attendanceRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final records = snapshot.data!.docs;
          if (records.isEmpty)
            return const Center(child: Text('No attendance records found.'));

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final data = records[index].data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final total =
                  (data['adults'] ?? 0) +
                  (data['youth'] ?? 0) +
                  (data['leaders'] ?? 0);

              return ListTile(
                title: Text(data['meetingType'] ?? 'Unknown'),
                subtitle: Text(DateFormat.yMMMd().format(date)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data['notes']?.isNotEmpty == true) ...[
                      const Icon(Icons.description, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text('Total: $total'),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            '${data['meetingType']} - ${DateFormat.yMMMd().format(date)}',
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Adults: ${data['adults'] ?? 0}'),
                              Text('Youth: ${data['youth'] ?? 0}'),
                              Text('Leaders: ${data['leaders'] ?? 0}'),
                              Text('Total: $total'),
                              if (data['notes'] != null) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Notes:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(data['notes']),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
