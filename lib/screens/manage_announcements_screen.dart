import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/role_permissions.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  final String churchId;

  const ManageAnnouncementsScreen({super.key, required this.churchId});

  @override
  State<ManageAnnouncementsScreen> createState() =>
      _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  final _messageController = TextEditingController();
  DateTime? _expiryDate;
  int? _displayCount;
  bool _showArchived = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
      });
    }
  }

  Future<void> _addAnnouncement() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId)
          .collection('announcements')
          .add({
            'message': message,
            'postedAt': FieldValue.serverTimestamp(),
            'expiryDate': _expiryDate?.toUtc(),
            'displayCount': _displayCount,
            'currentDisplayCount': 0,
            'isArchived': false,
          });

      if (mounted) {
        _messageController.clear();
        setState(() {
          _expiryDate = null;
          _displayCount = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Announcement posted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting announcement: $e')),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Announcement'),
            content: const Text(
              'Are you sure you want to delete this announcement?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId)
          .collection('announcements')
          .doc(id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Announcement deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting announcement: $e')),
        );
      }
    }
  }

  Future<void> _toggleArchiveAnnouncement(String id, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId)
          .collection('announcements')
          .doc(id)
          .update({'isArchived': !currentStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? 'Announcement unarchived'
                  : 'Announcement archived',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating announcement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        actions: [
          IconButton(
            icon: Icon(
              _showArchived ? Icons.inbox : Icons.archive,
              color: _showArchived ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
            },
            tooltip: _showArchived ? 'Show Active' : 'Show Archived',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'New Announcement',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addAnnouncement,
                          icon: const Icon(Icons.send),
                          label: const Text('Post'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _selectExpiryDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _expiryDate == null
                                ? 'Set Expiry'
                                : 'Expires: ${_expiryDate!.toLocal().toString().split(' ')[0]}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Display Count: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('∞'),
                      selected: _displayCount == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _displayCount = null);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    for (var count in [1, 3, 5, 10])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$count'),
                          selected: _displayCount == count,
                          onSelected: (selected) {
                            setState(
                              () => _displayCount = selected ? count : null,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('churches')
                      .doc(widget.churchId)
                      .collection('announcements')
                      .where('isArchived', isEqualTo: _showArchived)
                      .orderBy('postedAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final announcements = snapshot.data!.docs;

                if (announcements.isEmpty) {
                  return Center(
                    child: Text(
                      _showArchived
                          ? 'No archived announcements'
                          : 'No active announcements',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: announcements.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    final data = announcement.data() as Map<String, dynamic>;
                    final message = data['message'] ?? '';
                    final postedAt = (data['postedAt'] as Timestamp?)?.toDate();
                    final expiryDate =
                        (data['expiryDate'] as Timestamp?)?.toDate();
                    final displayCount = data['displayCount'] as int?;
                    final currentDisplayCount =
                        data['currentDisplayCount'] as int? ?? 0;
                    final isArchived = data['isArchived'] as bool? ?? false;

                    String subtitle =
                        'Posted on: ${postedAt?.toLocal().toString().split('.')[0] ?? 'Unknown'}';
                    if (expiryDate != null) {
                      subtitle +=
                          '\nExpires on: ${expiryDate.toLocal().toString().split('.')[0]}';
                    }
                    if (displayCount != null) {
                      subtitle +=
                          '\nShown $currentDisplayCount/$displayCount times';
                    }

                    return Card(
                      child: ListTile(
                        title: Text(message),
                        subtitle: Text(subtitle),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isArchived ? Icons.unarchive : Icons.archive,
                                color: isArchived ? Colors.amber : Colors.grey,
                              ),
                              onPressed:
                                  () => _toggleArchiveAnnouncement(
                                    announcement.id,
                                    isArchived,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  () => _deleteAnnouncement(announcement.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
