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

      // Query the members subcollection directly
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('churches')
              .doc(widget.churchId)
              .collection('members')
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
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      return name.contains(query) || email.contains(query);
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
                .collection('churches')
                .doc(widget.churchId)
                .collection('members')
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
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return name.contains(query) || email.contains(query);
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
                    final name = data['name'] ?? 'Unknown';
                    final email = data['email'] ?? '';
                    final role =
                        (data['role'] ?? 'member').toString().toLowerCase();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            name.toString().characters.take(2).toString(),
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                role,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'remove') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Remove Member'),
                                      content: Text(
                                        'Are you sure you want to remove $name?',
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

                              if (confirmed == true) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('churches')
                                      .doc(widget.churchId)
                                      .collection('members')
                                      .doc(doc.id)
                                      .delete();

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Removed $name from church',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error removing member: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('churches')
                                    .doc(widget.churchId)
                                    .collection('members')
                                    .doc(doc.id)
                                    .update({'role': value});

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Updated $name to $value'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating role: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'admin',
                                  child: Text('Make Admin'),
                                ),
                                const PopupMenuItem(
                                  value: 'leader',
                                  child: Text('Make Leader'),
                                ),
                                const PopupMenuItem(
                                  value: 'member',
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
