import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/attendance_record.dart';
import '../services/export_service.dart';
import '../services/role_permissions.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService _exportService = ExportService();
  final DateTime _initialDate = DateTime.now();
  late DateTime _selectedMonth;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _selectedMonth = _initialDate;
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      userRole = doc.data()?['role'] ?? 'Visitor';
    });
  }

  Future<void> _exportData() async {
    final snapshot = await FirebaseFirestore.instance.collection('attendance').get();

    final records = snapshot.docs.map((doc) {
      final data = doc.data();
      return AttendanceRecord.fromMap(data, doc.id);
    }).toList();

    final selectedRecords = records.where((r) =>
    r.date.year == _selectedMonth.year &&
        r.date.month == _selectedMonth.month).toList();

    if (selectedRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No records found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}')),
      );
      return;
    }

    final filename = 'attendance_${DateFormat('yyyy_MM').format(_selectedMonth)}';
    final file = await _exportService.exportToCsv(selectedRecords, filename);

    await Share.shareXFiles([XFile(file.path)], text: 'Attendance Data Export');
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select any day in the month to export',
    );
    if (picked != null) {
      setState(() => _selectedMonth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!RolePermissions.canExportAttendance(userRole!)) {
      return const Scaffold(
        body: Center(child: Text('Access denied: insufficient permissions.')),
      );
    }

    final displayMonth = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Attendance Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextButton.icon(
              onPressed: _pickMonth,
              icon: const Icon(Icons.calendar_today),
              label: Text('Month: $displayMonth'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export & Share CSV'),
              onPressed: _exportData,
            ),
          ],
        ),
      ),
    );
  }
}
