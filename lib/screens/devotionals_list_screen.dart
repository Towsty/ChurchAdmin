import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/devotional.dart';
import '../services/role_permissions.dart';
import 'create_devotional_screen.dart';

class DevotionalsListScreen extends StatefulWidget {
  final String churchId;
  final String churchName;

  const DevotionalsListScreen({
    super.key,
    required this.churchId,
    required this.churchName,
  });

  @override
  State<DevotionalsListScreen> createState() => _DevotionalsListScreenState();
}

class _DevotionalsListScreenState extends State<DevotionalsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  bool _showArchived = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.churchName} Devotionals'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      CreateDevotionalScreen(churchId: widget.churchId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
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
                            setState(() => _selectedFilter = 'all');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Today'),
                        selected: _selectedFilter == 'today',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = 'today');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('This Week'),
                        selected: _selectedFilter == 'week',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = 'week');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Past'),
                        selected: _selectedFilter == 'past',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = 'past');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Future'),
                        selected: _selectedFilter == 'future',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = 'future');
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
                        case 'past':
                          return date.isBefore(DateTime.now());
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
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CreateDevotionalScreen(
                                          churchId: widget.churchId,
                                          devotional: Devotional.fromFirestore(
                                            doc,
                                          ),
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => CreateDevotionalScreen(
                                    churchId: widget.churchId,
                                    devotional: Devotional.fromFirestore(doc),
                                  ),
                            ),
                          );
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
