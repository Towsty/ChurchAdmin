import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/role_permissions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageMembersScreen extends StatefulWidget {
  final String churchId;

  const ManageMembersScreen({super.key, required this.churchId});

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Not signed in');

      // Get the current user's document to verify admin status
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      if (!userDoc.exists) throw Exception('User document not found');

      final userData = userDoc.data()!;
      if (userData['role']?.toString().toLowerCase() != 'admin' ||
          userData['churchId'] != widget.churchId) {
        throw Exception('Not an admin of this church');
      }

      // Query all users that belong to this church
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('churchId', isEqualTo: widget.churchId)
              .get();

      if (!mounted) return;

      setState(() {
        _members = snapshot.docs;
        _isLoading = false;
      });
    } catch (e, stack) {
      print('Error loading members: $e');
      print('Stack trace: $stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _getFilteredMembers() {
    if (_searchQuery.isEmpty) return _members;
    final query = _searchQuery.toLowerCase();
    return _members.where((doc) {
      final data = doc.data();
      final firstName = (data['firstName'] ?? '').toString().toLowerCase();
      final lastName = (data['lastName'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      return firstName.contains(query) ||
          lastName.contains(query) ||
          email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMembers),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('churchId', isEqualTo: widget.churchId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('DEBUG: Error in member query:');
            print('Error: ${snapshot.error}');
            print('Stack: ${snapshot.stackTrace}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading members: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data!.docs;

          if (members.isEmpty) {
            return const Center(
              child: Text(
                'No members found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final filteredMembers =
              _searchQuery.isEmpty
                  ? members
                  : members.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final firstName =
                        (data['firstName'] ?? '').toString().toLowerCase();
                    final lastName =
                        (data['lastName'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return firstName.contains(query) ||
                        lastName.contains(query) ||
                        email.contains(query);
                  }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Members',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                            : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredMembers.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final doc = filteredMembers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final firstName = data['firstName'] ?? '';
                    final lastName = data['lastName'] ?? '';
                    final fullName = '$firstName $lastName'.trim();
                    final displayName =
                        fullName.isNotEmpty ? fullName : 'Unknown';
                    final email = data['email'] ?? '';
                    final role =
                        (data['role'] ?? 'member').toString().toLowerCase();

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(displayName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            Text(
                              'Role: ${role[0].toUpperCase()}${role.substring(1)}',
                              style: TextStyle(
                                color:
                                    role == 'admin'
                                        ? Colors.red
                                        : role == 'leader'
                                        ? Colors.blue
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'remove') {
                              // Show confirmation dialog
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Remove Member'),
                                      content: Text(
                                        'Are you sure you want to remove $displayName from the church?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(doc.id)
                                      .update({
                                        'churchId': null,
                                        'role': 'member',
                                      });

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Successfully removed $displayName',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            } else if (value.startsWith('role_')) {
                              final newRole = value.substring(5);
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(doc.id)
                                    .update({'role': newRole});

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Updated ${displayName}\'s role to ${newRole[0].toUpperCase()}${newRole.substring(1)}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'role_admin',
                                  child: Text('Make Admin'),
                                ),
                                const PopupMenuItem(
                                  value: 'role_leader',
                                  child: Text('Make Leader'),
                                ),
                                const PopupMenuItem(
                                  value: 'role_member',
                                  child: Text('Make Member'),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text(
                                    'Remove from Church',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
