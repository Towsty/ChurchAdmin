import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/small_group.dart';
import '../services/group_service.dart';
import '../services/role_permissions.dart';
import 'manage_small_groups_screen.dart';

class SmallGroupsAdminScreen extends StatefulWidget {
  final String churchId;

  const SmallGroupsAdminScreen({super.key, required this.churchId});

  @override
  State<SmallGroupsAdminScreen> createState() => _SmallGroupsAdminScreenState();
}

class _SmallGroupsAdminScreenState extends State<SmallGroupsAdminScreen> {
  final _groupService = GroupService();
  bool _isLoading = false;
  String? _userRole;
  String? _userId;
  List<SmallGroup> _groups = [];
  Map<String, String> _leaderNames = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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

      await _loadGroups();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _groupService.getSmallGroups(widget.churchId);
      final leaderIds = groups.map((g) => g.leaderId).toSet().toList();

      print('🔍 Loading leader names for IDs: $leaderIds');

      // Get leader names
      final leaderDocs = await Future.wait(
        leaderIds.map(
          (id) => FirebaseFirestore.instance.collection('users').doc(id).get(),
        ),
      );

      final leaderNames = Map.fromEntries(
        leaderDocs.map((doc) {
          final data = doc.data();
          final name = data?['name'] as String?;
          print('👤 Leader ${doc.id}: ${name ?? 'Unknown'} (data: $data)');
          return MapEntry(doc.id, name ?? 'Unknown');
        }),
      );

      print('📊 Final leader names map: $_leaderNames');

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _leaderNames = leaderNames;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading groups: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Small Groups Admin'),
        actions: [
          if (_userRole != null &&
              RolePermissions.canCreateSmallGroup(_userRole!))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ManageSmallGroupsScreen(churchId: widget.churchId),
                  ),
                ).then((_) => _loadGroups());
              },
              tooltip: 'Create New Group',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadGroups,
                child:
                    _groups.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No small groups created yet'),
                              if (_userRole != null &&
                                  RolePermissions.canCreateSmallGroup(
                                    _userRole!,
                                  ))
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                ManageSmallGroupsScreen(
                                                  churchId: widget.churchId,
                                                ),
                                      ),
                                    ).then((_) => _loadGroups());
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create First Group'),
                                ),
                            ],
                          ),
                        )
                        : ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Overview',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Total Groups: ${_groups.length}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Total Members: ${_groups.fold(0, (sum, group) => sum + group.members.length)}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Active Groups: ${_groups.where((g) => g.isActive).length}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _groups.length,
                              itemBuilder: (context, index) {
                                final group = _groups[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    title: Text(group.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(group.description),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Leader: ${_leaderNames[group.leaderId] ?? 'Unknown'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Members: ${group.members.length}',
                                        ),
                                        if (group.meetingTime != null)
                                          Text(
                                            'Meeting Time: ${group.meetingTime}',
                                          ),
                                        if (group.meetingLocation != null)
                                          Text(
                                            'Location: ${group.meetingLocation}',
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        ManageSmallGroupsScreen(
                                                          churchId:
                                                              widget.churchId,
                                                          group: group,
                                                        ),
                                              ),
                                            ).then((updated) {
                                              if (updated == true) {
                                                _loadGroups();
                                              }
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () async {
                                            final confirmed = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text(
                                                      'Delete Group',
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        style:
                                                            TextButton.styleFrom(
                                                              foregroundColor:
                                                                  Colors.red,
                                                            ),
                                                        child: const Text(
                                                          'Delete',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );

                                            if (confirmed == true) {
                                              try {
                                                await _groupService
                                                    .deleteSmallGroup(
                                                      widget.churchId,
                                                      group.id,
                                                    );
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Group deleted successfully',
                                                    ),
                                                  ),
                                                );
                                                _loadGroups();
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error deleting group: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
              ),
    );
  }
}
