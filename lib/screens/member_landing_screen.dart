import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MemberLandingScreen extends StatefulWidget {
  final String churchId;
  final String churchName;

  const MemberLandingScreen({
    super.key,
    required this.churchId,
    required this.churchName,
  });

  @override
  State<MemberLandingScreen> createState() => _MemberLandingScreenState();
}

class _MemberLandingScreenState extends State<MemberLandingScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final todayId = DateFormat('yyyyMMdd').format(DateTime.now());

    final devotionalRef = FirebaseFirestore.instance
        .collection('churches')
        .doc(widget.churchId)
        .collection('devotionals')
        .doc(todayId);

    final meetingsRef = FirebaseFirestore.instance
        .collection('churches')
        .doc(widget.churchId)
        .collection('meetings')
        .orderBy('date')
        .limit(3);

    final announcementsRef = FirebaseFirestore.instance
        .collection('churches')
        .doc(widget.churchId)
        .collection('announcements')
        .orderBy('postedAt', descending: true)
        .limit(3);

    final userName = user?.displayName ??
        user?.email?.split('@').first ??
        'User';

    final initials = userName.trim().isNotEmpty
        ? userName.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase()
        : '?';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get(),
      builder: (context, snapshot) {
        final userRole = snapshot.data?.data() != null
            ? (snapshot.data!.data() as Map)['role'] ?? 'visitor'
            : 'visitor';

        return Scaffold(
          appBar: AppBar(
            title: Text('Welcome to ${widget.churchName}'),
            actions: [
              PopupMenuButton<String>(
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
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'profile', child: Text('Profile')),
                  PopupMenuItem(value: 'logout', child: Text('Sign Out')),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Devotional',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<DocumentSnapshot>(
                        future: devotionalRef.get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final data = snapshot.data?.data() as Map<String, dynamic>?;
                          if (data == null) return const Text('No devotional for today.');

                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    expand: false,
                                    initialChildSize: 0.6,
                                    minChildSize: 0.4,
                                    maxChildSize: 0.95,
                                    builder: (_, controller) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: SingleChildScrollView(
                                          controller: controller,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(data['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              Text(data['verse'] ?? '', style: const TextStyle(fontStyle: FontStyle.italic)),
                                              const Divider(height: 20),
                                              Text(data['content'] ?? ''),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Card(
                              child: ListTile(
                                title: Text(data['title'] ?? ''),
                                subtitle: Text(
                                  data['verse'] ?? '',
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                                trailing: const Icon(Icons.expand_more),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Upcoming Meetings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: meetingsRef.snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final meetings = snapshot.data!.docs;
                          if (meetings.isEmpty) return const Text('No upcoming meetings.');

                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    expand: false,
                                    initialChildSize: 0.6,
                                    minChildSize: 0.4,
                                    maxChildSize: 0.95,
                                    builder: (_, controller) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: SingleChildScrollView(
                                          controller: controller,
                                          child: Column(
                                            children: meetings.map((doc) {
                                              final data = doc.data() as Map<String, dynamic>;
                                              final date = (data['date'] as Timestamp).toDate();
                                              return Card(
                                                child: ListTile(
                                                  leading: const Icon(Icons.event),
                                                  title: Text(data['title'] ?? ''),
                                                  subtitle: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Date: ${DateFormat.yMMMd().format(date)}'),
                                                      if (data['location'] != null) Text('Location: ${data['location']}'),
                                                      if (data['description'] != null) Text(data['description']),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Card(
                              child: ListTile(
                                title: Text('View upcoming meetings (${meetings.length})'),
                                trailing: const Icon(Icons.expand_more),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Announcements',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: announcementsRef.snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final announcements = snapshot.data!.docs;
                          if (announcements.isEmpty) return const Text('No announcements.');

                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    expand: false,
                                    initialChildSize: 0.5,
                                    minChildSize: 0.3,
                                    maxChildSize: 0.9,
                                    builder: (_, controller) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: SingleChildScrollView(
                                          controller: controller,
                                          child: Column(
                                            children: announcements.map((doc) {
                                              final data = doc.data() as Map<String, dynamic>;
                                              final date = (data['postedAt'] as Timestamp).toDate();
                                              return Card(
                                                child: ListTile(
                                                  leading: const Icon(Icons.announcement),
                                                  title: Text(data['message'] ?? ''),
                                                  subtitle: Text(DateFormat.yMMMd().format(date)),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Card(
                              child: ListTile(
                                title: Text('View announcements (${announcements.length})'),
                                trailing: const Icon(Icons.expand_more),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        tooltip: 'Take Attendance',
                        onPressed: () {
                          Navigator.pushNamed(context, '/attendance');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.history),
                        tooltip: 'Past Attendance',
                        onPressed: () {
                          Navigator.pushNamed(context, '/attendance-history');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        tooltip: 'Meeting Types',
                        onPressed: () {
                          Navigator.pushNamed(context, '/meeting-types');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download),
                        tooltip: 'Export Data',
                        onPressed: () {
                          Navigator.pushNamed(context, '/export');
                        },
                      ),
                      if (userRole == 'admin')
                        IconButton(
                          icon: const Icon(Icons.admin_panel_settings),
                          tooltip: 'Admin Tools',
                          onPressed: () {
                            Navigator.pushNamed(context, '/join-requests');
                          },
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
