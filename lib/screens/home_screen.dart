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
import 'join_request_approval_screen.dart';
import 'member_landing_screen.dart';

import '../widgets/large_button.dart';
import '../services/join_request_service.dart';
import '../services/role_permissions.dart';

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
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data!;
        final userName = userData['name'] ?? 'User';
        final initials = userName.trim().isNotEmpty
            ? userName.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase()
            : '?';
        final rawRole = (userData['role'] ?? 'visitor').toString().toLowerCase();
        final role = rawRole[0].toUpperCase() + rawRole.substring(1);
        final hasChurch = userData['churchId'] != null && userData['churchId'].toString().isNotEmpty;
        final hasPendingRequest = userData['joinRequest'] != null;

        // No church and no request
        if (!hasChurch && !hasPendingRequest) {
          return Scaffold(
            appBar: AppBar(title: const Text('Welcome')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 60, color: Colors.blueGrey),
                  const SizedBox(height: 20),
                  const Text(
                    'You are not part of a church yet.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please search and request to join a church to get started.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurchSearchScreen()));
                    },
                    child: const Text('Find a Church'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {}); // Triggers a rebuild to recheck user data
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check for Updates'),
                  ),
                ],
              ),
            ),
          );
        }


        // Pending join request
        if (!hasChurch && hasPendingRequest) {
          final pendingChurchId = userData['joinRequest']['churchId'];
          final requestedAt = userData['joinRequest']['requestedAt'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('churches').doc(pendingChurchId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final churchData = snapshot.data!.data() as Map<String, dynamic>?;

              return Scaffold(
                appBar: AppBar(title: const Text('Pending Approval')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_top, size: 60, color: Colors.orange),
                      const SizedBox(height: 20),
                      Text(
                        'Your request to join "${churchData?['name'] ?? 'this church'}" is pending approval.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Requested on: ${requestedAt?.toDate().toLocal().toString().split(" ")[0] ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      if (churchData?['meetingTimes'] != null) ...[
                        const Text('Meeting Times:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(churchData!['meetingTimes'], textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                      ],
                      if (churchData?['contactEmail'] != null)
                        Text('Contact: ${churchData!['contactEmail']}'),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // Get church name for all other roles
        return FutureBuilder<String?>(
          future: _getChurchName(),
          builder: (context, churchSnapshot) {
            if (!churchSnapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final churchName = churchSnapshot.data ?? 'Church Admin';

            // Member role — show landing screen
            if (hasChurch) {
              return MemberLandingScreen(
                churchId: userData['churchId'],
                churchName: churchName,
              );
            }

            final isAdmin = rawRole == 'admin';

            // Admin or Leader dashboard
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
                leading: PopupMenuButton<String>(
                  tooltip: 'Account',
                  onSelected: (value) {
                    if (value == 'profile') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile screen coming soon.')),
                      );
                    } else if (value == 'logout') {
                      FirebaseAuth.instance.signOut();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Text('Profile'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Sign Out'),
                    ),
                  ],
                  child: Padding(
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
                    if (RolePermissions.canTakeAttendance(role))
                      LargeButton(
                        label: 'Take Attendance',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceInputScreen()));
                        },
                      ),
                    if (RolePermissions.canManageMeetingTypes(role))
                      Column(children: [
                        const SizedBox(height: 20),
                        LargeButton(
                          label: 'Manage Meeting Types',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingTypeManager()));
                          },
                        ),
                      ]),
                    if (RolePermissions.canExportAttendance(role))
                      Column(children: [
                        const SizedBox(height: 20),
                        LargeButton(
                          label: 'Export Attendance Data',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen()));
                          },
                        ),
                      ]),
                    if (RolePermissions.canViewAttendance(role))
                      Column(children: [
                        const SizedBox(height: 20),
                        LargeButton(
                          label: 'View Past Attendance',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()));
                          },
                        ),
                        const SizedBox(height: 30),
                      ]),
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
