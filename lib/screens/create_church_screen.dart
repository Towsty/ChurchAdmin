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
  bool _isSaving = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User not authenticated.'),
      ));
      setState(() => _isSaving = false);
      return;
    }

    final newChurch = Church(
      id: '',
      name: _nameController.text.trim(),
      zipCode: _zipController.text.trim(),
      createdBy: user.uid,
      createdAt: DateTime.now(),
    );

    try {
      // 1. Create the church document
      final docRef = await FirebaseFirestore.instance
          .collection('churches')
          .add(newChurch.toMap());

      final churchId = docRef.id;

      // 2. Update the user as admin of the church
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'churchId': churchId,
        'role': 'admin',
        'pending': false,
      });

      // 3. Seed welcome announcement
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('announcements')
          .add({
        'message': 'Welcome to your new church admin portal!',
        'postedAt': FieldValue.serverTimestamp(),
      });

      // 4. Seed welcome meeting
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('meetings')
          .add({
        'title': 'Launch Team Meeting',
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'location': 'Main Office',
        'description': 'First planning meeting for church setup and vision casting.',
      });

      // 5. Seed devotional
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

      // 6. Navigate back to HomeScreen
      Navigator.of(context).popUntil((route) => route.isFirst);

      // 7. Show confirmation
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Church "${newChurch.name}" created and you are now an Admin.'),
        ));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isSaving = false);
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
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Church Name'),
                validator: (val) =>
                val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                decoration: const InputDecoration(labelText: 'ZIP Code'),
                validator: (val) =>
                val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitForm,
                icon: const Icon(Icons.church),
                label: Text(_isSaving ? 'Saving...' : 'Create Church'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
