import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/role_permissions.dart';
import '../models/devotional.dart';
import 'devotionals_list_screen.dart';
import '../services/notification_service.dart';
import 'notifications_screen.dart';
import '../widgets/small_groups_section.dart';

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
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    print('🕒 Querying devotionals between:');
    print('   Start: ${today.toIso8601String()}');
    print('   End: ${tomorrow.toIso8601String()}');

    final devotionalsRef = FirebaseFirestore.instance
        .collection('churches')
        .doc(widget.churchId)
        .collection('devotionals')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('date', isLessThan: Timestamp.fromDate(tomorrow))
        .where('isArchived', isEqualTo: false)
        .orderBy('date', descending: true)
        .limit(1);

    final meetingsRef = FirebaseFirestore.instance
        .collection('churches')
        .doc(widget.churchId)
        .collection('meetings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .orderBy('date')
        .limit(3);

    var announcementsRef = FirebaseFirestore.instance
        .collection('churches')
        .doc(widget.churchId)
        .collection('announcements')
        .where('isArchived', isEqualTo: false)
        .orderBy('postedAt', descending: true)
        .limit(3);

    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? 'User';

    final initials =
        userName.trim().isNotEmpty
            ? userName
                .trim()
                .split(' ')
                .map((s) => s[0])
                .take(2)
                .join()
                .toUpperCase()
            : '?';

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        print(
          'User document snapshot state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}',
        );
        final userRole =
            snapshot.data?.data() != null
                ? (snapshot.data!.data() as Map)['role'] ?? 'visitor'
                : 'visitor';

        print('👤 User Role: $userRole'); // Debug log
        print(
          '🔑 Can Access Admin Portal: ${RolePermissions.canAccessAdminPortal(userRole)}',
        ); // Debug log

        return Scaffold(
          appBar: AppBar(
            title: Text('Welcome to ${widget.churchName}'),
            actions: [
              StreamBuilder<int>(
                stream: _notificationService.getUnreadNotificationsCount(
                  user!.uid,
                ),
                builder: (context, notificationSnapshot) {
                  return Stack(
                    children: [
                      PopupMenuButton<String>(
                        tooltip: 'Account',
                        onSelected: (value) {
                          if (value == 'profile') {
                            Navigator.pushNamed(context, '/profile');
                          } else if (value == 'notifications') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationsScreen(),
                              ),
                            );
                          } else if (value == 'logout') {
                            FirebaseAuth.instance.signOut();
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'profile',
                                child: Text('Profile'),
                              ),
                              const PopupMenuItem(
                                value: 'notifications',
                                child: Text('Notifications'),
                              ),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Text('Sign Out'),
                              ),
                            ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage:
                                  (snapshot.data?.data()
                                              as Map<
                                                String,
                                                dynamic
                                              >?)?['photoUrl'] !=
                                          null
                                      ? NetworkImage(
                                        (snapshot.data!.data()
                                            as Map<
                                              String,
                                              dynamic
                                            >)['photoUrl'],
                                      )
                                      : null,
                              child:
                                  ((snapshot.data?.data()
                                              as Map<
                                                String,
                                                dynamic
                                              >?)?['photoUrl'] ==
                                          null)
                                      ? Text(
                                        initials,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      )
                                      : null,
                              radius: 20,
                            ),
                          ),
                        ),
                      ),
                      if (notificationSnapshot.hasData &&
                          notificationSnapshot.data! > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              notificationSnapshot.data.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: devotionalsRef.snapshots(),
                        builder: (context, snapshot) {
                          print('📱 Devotional StreamBuilder state:');
                          print('   Has data: ${snapshot.hasData}');
                          print('   Has error: ${snapshot.hasError}');
                          if (snapshot.hasError) {
                            print('   Error: ${snapshot.error}');
                            print('   Stack trace: ${snapshot.stackTrace}');
                          }

                          if (snapshot.hasError) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Error loading devotional',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      snapshot.error.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.red,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;
                          print('📚 Found ${docs.length} devotionals');

                          if (docs.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No devotional for today.'),
                              ),
                            );
                          }

                          try {
                            final devotional = Devotional.fromFirestore(
                              docs.first,
                            );
                            print('📖 Loaded devotional:');
                            print('   Title: ${devotional.title}');
                            print('   Scripture: ${devotional.scriptureFocus}');
                            print('   Tags: ${devotional.tags.join(", ")}');

                            return GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF121212)
                                          : Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  devotional.title,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  devotional.scriptureFocus,
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                                if (devotional
                                                    .tags
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    children:
                                                        devotional.tags
                                                            .map(
                                                              (tag) => Chip(
                                                                label: Text(
                                                                  tag,
                                                                ),
                                                              ),
                                                            )
                                                            .toList(),
                                                  ),
                                                ],
                                                const Divider(height: 20),
                                                ...devotional.content.map((
                                                  content,
                                                ) {
                                                  return Text(
                                                    content.text,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          content.isBold
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                      fontStyle:
                                                          content.isItalic
                                                              ? FontStyle.italic
                                                              : FontStyle
                                                                  .normal,
                                                      decoration:
                                                          content.isUnderline
                                                              ? TextDecoration
                                                                  .underline
                                                              : null,
                                                      fontSize:
                                                          content.fontSize
                                                              ?.toDouble(),
                                                    ),
                                                  );
                                                }).toList(),
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
                                  title: Text(devotional.title),
                                  subtitle: Text(
                                    devotional.scriptureFocus,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.expand_more),
                                ),
                              ),
                            );
                          } catch (e) {
                            print('Error loading devotional: $e');
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Error loading devotional'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Upcoming Meetings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: meetingsRef.snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            print('Error loading meetings: ${snapshot.error}');
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Error loading meetings',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final meetings = snapshot.data!.docs;
                          if (meetings.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No upcoming meetings scheduled.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF121212)
                                        : Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder:
                                    (context) => DraggableScrollableSheet(
                                      initialChildSize: 0.4,
                                      minChildSize: 0.3,
                                      maxChildSize: 0.9,
                                      expand: false,
                                      builder: (context, scrollController) {
                                        return SingleChildScrollView(
                                          controller: scrollController,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Text(
                                                  'Upcoming Meetings',
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.headlineSmall,
                                                ),
                                              ),
                                              ...meetings.map((doc) {
                                                final data =
                                                    doc.data()
                                                        as Map<String, dynamic>;
                                                final date =
                                                    (data['date'] as Timestamp)
                                                        .toDate();
                                                return ListTile(
                                                  title: Text(
                                                    data['title'] ?? 'Untitled',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        DateFormat(
                                                          'EEEE, MMMM d, y - h:mm a',
                                                        ).format(date),
                                                      ),
                                                      if (data['location'] !=
                                                          null)
                                                        Text(
                                                          'Location: ${data['location']}',
                                                        ),
                                                      if (data['description'] !=
                                                          null)
                                                        Text(
                                                          data['description'],
                                                          style:
                                                              const TextStyle(
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                  isThreeLine: true,
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                              );
                            },
                            child: Card(
                              child: ListTile(
                                title: Text(
                                  'View upcoming meetings (${meetings.length})',
                                ),
                                trailing: const Icon(Icons.expand_more),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SmallGroupsSection(churchId: widget.churchId),
                      const SizedBox(height: 24),
                      const Text(
                        'Announcements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: announcementsRef.snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            print('Announcements error: ${snapshot.error}');
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.cloud_off,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Unable to load announcements',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      snapshot.error.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                      onPressed: () {
                                        setState(() {
                                          // Reinitialize the stream
                                          announcementsRef = FirebaseFirestore
                                              .instance
                                              .collection('churches')
                                              .doc(widget.churchId)
                                              .collection('announcements')
                                              .where(
                                                'isArchived',
                                                isEqualTo: false,
                                              )
                                              .orderBy(
                                                'postedAt',
                                                descending: true,
                                              )
                                              .limit(3);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }

                          final announcements = snapshot.data!.docs;

                          // Debug print for announcements
                          print(
                            'Fetched ${announcements.length} announcements',
                          );
                          announcements.forEach((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            print('Announcement: ${doc.id} - $data');
                          });

                          if (announcements.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No announcements available.'),
                              ),
                            );
                          }

                          // Filter announcements for the count
                          final validAnnouncements =
                              announcements.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final isArchived =
                                    data['isArchived'] as bool? ?? false;
                                if (isArchived) return false;

                                final displayCount =
                                    data['displayCount'] as int?;
                                final currentDisplayCount =
                                    data['currentDisplayCount'] as int? ?? 0;
                                if (displayCount != null &&
                                    currentDisplayCount >= displayCount)
                                  return false;

                                final expiryDate =
                                    (data['expiryDate'] as Timestamp?)
                                        ?.toDate();
                                if (expiryDate != null &&
                                    DateTime.now().isAfter(expiryDate))
                                  return false;

                                return true;
                              }).toList();

                          if (validAnnouncements.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No active announcements.'),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              if (!snapshot.hasData || snapshot.hasError) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Unable to load announcements. Please check your connection.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF121212)
                                        : Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (context) {
                                  print(
                                    'Raw announcements count: ${announcements.length}',
                                  );
                                  announcements.forEach((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    print('Raw announcement data: $data');
                                  });

                                  // Filter out announcements that shouldn't be displayed
                                  final validAnnouncements =
                                      announcements.where((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        print('Checking announcement: $data');

                                        // Check if archived
                                        final isArchived =
                                            data['isArchived'] as bool? ??
                                            false;
                                        if (isArchived) {
                                          print('Filtered out: archived');
                                          return false;
                                        }

                                        // Check display count
                                        final displayCount =
                                            data['displayCount'] as int?;
                                        final currentDisplayCount =
                                            data['currentDisplayCount']
                                                as int? ??
                                            0;

                                        if (displayCount != null &&
                                            currentDisplayCount >=
                                                displayCount) {
                                          print(
                                            'Filtered out: display count limit reached',
                                          );
                                          return false;
                                        }

                                        // Check expiry
                                        final expiryDate =
                                            (data['expiryDate'] as Timestamp?)
                                                ?.toDate();
                                        if (expiryDate != null &&
                                            DateTime.now().isAfter(
                                              expiryDate,
                                            )) {
                                          print('Filtered out: expired');
                                          return false;
                                        }

                                        print('Announcement is valid');
                                        return true;
                                      }).toList();

                                  print(
                                    'Valid announcements count: ${validAnnouncements.length}',
                                  );

                                  if (validAnnouncements.isEmpty) {
                                    return Container(
                                      height: 200,
                                      padding: const EdgeInsets.all(16),
                                      child: const Center(
                                        child: Text(
                                          'No active announcements',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return Container(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.7,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.1),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Announcements',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                ),
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            padding: const EdgeInsets.all(16),
                                            itemCount:
                                                validAnnouncements.length,
                                            itemBuilder: (context, index) {
                                              final doc =
                                                  validAnnouncements[index];
                                              final data =
                                                  doc.data()
                                                      as Map<String, dynamic>;

                                              print(
                                                'Building announcement card: $data',
                                              );

                                              final postedAt =
                                                  data['postedAt']
                                                      as Timestamp?;
                                              final date = postedAt?.toDate();
                                              final expiryDate =
                                                  (data['expiryDate']
                                                          as Timestamp?)
                                                      ?.toDate();
                                              final displayCount =
                                                  data['displayCount'] as int?;
                                              final currentDisplayCount =
                                                  data['currentDisplayCount']
                                                      as int? ??
                                                  0;

                                              // Only increment display count once when the modal is opened
                                              if (index == 0) {
                                                WidgetsBinding.instance.addPostFrameCallback((
                                                  _,
                                                ) async {
                                                  try {
                                                    final batch =
                                                        FirebaseFirestore
                                                            .instance
                                                            .batch();
                                                    for (var announcement
                                                        in validAnnouncements) {
                                                      final announcementData =
                                                          announcement.data()
                                                              as Map<
                                                                String,
                                                                dynamic
                                                              >;
                                                      final currentCount =
                                                          announcementData['currentDisplayCount']
                                                              as int? ??
                                                          0;
                                                      batch.update(
                                                        announcement.reference,
                                                        {
                                                          'currentDisplayCount':
                                                              currentCount + 1,
                                                        },
                                                      );
                                                    }
                                                    await batch.commit();
                                                  } catch (e) {
                                                    print(
                                                      'Error updating announcement display counts: $e',
                                                    );
                                                  }
                                                });
                                              }

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8.0,
                                                ),
                                                child: Card(
                                                  elevation: 2,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16.0,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .announcement,
                                                              color:
                                                                  Theme.of(
                                                                    context,
                                                                  ).primaryColor,
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                data['message'] ??
                                                                    '',
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        if (date != null)
                                                          Text(
                                                            'Posted: ${DateFormat.yMMMd().format(date)}',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        if (expiryDate != null)
                                                          Text(
                                                            'Expires: ${DateFormat.yMMMd().format(expiryDate)}',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        if (displayCount !=
                                                            null)
                                                          Text(
                                                            'Shown ${currentDisplayCount + 1}/$displayCount times',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Card(
                              child: ListTile(
                                title: Text(
                                  'View announcements (${validAnnouncements.length})',
                                ),
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
                        icon: const Icon(Icons.book),
                        tooltip: 'Devotionals',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DevotionalsListScreen(
                                    churchId: widget.churchId,
                                    churchName: widget.churchName,
                                  ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download),
                        tooltip: 'Export Data',
                        onPressed: () {
                          Navigator.pushNamed(context, '/export');
                        },
                      ),
                      if (RolePermissions.canAccessAdminPortal(userRole))
                        IconButton(
                          icon: const Icon(Icons.admin_panel_settings),
                          tooltip: 'Admin Portal',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/admin',
                              arguments: {
                                'churchId': widget.churchId,
                                'churchName': widget.churchName,
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
