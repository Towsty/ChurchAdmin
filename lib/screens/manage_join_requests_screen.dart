import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageJoinRequestsScreen extends StatefulWidget {
  final String churchId;

  const ManageJoinRequestsScreen({super.key, required this.churchId});

  @override
  State<ManageJoinRequestsScreen> createState() =>
      _ManageJoinRequestsScreenState();
}

class _ManageJoinRequestsScreenState extends State<ManageJoinRequestsScreen> {
  bool _isProcessing = false;

  Future<void> _handleRequest(
    DocumentSnapshot request,
    String action,
    String role,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final userId = request.id;
      final userData = request.data() as Map<String, dynamic>;
      final churchRef = FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId);
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final membersRef = churchRef.collection('members').doc(userId);
      final joinRequestRef = churchRef.collection('joinRequests').doc(userId);

      // Get current user info for debugging
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      // Get current user's role from Firestore
      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final currentUserData = currentUserDoc.data();
      if (currentUserData == null) {
        throw Exception('Current user data not found');
      }

      print('DEBUG - Current User Details:');
      print('- Auth UID: ${currentUser.uid}');
      print('- Email: ${currentUser.email}');
      print('- Role: ${currentUserData['role']}');
      print('- Church ID: ${currentUserData['churchId']}');

      if (currentUserData['role'] != 'admin') {
        throw Exception('User is not an admin');
      }

      final firstName = userData['firstName'] ?? '';
      final lastName = userData['lastName'] ?? '';
      final displayName = '$firstName $lastName'.trim();
      final finalDisplayName =
          displayName.isNotEmpty
              ? displayName
              : userData['userEmail']?.split('@')[0] ?? 'Unknown User';

      if (action == 'approve') {
        try {
          // Step 1: Add to members collection
          print('DEBUG - Step 1: Adding to members collection');
          await membersRef.set({
            'firstName': firstName,
            'lastName': lastName,
            'email': userData['userEmail'],
            'role': role.toLowerCase(),
            'joinedAt': FieldValue.serverTimestamp(),
          });
          print('DEBUG - Successfully added to members collection');

          // Step 2: Update user document
          print('DEBUG - Step 2: Updating user document');
          try {
            await userRef.update({
              'churchId': widget.churchId,
              'role': role.toLowerCase(),
              'firstName': firstName,
              'lastName': lastName,
              'pendingChurchId': FieldValue.delete(),
              'pendingChurchName': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedBy': currentUser.uid,
            });
            print('DEBUG - Successfully updated user document');
          } catch (e) {
            print('ERROR - Failed to update user document: $e');
            throw Exception('Failed to update user document: $e');
          }

          // Step 3: Delete join request
          print('DEBUG - Step 3: Deleting join request');
          try {
            await joinRequestRef.delete();
            print('DEBUG - Successfully deleted join request');
          } catch (e) {
            print('ERROR - Failed to delete join request: $e');
            throw Exception('Failed to delete join request: $e');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully added $finalDisplayName as ${role.toLowerCase()}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('ERROR - Operation failed: $e');
          throw Exception('Failed to process request: $e');
        }
      } else {
        // Handle denial - just remove request
        try {
          print('DEBUG - Denying request');
          await joinRequestRef.delete();
          print('DEBUG - Successfully denied request');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Request from $finalDisplayName was denied'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          print('ERROR - Failed to deny request: $e');
          throw Exception('Failed to deny request: $e');
        }
      }
    } catch (e) {
      print('ERROR - Operation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('churches')
                .doc(widget.churchId)
                .collection('joinRequests')
                .orderBy('requestedAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading requests: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending join requests',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;
              final requestedAt = (data['requestedAt'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Email: ${data['userEmail'] ?? 'N/A'}'),
                      Text(
                        'Requested: ${requestedAt.toString().split('.')[0]}',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Approve as Member'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed:
                                _isProcessing
                                    ? null
                                    : () => _handleRequest(
                                      request,
                                      'approve',
                                      'member',
                                    ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.star),
                            label: const Text('Approve as Leader'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed:
                                _isProcessing
                                    ? null
                                    : () => _handleRequest(
                                      request,
                                      'approve',
                                      'leader',
                                    ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Deny'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed:
                                _isProcessing
                                    ? null
                                    : () => _handleRequest(request, 'deny', ''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
