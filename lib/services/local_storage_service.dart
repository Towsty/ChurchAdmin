import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';

class LocalStorageService {
  static const _key = 'attendanceRecords';

  Future<List<AttendanceRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data
        .map((jsonStr) => AttendanceRecord.fromJson(json.decode(jsonStr)))
        .toList();
  }

  Future<void> saveRecord(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    records.add(record);
    final encoded =
    records.map((r) => json.encode(r.toLocalJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
