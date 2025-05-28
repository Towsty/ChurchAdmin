import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<DocumentSnapshot> _churches = [];
  List<DocumentSnapshot> _allUsers = [];
  bool _isLoading = true;
  Map<String, String> _selectedRoles = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load all churches
      final churchesSnapshot =
          await FirebaseFirestore.instance.collection('churches').get();

      // Load all users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      setState(() {
        _churches = churchesSnapshot.docs;
        _allUsers = usersSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewChurch() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Church'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Church Name'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Church name is required')),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('churches')
                        .add({
                          'name': nameController.text,
                          'address': addressController.text,
                          'phone': phoneController.text,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                    Navigator.pop(context);
                    _loadData(); // Refresh the list
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating church: $e')),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  Future<void> _assignAdmin(String churchId, String churchName) async {
    final filteredUsers =
        _searchQuery.isEmpty
            ? _allUsers
            : _allUsers.where((user) {
              final userData = user.data() as Map<String, dynamic>;
              final name = userData['name']?.toString().toLowerCase() ?? '';
              final email = userData['email']?.toString().toLowerCase() ?? '';
              final searchLower = _searchQuery.toLowerCase();
              return name.contains(searchLower) || email.contains(searchLower);
            }).toList();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Add User to $churchName'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search Users',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final userData =
                                  filteredUsers[index].data()
                                      as Map<String, dynamic>;
                              final userId = filteredUsers[index].id;

                              // Initialize role if not set
                              _selectedRoles.putIfAbsent(
                                userId,
                                () => 'member',
                              );

                              final firstName = userData['firstName'] ?? '';
                              final lastName = userData['lastName'] ?? '';
                              final fullName = '$firstName $lastName'.trim();

                              return ListTile(
                                title: Text(
                                  fullName.isNotEmpty ? fullName : 'No Name',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userData['email'] ?? 'No Email'),
                                    const SizedBox(height: 4),
                                    DropdownButton<String>(
                                      value: _selectedRoles[userId],
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'admin',
                                          child: Text('Admin - Full access'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'leader',
                                          child: Text(
                                            'Leader - Can track attendance',
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'member',
                                          child: Text('Member - View only'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                            () =>
                                                _selectedRoles[userId] = value,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  child: const Text('Add'),
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userId)
                                          .update({
                                            'role': _selectedRoles[userId],
                                            'churchId': churchId,
                                          });

                                      Navigator.pop(context);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'User added as ${_selectedRoles[userId]} successfully',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error assigning user: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin - Church Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Churches',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _churches.length,
              itemBuilder: (context, index) {
                final church = _churches[index].data() as Map<String, dynamic>;
                final churchName = church['name'] as String;

                if (_searchController.text.isNotEmpty &&
                    !churchName.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    )) {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(churchName),
                    subtitle: Text(church['address'] ?? 'No address'),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed:
                          () => _assignAdmin(_churches[index].id, churchName),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChurch,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
