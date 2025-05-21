import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/devotional.dart';
import '../models/formatted_text.dart';
import '../components/custom_text_editor.dart';

class CreateDevotionalScreen extends StatefulWidget {
  final String churchId;
  final Devotional?
  devotional; // If provided, we're editing an existing devotional

  const CreateDevotionalScreen({
    super.key,
    required this.churchId,
    this.devotional,
  });

  @override
  State<CreateDevotionalScreen> createState() => _CreateDevotionalScreenState();
}

class _CreateDevotionalScreenState extends State<CreateDevotionalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _scriptureFocusController;
  late DateTime _selectedDate;
  late List<FormattedText> _content;
  late List<String> _tags;
  final TextEditingController _tagController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.devotional?.title ?? '',
    );
    _scriptureFocusController = TextEditingController(
      text: widget.devotional?.scriptureFocus ?? '',
    );
    _selectedDate = widget.devotional?.date ?? DateTime.now();
    _content = List.from(widget.devotional?.content ?? []);
    _tags = List.from(widget.devotional?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scriptureFocusController.dispose();
    _tagController.dispose();
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
    final tag = _tagController.text.trim().toUpperCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _saveDevotional() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final devotionalRef = FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId)
          .collection('devotionals')
          .doc(widget.devotional?.id);

      final now = DateTime.now();
      final data = {
        'title': _titleController.text,
        'scriptureFocus': _scriptureFocusController.text,
        'content': _content.map((item) => item.toJson()).toList(),
        'tags': _tags,
        'date': Timestamp.fromDate(_selectedDate),
        'updatedAt': Timestamp.fromDate(now),
        'isArchived': false,
      };

      if (widget.devotional == null) {
        data['createdAt'] = Timestamp.fromDate(now);
      }

      await devotionalRef.set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.devotional == null
                  ? 'Devotional created successfully'
                  : 'Devotional updated successfully',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.devotional == null ? 'Create Devotional' : 'Edit Devotional',
        ),
        actions: [
          if (!_isSaving)
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: _saveDevotional,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
              title: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
              tileColor: Theme.of(context).colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Content',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
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
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Add Tag',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                  tooltip: 'Add Tag',
                ),
              ],
            ),
            const SizedBox(height: 8),
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
    );
  }
}
