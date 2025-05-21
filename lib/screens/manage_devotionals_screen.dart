import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/devotional.dart';
import '../components/custom_text_editor.dart';
import '../models/formatted_text.dart';

class ManageDevotionalsScreen extends StatefulWidget {
  final String churchId;

  const ManageDevotionalsScreen({super.key, required this.churchId});

  @override
  State<ManageDevotionalsScreen> createState() =>
      _ManageDevotionalsScreenState();
}

class _ManageDevotionalsScreenState extends State<ManageDevotionalsScreen> {
  bool _showArchived = false;
  String _selectedFilter = 'all';
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createDevotional() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final devotional = Devotional(
      id: '',
      date: pickedDate,
      title: '',
      content: [],
      scriptureFocus: '',
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _showDevotionalEditor(devotional, isNew: true);
  }

  Future<void> _showDevotionalEditor(
    Devotional devotional, {
    bool isNew = false,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) =>
              DevotionalEditorDialog(devotional: devotional, isNew: isNew),
    );

    if (result != null && mounted) {
      try {
        final devotionalRef = FirebaseFirestore.instance
            .collection('churches')
            .doc(widget.churchId)
            .collection('devotionals')
            .doc(isNew ? null : devotional.id);

        await devotionalRef.set({
          ...result,
          'updatedAt': FieldValue.serverTimestamp(),
          if (isNew) 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isNew ? 'Devotional created' : 'Devotional updated',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _toggleArchived(String id, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId)
          .collection('devotionals')
          .doc(id)
          .update({
            'isArchived': !currentStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus ? 'Devotional unarchived' : 'Devotional archived',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteDevotional(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Devotional'),
            content: const Text(
              'Are you sure you want to delete this devotional?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
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
          .collection('devotionals')
          .doc(id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Devotional deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Devotionals'),
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
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search devotionals...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _createDevotional,
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedFilter == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'all';
                              _selectedDate = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Today'),
                        selected: _selectedFilter == 'today',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'today';
                              _selectedDate = DateTime.now();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('This Week'),
                        selected: _selectedFilter == 'week',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'week';
                              _selectedDate = DateTime.now();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Future'),
                        selected: _selectedFilter == 'future',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'future';
                            });
                          }
                        },
                      ),
                    ],
                  ),
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
                      .collection('devotionals')
                      .where('isArchived', isEqualTo: _showArchived)
                      .orderBy('date', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var devotionals =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      final title = data['title'] as String? ?? '';
                      final scriptureFocus =
                          data['scriptureFocus'] as String? ?? '';
                      final searchTerm = _searchController.text.toLowerCase();

                      // Apply search filter
                      if (searchTerm.isNotEmpty) {
                        return title.toLowerCase().contains(searchTerm) ||
                            scriptureFocus.toLowerCase().contains(searchTerm);
                      }

                      // Apply date filter
                      switch (_selectedFilter) {
                        case 'today':
                          final today = DateTime.now();
                          return date.year == today.year &&
                              date.month == today.month &&
                              date.day == today.day;
                        case 'week':
                          final now = DateTime.now();
                          final weekStart = now.subtract(
                            Duration(days: now.weekday - 1),
                          );
                          final weekEnd = weekStart.add(
                            const Duration(days: 7),
                          );
                          return date.isAfter(weekStart) &&
                              date.isBefore(weekEnd);
                        case 'future':
                          return date.isAfter(DateTime.now());
                        default:
                          return true;
                      }
                    }).toList();

                if (devotionals.isEmpty) {
                  return Center(
                    child: Text(
                      _showArchived
                          ? 'No archived devotionals'
                          : 'No active devotionals',
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: devotionals.length,
                  itemBuilder: (context, index) {
                    final doc = devotionals[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    final isArchived = data['isArchived'] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isArchived ? Icons.unarchive : Icons.archive,
                                color: isArchived ? Colors.amber : Colors.grey,
                              ),
                              onPressed:
                                  () => _toggleArchived(doc.id, isArchived),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                final devotional = Devotional.fromFirestore(
                                  doc,
                                );
                                _showDevotionalEditor(devotional);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDevotional(doc.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          final devotional = Devotional.fromFirestore(doc);
                          _showDevotionalEditor(devotional);
                        },
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

class DevotionalEditorDialog extends StatefulWidget {
  final Devotional devotional;
  final bool isNew;

  const DevotionalEditorDialog({
    super.key,
    required this.devotional,
    this.isNew = false,
  });

  @override
  State<DevotionalEditorDialog> createState() => _DevotionalEditorDialogState();
}

class _DevotionalEditorDialogState extends State<DevotionalEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _scriptureFocusController;
  late DateTime _selectedDate;
  late List<FormattedText> _content;
  late List<String> _tags;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.devotional.title);
    _scriptureFocusController = TextEditingController(
      text: widget.devotional.scriptureFocus,
    );
    _selectedDate = widget.devotional.date;
    _content = List.from(widget.devotional.content);
    _tags = List.from(widget.devotional.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scriptureFocusController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _addTag() {
    showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Tag'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter tag name'),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final controller =
                      context
                          .findAncestorStateOfType<FormFieldState<String>>()
                          ?.value;
                  Navigator.pop(context, controller);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    ).then((tag) {
      if (tag != null && tag.isNotEmpty) {
        setState(() {
          _tags.add(tag);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNew ? 'Create Devotional' : 'Edit Devotional'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scriptureFocusController,
                decoration: const InputDecoration(
                  labelText: 'Scripture Focus',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a scripture focus';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              const Text('Content'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: CustomTextEditor(
                  initialContent: _content,
                  onChanged: (content) {
                    _content = content;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Tags'),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTag,
                    tooltip: 'Add Tag',
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children:
                    _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                          });
                        },
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'title': _titleController.text,
                'scriptureFocus': _scriptureFocusController.text,
                'date': Timestamp.fromDate(_selectedDate),
                'content': _content.map((item) => item.toJson()).toList(),
                'tags': _tags,
              });
            }
          },
          child: Text(widget.isNew ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
