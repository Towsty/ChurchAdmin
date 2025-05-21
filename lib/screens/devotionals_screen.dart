import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/role_permissions.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import '../components/custom_text_editor.dart';
import '../models/formatted_text.dart';

class DevotionalsScreen extends StatefulWidget {
  final String churchId;
  final String churchName;

  const DevotionalsScreen({
    super.key,
    required this.churchId,
    required this.churchName,
  });

  @override
  State<DevotionalsScreen> createState() => _DevotionalsScreenState();
}

class _DevotionalsScreenState extends State<DevotionalsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    setState(() {
      userRole = doc.data()?['role']?.toString().toLowerCase() ?? 'visitor';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Devotionals - ${widget.churchName}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('churches')
            .doc(widget.churchId)
            .collection('devotionals')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final devotionals = snapshot.data!.docs;

          if (devotionals.isEmpty) {
            return const Center(child: Text('No devotionals available.'));
          }

          return Column(
            children: [
              if (RolePermissions.canAccessAdminPortal(userRole ?? ''))
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('New Devotional'),
                          onPressed: _showNewDevotionalDialog,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: devotionals.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final data =
                        devotionals[index].data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    final isArchived = data['isArchived'] ?? false;
                    final tags = List<String>.from(data['tags'] ?? []);

                    if (isArchived &&
                        !RolePermissions.canAccessAdminPortal(userRole ?? '')) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        leading: Icon(
                          Icons.book,
                          color: isArchived ? Colors.grey : null,
                        ),
                        title: Text(
                          data['title'] ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat.yMMMd().format(date)),
                            if (data['scriptureFocus'] != null)
                              Text(
                                data['scriptureFocus'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (data['scripture'] != null) ...[
                                  Text(
                                    data['scripture'],
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (tags.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 8,
                                    children: tags
                                        .map((tag) => Chip(
                                              label: Text(tag),
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.1),
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                CustomTextEditor(
                                  initialContent: (data['content']
                                              as List<dynamic>?)
                                          ?.map((item) =>
                                              FormattedText.fromJson(
                                                  item as Map<String, dynamic>))
                                          .toList() ??
                                      [],
                                  onChanged: (_) {},
                                  readOnly: true,
                                ),
                              ],
                            ),
                          ),
                          if (RolePermissions.canAccessAdminPortal(
                              userRole ?? '')) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: Icon(
                                    isArchived
                                        ? Icons.unarchive
                                        : Icons.archive,
                                  ),
                                  label: Text(
                                    isArchived ? 'Unarchive' : 'Archive',
                                  ),
                                  onPressed: () => _toggleDevotionalArchive(
                                    devotionals[index].id,
                                    !isArchived,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                  onPressed: () => _showEditDevotionalDialog(
                                    devotionals[index].id,
                                    data,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () => _showDeleteDevotionalDialog(
                                    devotionals[index].id,
                                    data,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showNewDevotionalDialog() async {
    final titleController = TextEditingController();
    final scriptureFocusController = TextEditingController();
    final scriptureController = TextEditingController();
    final tagController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    List<String> tags = [];

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Devotional'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter devotional title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: scriptureFocusController,
                  decoration: const InputDecoration(
                    labelText: 'Scripture Focus',
                    hintText: 'Enter the key scripture or passage',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: scriptureController,
                  decoration: const InputDecoration(
                    labelText: 'Scripture Reference',
                    hintText: 'e.g., John 3:16',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: const InputDecoration(
                          labelText: 'Add Tag',
                          hintText: 'Enter tag and press +',
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              tags.add(value.trim());
                              tagController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final value = tagController.text.trim();
                        if (value.isNotEmpty) {
                          setState(() {
                            tags.add(value);
                            tagController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  tags.remove(tag);
                                });
                              },
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Date: ${DateFormat.yMMMd().format(selectedDate)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final scriptureFocus = scriptureFocusController.text.trim();
                final scripture = scriptureController.text.trim();

                if (title.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('churches')
                        .doc(widget.churchId)
                        .collection('devotionals')
                        .add({
                      'title': title,
                      'scriptureFocus': scriptureFocus,
                      'scripture': scripture,
                      'content': [],
                      'tags': tags,
                      'date': Timestamp.fromDate(selectedDate),
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy': user?.uid,
                      'isArchived': false,
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Devotional created successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    developer.log('❌ Error creating devotional: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error creating devotional'),
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in title'),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDevotionalDialog(
    String devotionalId,
    Map<String, dynamic> devotionalData,
  ) async {
    final titleController = TextEditingController(
      text: devotionalData['title'],
    );
    final scriptureFocusController = TextEditingController(
      text: devotionalData['scriptureFocus'],
    );
    final scriptureController = TextEditingController(
      text: devotionalData['scripture'],
    );
    final tagController = TextEditingController();
    DateTime selectedDate = (devotionalData['date'] as Timestamp).toDate();
    List<String> tags = List<String>.from(devotionalData['tags'] ?? []);

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Devotional'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter devotional title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: scriptureFocusController,
                  decoration: const InputDecoration(
                    labelText: 'Scripture Focus',
                    hintText: 'Enter the key scripture or passage',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: scriptureController,
                  decoration: const InputDecoration(
                    labelText: 'Scripture Reference',
                    hintText: 'e.g., John 3:16',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: const InputDecoration(
                          labelText: 'Add Tag',
                          hintText: 'Enter tag and press +',
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              tags.add(value.trim());
                              tagController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final value = tagController.text.trim();
                        if (value.isNotEmpty) {
                          setState(() {
                            tags.add(value);
                            tagController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  tags.remove(tag);
                                });
                              },
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Date: ${DateFormat.yMMMd().format(selectedDate)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final scriptureFocus = scriptureFocusController.text.trim();
                final scripture = scriptureController.text.trim();

                if (title.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('churches')
                        .doc(widget.churchId)
                        .collection('devotionals')
                        .doc(devotionalId)
                        .update({
                      'title': title,
                      'scriptureFocus': scriptureFocus,
                      'scripture': scripture,
                      'content': [],
                      'tags': tags,
                      'date': Timestamp.fromDate(selectedDate),
                      'updatedAt': FieldValue.serverTimestamp(),
                      'updatedBy': user?.uid,
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Devotional updated successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    developer.log('❌ Error updating devotional: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error updating devotional'),
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in title'),
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDevotionalDialog(
    String devotionalId,
    Map<String, dynamic> devotionalData,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Devotional'),
        content: Text(
          'Are you sure you want to delete "${devotionalData['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('churches')
                    .doc(widget.churchId)
                    .collection('devotionals')
                    .doc(devotionalId)
                    .delete();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Devotional deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                developer.log('❌ Error deleting devotional: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error deleting devotional'),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDevotionalArchive(
      String devotionalId, bool archive) async {
    try {
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId)
          .collection('devotionals')
          .doc(devotionalId)
          .update({
        'isArchived': archive,
        'archivedAt': archive ? FieldValue.serverTimestamp() : null,
        'archivedBy': archive ? user?.uid : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              archive
                  ? 'Devotional archived successfully'
                  : 'Devotional unarchived successfully',
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Error toggling devotional archive: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating devotional'),
          ),
        );
      }
    }
  }
}
