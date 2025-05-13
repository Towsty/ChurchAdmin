import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/meeting_type_service.dart';
import '../services/role_permissions.dart';

class MeetingTypeManager extends StatefulWidget {
  const MeetingTypeManager({super.key});

  @override
  State<MeetingTypeManager> createState() => _MeetingTypeManagerState();
}

class _MeetingTypeManagerState extends State<MeetingTypeManager> {
  final MeetingTypeService _service = MeetingTypeService();
  final TextEditingController _controller = TextEditingController();
  String? userRole;

  @override
  void initState() {
    super.initState();
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

  void _addMeetingType() {
    final newType = _controller.text.trim();
    if (newType.isNotEmpty) {
      _service.addMeetingType(newType);
      _controller.clear();
    }
  }

  void _removeMeetingType(String type) {
    _service.deleteMeetingType(type);
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!RolePermissions.canManageMeetingTypes(userRole!)) {
      return const Scaffold(
        body: Center(child: Text('Access denied: Admins only.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Meeting Types'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'New Meeting Type',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addMeetingType,
                ),
              ),
              onSubmitted: (_) => _addMeetingType(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _service.getMeetingTypesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final types = snapshot.data!;
                  if (types.isEmpty) {
                    return const Center(child: Text('No meeting types found.'));
                  }

                  return ListView.builder(
                    itemCount: types.length,
                    itemBuilder: (context, index) {
                      final type = types[index];
                      return ListTile(
                        title: Text(type),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeMeetingType(type),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}