
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import 'attendance_input_screen.dart';
import 'meeting_type_manager.dart';
import 'export_screen.dart';
import 'attendance_history_screen.dart';
import 'create_church_screen.dart';
import 'church_search_screen.dart';
import 'JoinRequestApprovalScreen.dart';
import '../widgets/large_button.dart';

import '../services/join_request_service.dart';
final JoinRequestService _joinRequestService = JoinRequestService();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMenu = false;

  Future<String> _getVersionString() async {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version} (${info.buildNumber})';
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  Future<String?> _getChurchName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final churchId = userDoc.data()?['churchId'];
    if (churchId == null || churchId == '') return null;
    final churchDoc = await FirebaseFirestore.instance.collection('churches').doc(churchId).get();
    return churchDoc.data()?['name'];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data ?? {};
        final userName = userData['name'] ?? 'User';
        final initials = userName.trim().isNotEmpty
            ? userName.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase()
            : '?';
        final rawRole = (userData['role'] ?? 'member').toString();
        final role = rawRole[0].toUpperCase() + rawRole.substring(1).toLowerCase();
        final isAdmin = role == 'Admin';

        return FutureBuilder<String?>(
          future: _getChurchName(),
          builder: (context, churchSnapshot) {
            final churchName = churchSnapshot.data ?? 'Church Admin';

            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: GestureDetector(
                  onTap: () => setState(() => _showMenu = !_showMenu),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.deepPurple, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              churchName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              role,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_showMenu)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.search),
                            title: const Text('Find Church'),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurchSearchScreen()));
                            },
                          ),
                          if (isAdmin)
                            ListTile(
                              leading: const Icon(Icons.church),
                              title: const Text('Create Church'),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateChurchScreen()));
                              },
                            ),
                          if (isAdmin)
                            StreamBuilder<int>(
                              stream: _joinRequestService.joinRequestCountStream(),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;

                                return ListTile(
                                  leading: const Icon(Icons.how_to_reg),
                                  title: Row(
                                    children: [
                                      const Text('Approve Join Requests'),
                                      if (count > 0)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinRequestApprovalScreen()));
                                  },
                                );
                              },
                            ),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Profile'),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile screen coming soon.')));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Sign Out'),
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                          ),
                          const Divider(),
                        ],
                      ),
                    const Spacer(),
                    LargeButton(
                      label: 'Take Attendance',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceInputScreen()));
                      },
                    ),
                    const SizedBox(height: 20),
                    LargeButton(
                      label: 'Manage Meeting Types',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingTypeManager()));
                      },
                    ),
                    const SizedBox(height: 20),
                    LargeButton(
                      label: 'Export Attendance Data',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen()));
                      },
                    ),
                    const SizedBox(height: 20),
                    LargeButton(
                      label: 'View Past Attendance',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()));
                      },
                    ),
                    const SizedBox(height: 30),
                    FutureBuilder<String>(
                      future: _getVersionString(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox(height: 20);
                        return Text(
                          snapshot.data!,
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
