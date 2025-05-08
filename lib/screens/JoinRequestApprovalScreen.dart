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
  bool _isLoading = true;
  List<DocumentSnapshot> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = userDoc.data();
    if (data == null || data['churchId'] == null) return;

    final churchId = data['churchId'];
    _churchId = churchId;

    final requestSnapshot = await FirebaseFirestore.instance
        .collection('churches')
        .doc(churchId)
        .collection('joinRequests')
        .get();

    setState(() {
      _requests = requestSnapshot.docs;
      _isLoading = false;
    });
  }

  Future<void> _approveRequest(String userId) async {
    if (_churchId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await userRef.update({
      'churchId': _churchId,
      'role': 'member',
      'joinRequest': FieldValue.delete(),
    });

    await FirebaseFirestore.instance
        .collection('churches')
        .doc(_churchId)
        .collection('joinRequests')
        .doc(userId)
        .delete();

    _loadRequests(); // refresh list
  }

  Future<void> _rejectRequest(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await userRef.update({
      'joinRequest': FieldValue.delete(),
    });

    await FirebaseFirestore.instance
        .collection('churches')
        .doc(_churchId)
        .collection('joinRequests')
        .doc(userId)
        .delete();

    _loadRequests(); // refresh list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? const Center(child: Text('No join requests.'))
          : ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final req = _requests[index];
          final userId = req.id;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(title: Text('Loading user...'));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;

              return ListTile(
                title: Text(userData?['email'] ?? userId),
                subtitle: Text('Requested at: ${req['requestedAt'].toDate()}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Approve',
                      onPressed: () => _approveRequest(userId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () => _rejectRequest(userId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
