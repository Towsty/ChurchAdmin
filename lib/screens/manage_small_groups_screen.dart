import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/group_service.dart';
import '../models/small_group.dart';
import '../services/role_permissions.dart';
import 'manage_group_members_screen.dart';

class ManageSmallGroupsScreen extends StatefulWidget {
  final String churchId;
  final SmallGroup? group; // Optional group for editing

  const ManageSmallGroupsScreen({
    super.key,
    required this.churchId,
    this.group,
  });

  @override
  State<ManageSmallGroupsScreen> createState() =>
      _ManageSmallGroupsScreenState();
}

class _ManageSmallGroupsScreenState extends State<ManageSmallGroupsScreen> {
  final _groupService = GroupService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingTimeController = TextEditingController();
  final _meetingLocationController = TextEditingController();
  bool _isLoading = false;
  String? _userRole;
  String? _userId;
  String? _selectedLeaderId;
  List<Map<String, dynamic>> _churchLeaders = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadChurchLeaders();

    // Initialize controllers if editing existing group
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description ?? '';
      _meetingTimeController.text = widget.group!.meetingTime ?? '';
      _meetingLocationController.text = widget.group!.meetingLocation ?? '';
      _selectedLeaderId = widget.group!.leaderId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _meetingTimeController.dispose();
    _meetingLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadChurchLeaders() async {
    try {
      print('🔍 Loading church leaders for churchId: ${widget.churchId}');

      // First get current user's church ID to verify
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final userData = userDoc.data();
      if (userData == null) {
        print('❌ No user data found');
        return;
      }

      print('👤 Current user church ID: ${userData['churchId']}');

      // Now query for leaders and admins
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('churchId', isEqualTo: widget.churchId)
              .where('role', whereIn: ['admin', 'leader'])
              .get();

      print('📊 Found ${snapshot.docs.length} leaders/admins');

      if (!mounted) return;
      setState(() {
        _churchLeaders =
            snapshot.docs.map((doc) {
              final data = doc.data();
              print('👥 Leader found: ${data['name']} (${data['role']})');
              return {
                'id': doc.id,
                'name': data['name'] ?? 'Unknown',
                'role': data['role'] ?? 'unknown',
              };
            }).toList();
      });
    } catch (e) {
      print('❌ Error loading church leaders: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading church leaders: $e')),
      );
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) return;
      setState(() {
        _userRole = doc.data()?['role'] as String?;
        _userId = user.uid;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
    }
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.group != null) {
        // Update existing group
        final updatedGroup = widget.group!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text,
          leaderId: _selectedLeaderId!,
          meetingTime:
              _meetingTimeController.text.isNotEmpty
                  ? _meetingTimeController.text
                  : null,
          meetingLocation:
              _meetingLocationController.text.isNotEmpty
                  ? _meetingLocationController.text
                  : null,
          updatedAt: DateTime.now(),
        );

        await _groupService.updateSmallGroup(
          widget.churchId,
          widget.group!.id,
          updatedGroup,
        );
      } else {
        // Create new group
        final newGroup = SmallGroup(
          id: '', // Will be set by Firestore
          name: _nameController.text,
          description: _descriptionController.text,
          churchId: widget.churchId,
          leaderId: _selectedLeaderId!,
          members: [],
          meetingTime:
              _meetingTimeController.text.isNotEmpty
                  ? _meetingTimeController.text
                  : null,
          meetingLocation:
              _meetingLocationController.text.isNotEmpty
                  ? _meetingLocationController.text
                  : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _groupService.createSmallGroup(widget.churchId, newGroup);
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        true,
      ); // Pass back true to indicate successful operation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.group != null
                ? 'Group updated successfully'
                : 'Group created successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving group: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.group != null ? 'Edit Small Group' : 'Create Small Group',
        ),
        actions: [
          if (!_isLoading)
            TextButton(onPressed: _saveGroup, child: const Text('Save')),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a group name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedLeaderId,
                      decoration: const InputDecoration(
                        labelText: 'Group Leader',
                      ),
                      items:
                          _churchLeaders.map<DropdownMenuItem<String>>((
                            leader,
                          ) {
                            return DropdownMenuItem<String>(
                              value: leader['id'] as String,
                              child: Text(
                                '${leader['name']} (${leader['role'].toString().toUpperCase()})',
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedLeaderId = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a group leader';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _meetingTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Time (optional)',
                        hintText: 'e.g., Every Sunday at 6:00 PM',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _meetingLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Location (optional)',
                        hintText: 'e.g., Church Fellowship Hall',
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
