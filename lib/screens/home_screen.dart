import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'attendance_input_screen.dart';
import 'meeting_type_manager.dart';
import 'export_screen.dart';
import 'attendance_history_screen.dart';
import '../widgets/large_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<String> _getVersionString() async {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version} (${info.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Admin'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Spacer(),
            LargeButton(
              label: 'Take Attendance',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AttendanceInputScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            LargeButton(
              label: 'Manage Meeting Types',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MeetingTypeManager()),
                );
              },
            ),
            const SizedBox(height: 20),
            LargeButton(
              label: 'Export Attendance Data',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExportScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            LargeButton(
              label: 'View Past Attendance',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
                );
              },
            ),
            const Spacer(),
            FutureBuilder<String>(
              future: _getVersionString(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 20);
                return Text(
                  snapshot.data!,
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
