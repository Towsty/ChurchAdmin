import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinRequestApprovalScreen extends StatefulWidget {
  const JoinRequestApprovalScreen({super.key});

  @override
  State<JoinRequestApprovalScreen> createState() => _JoinRequestApprovalScreenState();
}

class _JoinRequestApprovalScreenState extends State<JoinRequestApprovalScreen> {
  String? _churchId;
  final Map<String, String> _selectedRoles = {};

  @override
  void initState() {
    super.initState();
    _loadChurchId();
  }

  Future<void> _loadChurchId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data != null && data['churchId'] != null) {
      setState(() => _churchId = data['churchId']);
    }
  }

  Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> _approveRequest(String userId, String role) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'churchId': _churchId,
        'role': role.toLowerCase(),
        'joinRequest': FieldValue.delete(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('churches')
          .doc(_churchId!)
          .collection('joinRequests')
          .doc(userId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Approved $userId as $role')),
        );
      }
    } catch (e) {
      print('❌ Error approving request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error approving: $e')),
      );
    }
  }


  Future<void> _rejectRequest(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'joinRequest': FieldValue.delete(),
      });

      await FirebaseFirestore.instance
          .collection('churches')
          .doc(_churchId!)
          .collection('joinRequests')
          .doc(userId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Rejected request from $userId')),
        );
      }
    } catch (e) {
      print('❌ Error rejecting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error rejecting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_churchId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final joinRequestsRef = FirebaseFirestore.instance
        .collection('churches')
        .doc(_churchId!)
        .collection('joinRequests');

    return Scaffold(
      appBar: AppBar(title: const Text('Approve Join Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: joinRequestsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text('No join requests at this time.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final userId = request.id;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserDetails(userId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading user...'));
                  }

                  final userData = userSnapshot.data!;
                  final userName = userData['name'] ?? 'Unknown';
                  final userEmail = userData['email'] ?? '';
                  final selectedRole = _selectedRoles[userId] ?? 'member';

                  return ListTile(
                    title: Text(userName),
                    subtitle: Text(userEmail),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: selectedRole,
                          items: const [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin - Full access'),
                            ),
                            DropdownMenuItem(
                              value: 'leader',
                              child: Text('Leader - Can track attendance'),
                            ),
                            DropdownMenuItem(
                              value: 'member',
                              child: Text('Member - View only'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRoles[userId] = val);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            print('✅ Approve tapped for $userId');
                            final role = _selectedRoles[userId] ?? 'member';
                            _approveRequest(userId, role);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            print('❌ Reject tapped for $userId');
                            _rejectRequest(userId);
                          },
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
