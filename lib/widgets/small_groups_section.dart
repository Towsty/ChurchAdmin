import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/small_group.dart';
import '../services/group_service.dart';
import '../screens/small_group_portal_screen.dart';

class SmallGroupsSection extends StatefulWidget {
  final String churchId;

  const SmallGroupsSection({super.key, required this.churchId});

  @override
  State<SmallGroupsSection> createState() => _SmallGroupsSectionState();
}

class _SmallGroupsSectionState extends State<SmallGroupsSection> {
  final _groupService = GroupService();
  List<SmallGroup>? _userGroups;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final groups = await _groupService.getSmallGroups(widget.churchId);
      final userGroups =
          groups
              .where(
                (group) =>
                    group.members.contains(user.uid) ||
                    group.leaderId == user.uid,
              )
              .toList();

      if (mounted) {
        setState(() {
          _userGroups = userGroups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading groups: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userGroups == null || _userGroups!.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.groups),
          title: Text('You are not a member of any small groups'),
          subtitle: Text('Join a small group to see updates here'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Small Groups',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _userGroups!.length,
          itemBuilder: (context, index) {
            final group = _userGroups![index];
            return Card(
              child: ListTile(
                title: Text(group.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (group.meetingTime != null)
                      Text('Meets: ${group.meetingTime}'),
                    if (group.meetingLocation != null)
                      Text('Location: ${group.meetingLocation}'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SmallGroupPortalScreen(
                              churchId: widget.churchId,
                              group: group,
                            ),
                      ),
                    );
                  },
                  child: const Text('Go to Portal'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
