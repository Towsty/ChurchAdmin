import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/church.dart';

class CreateChurchScreen extends StatefulWidget {
  const CreateChurchScreen({super.key});

  @override
  State<CreateChurchScreen> createState() => _CreateChurchScreenState();
}

class _CreateChurchScreenState extends State<CreateChurchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _zipController = TextEditingController();
  final _denominationController = TextEditingController();
  final _meetingTypeController = TextEditingController();
  bool _isSaving = false;
  List<String> _meetingTypes = [
    'Sunday Service',
    'Bible Study',
    'Prayer Meeting',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _zipController.dispose();
    _denominationController.dispose();
    _meetingTypeController.dispose();
    super.dispose();
  }

  void _addMeetingType() {
    final type = _meetingTypeController.text.trim();
    if (type.isNotEmpty && !_meetingTypes.contains(type)) {
      setState(() {
        _meetingTypes.add(type);
        _meetingTypeController.clear();
      });
    }
  }

  void _removeMeetingType(String type) {
    setState(() {
      _meetingTypes.remove(type);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated.')));
      setState(() => _isSaving = false);
      return;
    }

    final newChurch = Church(
      id: '',
      name: _nameController.text.trim(),
      zipCode: _zipController.text.trim(),
      denomination: _denominationController.text.trim(),
      createdBy: user.uid,
      createdAt: DateTime.now(),
      defaultMeetingTypes: _meetingTypes,
    );

    try {
      // PHASE 1: Core Setup
      // 1. Create the church document with meeting types included in the main document
      debugPrint('📝 Creating church document...');
      final docRef = await FirebaseFirestore.instance
          .collection('churches')
          .add(
            newChurch.toMap(),
          ); // meeting types are already included in defaultMeetingTypes

      final churchId = docRef.id;
      debugPrint('✅ Church document created with ID: $churchId');

      // 2. Update the user as admin of the church
      debugPrint('👤 Updating user as admin...');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'churchId': churchId, 'role': 'admin', 'pending': false},
      );
      debugPrint('✅ User updated as admin');

      // Navigate back to HomeScreen immediately after core setup
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Show initial success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Church "${newChurch.name}" created! Setting up additional features...',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // PHASE 2: Initialize remaining features (in the background)
      Future(() async {
        try {
          // Wait a bit longer for permissions to propagate
          await Future.delayed(const Duration(seconds: 2));

          // Initialize remaining features
          await _initializeAnnouncements(churchId);
          await _initializeMeetings(churchId, _meetingTypes.first);
          await _initializeDevotionals(churchId);
        } catch (e) {
          debugPrint('⚠️ Some features failed to initialize: $e');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error during church creation: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating church: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }

    setState(() => _isSaving = false);
  }

  Future<void> _initializeMeetingTypes(
    String churchId,
    List<String> types,
  ) async {
    debugPrint('🔄 Initializing meeting types...');
    for (final type in types) {
      try {
        await FirebaseFirestore.instance
            .collection('churches')
            .doc(churchId)
            .collection('meeting_types')
            .add({'name': type, 'createdAt': FieldValue.serverTimestamp()});
        debugPrint('✅ Added meeting type: $type');
      } catch (e) {
        debugPrint('⚠️ Failed to add meeting type: $type - $e');
      }
    }
  }

  Future<void> _initializeAnnouncements(String churchId) async {
    try {
      debugPrint('📢 Creating welcome announcement...');
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('announcements')
          .add({
            'message': 'Welcome to your new church admin portal!',
            'postedAt': FieldValue.serverTimestamp(),
          });
      debugPrint('✅ Welcome announcement created');
    } catch (e) {
      debugPrint('⚠️ Failed to create welcome announcement: $e');
    }
  }

  Future<void> _initializeMeetings(String churchId, String defaultType) async {
    try {
      debugPrint('📅 Creating welcome meeting...');
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('meetings')
          .add({
            'title': 'Launch Team Meeting',
            'date': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 3)),
            ),
            'location': 'Main Office',
            'description':
                'First planning meeting for church setup and vision casting.',
            'meetingType': defaultType,
          });
      debugPrint('✅ Welcome meeting created');
    } catch (e) {
      debugPrint('⚠️ Failed to create welcome meeting: $e');
    }
  }

  Future<void> _initializeDevotionals(String churchId) async {
    try {
      debugPrint('📖 Creating initial devotional...');
      final todayId = DateFormat('yyyyMMdd').format(DateTime.now());
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('devotionals')
          .doc(todayId)
          .set({
            'title': 'Rooted in Purpose',
            'verse': 'Jeremiah 29:11',
            'content': 'For I know the plans I have for you...',
          });
      debugPrint('✅ Initial devotional created');
    } catch (e) {
      debugPrint('⚠️ Failed to create initial devotional: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Church')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Church Name',
                  icon: Icon(Icons.church),
                ),
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  icon: Icon(Icons.location_on),
                ),
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _denominationController,
                decoration: const InputDecoration(
                  labelText: 'Denomination/Affiliation',
                  icon: Icon(Icons.people_outline),
                  hintText: 'e.g., Baptist, Catholic, Non-denominational',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Meeting Types',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _meetingTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Add Meeting Type',
                        icon: Icon(Icons.event),
                      ),
                      onFieldSubmitted: (_) => _addMeetingType(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addMeetingType,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _meetingTypes.length,
                    itemBuilder: (context, index) {
                      final type = _meetingTypes[index];
                      return ListTile(
                        title: Text(type),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeMeetingType(type),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitForm,
                  icon: const Icon(Icons.church),
                  label: Text(_isSaving ? 'Saving...' : 'Create Church'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
