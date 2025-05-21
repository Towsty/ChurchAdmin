import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/small_group.dart';
import '../services/group_service.dart';
import '../services/role_permissions.dart';

class ManageGroupMembersScreen extends StatefulWidget {
  final String churchId;
  final SmallGroup group;

  const ManageGroupMembersScreen({
    super.key,
    required this.churchId,
    required this.group,
  });

  @override
  State<ManageGroupMembersScreen> createState() =>
      _ManageGroupMembersScreenState();
}

class _ManageGroupMembersScreenState extends State<ManageGroupMembersScreen> {
  final _groupService = GroupService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _churchMembers = [];
  List<String> _selectedMembers = [];
  String? _userRole;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadChurchMembers();
    _selectedMembers = List.from(widget.group.members);
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

  Future<void> _loadChurchMembers() async {
    setState(() => _isLoading = true);

    try {
      // First get the members from the church's members subcollection
      final membersSnapshot =
          await FirebaseFirestore.instance
              .collection('churches')
              .doc(widget.churchId)
              .collection('members')
              .get();

      // Then get the corresponding user documents for additional details
      final memberIds = membersSnapshot.docs.map((doc) => doc.id).toList();
      final userDocs = await Future.wait(
        memberIds.map(
          (id) => FirebaseFirestore.instance.collection('users').doc(id).get(),
        ),
      );

      setState(() {
        _churchMembers =
            userDocs.where((doc) => doc.exists).map((doc) {
              final data = doc.data()!;
              return {
                'id': doc.id,
                'name': data['name'] as String? ?? 'Unknown',
                'email': data['email'] as String? ?? '',
                'photoUrl': data['photoUrl'] as String?,
                'role': data['role'] as String? ?? 'member',
              };
            }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading church members: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_userRole == null ||
        _userId == null ||
        !RolePermissions.canManageSmallGroupMembers(
          _userRole!,
          _userId!,
          widget.group.leaderId,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to manage members'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get the members to add and remove
      final membersToAdd = _selectedMembers.where(
        (m) => !widget.group.members.contains(m),
      );
      final membersToRemove = widget.group.members.where(
        (m) => !_selectedMembers.contains(m),
      );

      // Add new members
      for (final memberId in membersToAdd) {
        await _groupService.addUserToGroup(
          memberId,
          widget.group.id,
          'smallGroups',
          widget.churchId,
        );
      }

      // Remove members
      for (final memberId in membersToRemove) {
        await _groupService.removeUserFromGroup(
          memberId,
          widget.group.id,
          'smallGroups',
          widget.churchId,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Members updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating members: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManageMembers =
        _userRole != null &&
        _userId != null &&
        RolePermissions.canManageSmallGroupMembers(
          _userRole!,
          _userId!,
          widget.group.leaderId,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.group.name} Members'),
        actions: [
          if (canManageMembers)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: const Text('Save'),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _churchMembers.length,
                itemBuilder: (context, index) {
                  final member = _churchMembers[index];
                  final isSelected = _selectedMembers.contains(member['id']);
                  final isLeader = member['id'] == widget.group.leaderId;

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged:
                        !canManageMembers || isLeader
                            ? null // Leader cannot be removed and non-managers cannot change
                            : (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedMembers.add(member['id']);
                                } else {
                                  _selectedMembers.remove(member['id']);
                                }
                              });
                            },
                    title: Text(member['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member['email']),
                        Text(
                          member['role'].toString().toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    secondary: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              member['photoUrl'] != null
                                  ? NetworkImage(member['photoUrl'])
                                  : null,
                          child:
                              member['photoUrl'] == null
                                  ? Text(member['name'][0].toUpperCase())
                                  : null,
                        ),
                        if (isLeader) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Leader',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
