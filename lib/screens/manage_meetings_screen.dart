import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/role_permissions.dart';
import '../services/meeting_type_service.dart';

class ManageMeetingsScreen extends StatefulWidget {
  final String churchId;

  const ManageMeetingsScreen({super.key, required this.churchId});

  @override
  State<ManageMeetingsScreen> createState() => _ManageMeetingsScreenState();
}

class _ManageMeetingsScreenState extends State<ManageMeetingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final MeetingTypeService _meetingTypeService = MeetingTypeService();

  DateTime _selectedDate = DateTime.now();
  String? _selectedMeetingType;
  List<String> _meetingTypes = [];
  bool _isLoading = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadMeetingTypes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (mounted) {
      setState(() {
        _userRole = doc.data()?['role'] as String?;
      });
    }
  }

  Future<void> _loadMeetingTypes() async {
    final types = await _meetingTypeService.getMeetingTypes();
    if (mounted) {
      setState(() {
        _meetingTypes = types.map((t) => t['name'].toString()).toList();
      });
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate() || _selectedMeetingType == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId)
          .collection('meetings')
          .add({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'location': _locationController.text.trim(),
            'date': Timestamp.fromDate(_selectedDate),
            'meetingType': _selectedMeetingType,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating meeting: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteMeeting(String meetingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId)
          .collection('meetings')
          .doc(meetingId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting meeting: $e')));
      }
    }
  }

  Future<void> _editMeeting(
    String meetingId,
    Map<String, dynamic> currentData,
  ) async {
    _titleController.text = currentData['title'] ?? '';
    _descriptionController.text = currentData['description'] ?? '';
    _locationController.text = currentData['location'] ?? '';
    _selectedMeetingType = currentData['meetingType'];
    _selectedDate = (currentData['date'] as Timestamp).toDate();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Meeting'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator:
                          (value) =>
                              value?.trim().isEmpty ?? true
                                  ? 'Title is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMeetingType,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Type',
                      ),
                      items:
                          _meetingTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) =>
                              setState(() => _selectedMeetingType = value),
                      validator:
                          (value) =>
                              value == null
                                  ? 'Please select a meeting type'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date and Time'),
                      subtitle: Text(
                        '${_selectedDate.toLocal().toString().split('.')[0]}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDate,
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
                onPressed: () async {
                  if (!_formKey.currentState!.validate() ||
                      _selectedMeetingType == null) {
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('churches')
                        .doc(widget.churchId)
                        .collection('meetings')
                        .doc(meetingId)
                        .update({
                          'title': _titleController.text.trim(),
                          'description': _descriptionController.text.trim(),
                          'location': _locationController.text.trim(),
                          'date': Timestamp.fromDate(_selectedDate),
                          'meetingType': _selectedMeetingType,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Meeting updated successfully'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating meeting: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!RolePermissions.canManageMeetingTypes(_userRole!)) {
      return const Scaffold(
        body: Center(child: Text('Access denied: Admin only area')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Meetings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Create Meeting'),
                      content: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                ),
                                validator:
                                    (value) =>
                                        value?.trim().isEmpty ?? true
                                            ? 'Title is required'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location',
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedMeetingType,
                                decoration: const InputDecoration(
                                  labelText: 'Meeting Type',
                                ),
                                items:
                                    _meetingTypes
                                        .map(
                                          (type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (value) => setState(
                                      () => _selectedMeetingType = value,
                                    ),
                                validator:
                                    (value) =>
                                        value == null
                                            ? 'Please select a meeting type'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                title: const Text('Date and Time'),
                                subtitle: Text(
                                  '${_selectedDate.toLocal().toString().split('.')[0]}',
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: _pickDate,
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
                          onPressed: _isLoading ? null : _createMeeting,
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Create'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('churches')
                .doc(widget.churchId)
                .collection('meetings')
                .orderBy('date')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final meetings = snapshot.data!.docs;

          if (meetings.isEmpty) {
            return const Center(child: Text('No meetings found'));
          }

          return ListView.builder(
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              final data = meeting.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['title'] ?? 'Untitled'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${data['meetingType']}'),
                      Text('Date: ${date.toLocal().toString().split('.')[0]}'),
                      if (data['location']?.isNotEmpty ?? false)
                        Text('Location: ${data['location']}'),
                      if (data['description']?.isNotEmpty ?? false)
                        Text('Description: ${data['description']}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editMeeting(meeting.id, data);
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Delete Meeting'),
                                content: const Text(
                                  'Are you sure you want to delete this meeting?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteMeeting(meeting.id);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                        );
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
