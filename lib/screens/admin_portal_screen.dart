import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/role_permissions.dart';
import 'manage_members_screen.dart';
import 'manage_announcements_screen.dart';
import 'meeting_type_manager.dart';
import 'church_settings_screen.dart';
import 'manage_join_requests_screen.dart';
import 'small_groups_admin_screen.dart';
import 'manage_meetings_screen.dart';

class AdminPortalScreen extends StatefulWidget {
  final String churchId;
  final String churchName;

  const AdminPortalScreen({
    super.key,
    required this.churchId,
    required this.churchName,
  });

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    setState(() {
      userRole = doc.data()?['role']?.toString().toLowerCase() ?? 'visitor';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!RolePermissions.canAccessAdminPortal(userRole!)) {
      return const Scaffold(
        body: Center(child: Text('Access denied: Admin only area')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.churchName} Admin')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _AdminCard(
            title: 'Join Requests',
            icon: Icons.person_add,
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ManageJoinRequestsScreen(churchId: widget.churchId),
                ),
              );
            },
          ),
          _AdminCard(
            title: 'Member Management',
            icon: Icons.people,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ManageMembersScreen(churchId: widget.churchId),
                ),
              );
            },
          ),
          _AdminCard(
            title: 'Meeting Types',
            icon: Icons.calendar_today,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MeetingTypeManager(),
                ),
              );
            },
          ),
          _AdminCard(
            title: 'Manage Meetings',
            icon: Icons.event,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ManageMeetingsScreen(churchId: widget.churchId),
                ),
              );
            },
          ),
          _AdminCard(
            title: 'Small Groups',
            icon: Icons.groups,
            color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          SmallGroupsAdminScreen(churchId: widget.churchId),
                ),
              );
            },
          ),
          _AdminCard(
            title: 'Announcements',
            icon: Icons.announcement,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ManageAnnouncementsScreen(churchId: widget.churchId),
                ),
              );
            },
          ),
          _AdminCard(
            title: 'Church Settings',
            icon: Icons.settings,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ChurchSettingsScreen(churchId: widget.churchId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
