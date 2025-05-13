import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/role_permissions.dart';
import '../widgets/attendance_row.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import '../services/meeting_type_service.dart';

class AttendanceInputScreen extends StatefulWidget {
  final AttendanceRecord? recordToEdit;

  const AttendanceInputScreen({super.key, this.recordToEdit});

  @override
  State<AttendanceInputScreen> createState() => _AttendanceInputScreenState();
}

class _AttendanceInputScreenState extends State<AttendanceInputScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final MeetingTypeService _meetingTypeService = MeetingTypeService();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedMeeting;
  List<String> _meetingTypes = [];

  int adultCount = 0;
  int youthCount = 0;
  int leaderCount = 0;

  bool get isEditMode => widget.recordToEdit != null;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadMeetingTypes();

    if (isEditMode) {
      final record = widget.recordToEdit!;
      _selectedDate = record.date;
      _selectedMeeting = record.meetingType;
      adultCount = record.adults;
      youthCount = record.youth;
      leaderCount = record.leaders;
      _notesController.text = record.notes ?? '';
    }
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      userRole = userDoc.data()?['role'] ?? 'Visitor';
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetingTypes() async {
    final types = await _meetingTypeService.getMeetingTypes();
    final currentMeeting = widget.recordToEdit?.meetingType;

    setState(() {
      _meetingTypes = types;

      if (currentMeeting != null && !_meetingTypes.contains(currentMeeting)) {
        _meetingTypes.add(currentMeeting);
      }
    });
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_selectedMeeting == null) return;

    try {
      final record = AttendanceRecord(
        id: widget.recordToEdit?.id,
        date: _selectedDate,
        meetingType: _selectedMeeting!,
        adults: adultCount,
        youth: youthCount,
        leaders: leaderCount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (isEditMode && record.id != null) {
        await _attendanceService.updateRecord(record);
      } else {
        await _attendanceService.saveRecord(record);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditMode ? 'Attendance updated!' : 'Attendance saved!'),
              const SizedBox(height: 8),
              const LinearProgressIndicator(value: null),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error during submit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!RolePermissions.canTakeAttendance(userRole!)) {
      return const Scaffold(
        body: Center(child: Text('Access denied: insufficient permissions.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Attendance' : 'Take Attendance'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: _pickDate,
                    child: Text('Date: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedMeeting,
                      hint: const Text('Select Meeting Type'),
                      onChanged: (val) => setState(() => _selectedMeeting = val),
                      items: _meetingTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedMeeting != null) ...[
                Center(
                  child: Text(
                    '$_selectedMeeting on ${_selectedDate.toLocal().toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 20),
                AttendanceRow(
                  label: 'Adults',
                  count: adultCount,
                  onChanged: (val) => setState(() => adultCount = val),
                ),
                const SizedBox(height: 10),
                AttendanceRow(
                  label: 'Youth',
                  count: youthCount,
                  onChanged: (val) => setState(() => youthCount = val),
                ),
                const SizedBox(height: 10),
                AttendanceRow(
                  label: 'Leaders',
                  count: leaderCount,
                  onChanged: (val) => setState(() => leaderCount = val),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: Icon(isEditMode ? Icons.check : Icons.save),
                  label: Text(isEditMode ? 'Update' : 'Submit'),
                  onPressed: _submitForm,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}