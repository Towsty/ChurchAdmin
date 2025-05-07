import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

import '../models/attendance_record.dart';

class ExportService {
  Future<File> exportToCsv(List<AttendanceRecord> records, String filename) async {
    final rows = <List<String>>[];

    // Header row
    rows.add(['Date', 'Meeting Type', 'Adults', 'Youth', 'Leaders', 'Notes']);

    // Data rows
    for (var record in records) {
      rows.add([
        record.date.toIso8601String(),
        record.meetingType,
        record.adults.toString(),
        record.youth.toString(),
        record.leaders.toString(),
        record.notes ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$filename.csv';
    final file = File(path);

    return file.writeAsString(csv);
  }
}
