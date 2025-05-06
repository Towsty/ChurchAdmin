import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import 'attendance_input_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  void _confirmDelete(AttendanceRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record?'),
        content: const Text('Are you sure you want to delete this attendance record?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true && record.id != null) {
      await _attendanceService.deleteRecord(record.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: StreamBuilder<List<AttendanceRecord>>(
        stream: _attendanceService.getRecordsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return const Center(child: Text('No attendance records found.'));
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final formattedDate = DateFormat('yyyy-MM-dd').format(record.date);
              final title = '${record.meetingType} on $formattedDate';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Card(
                  child: ExpansionTile(
                    title: Text(title),
                    subtitle: Row(
                      children: [
                        Text('Adults: ${record.adults}, Youth: ${record.youth}, Leaders: ${record.leaders}'),
                        if (record.notes != null && record.notes!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.note, size: 16, color: Colors.grey),
                        ],
                      ],
                    ),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (record.notes != null && record.notes!.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Notes: ${record.notes}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendanceInputScreen(recordToEdit: record),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(record),
                          ),
                        ],
                      )
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
