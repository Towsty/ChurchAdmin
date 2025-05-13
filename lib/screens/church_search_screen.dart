import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChurchSearchScreen extends StatefulWidget {
  const ChurchSearchScreen({super.key});

  @override
  State<ChurchSearchScreen> createState() => _ChurchSearchScreenState();
}

class _ChurchSearchScreenState extends State<ChurchSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _results = [];
  bool _isLoading = false;

  String? _requestedChurchId;
  Timestamp? _requestedAtTimestamp;
  String? _currentChurchId;

  @override
  void initState() {
    super.initState();
    _loadUserJoinStatus();
  }

  Future<void> _loadUserJoinStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (data != null) {
      setState(() {
        _currentChurchId = data['churchId'];
        _requestedChurchId = data['joinRequest']?['churchId'];
        _requestedAtTimestamp = data['joinRequest']?['requestedAt'];
      });
    }
  }

  void _searchChurches() async {
    final search = _searchController.text.trim();
    if (search.isEmpty) return;

    setState(() => _isLoading = true);

    final nameQuery = await FirebaseFirestore.instance
        .collection('churches')
        .where('name', isGreaterThanOrEqualTo: search)
        .where('name', isLessThanOrEqualTo: '$search\uf8ff')
        .get();

    final zipQuery = await FirebaseFirestore.instance
        .collection('churches')
        .where('zipCode', isEqualTo: search)
        .get();

    final allResults = {
      ...nameQuery.docs,
      ...zipQuery.docs,
    }.toList();

    setState(() {
      _results = allResults;
      _isLoading = false;
    });
  }

  Future<void> _requestJoin(DocumentSnapshot church) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final churchId = church.id;

    final timestamp = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'joinRequest': {
        'churchId': churchId,
        'requestedAt': timestamp,
      }
    });

    await FirebaseFirestore.instance
        .collection('churches')
        .doc(churchId)
        .collection('joinRequests')
        .doc(userId)
        .set({
      'userId': userId,
      'requestedAt': timestamp,
    });

    _loadUserJoinStatus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join request sent to ${church['name']}')),
      );
    }
  }

  Future<void> _cancelJoinRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _requestedChurchId == null) return;

    final userId = user.uid;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'joinRequest': FieldValue.delete(),
    });

    await FirebaseFirestore.instance
        .collection('churches')
        .doc(_requestedChurchId)
        .collection('joinRequests')
        .doc(userId)
        .delete();

    _loadUserJoinStatus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request cancelled.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final requestedAt = _requestedAtTimestamp?.toDate();
    final canCancel = requestedAt != null && now.difference(requestedAt).inSeconds >= 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Find Your Church')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name or ZIP',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchChurches,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final doc = _results[index];
                    final hasRequested = _requestedChurchId == doc.id;
                    final isInChurch = _currentChurchId != null;

                    return ListTile(
                      title: Text(doc['name']),
                      subtitle: Text('ZIP: ${doc['zipCode']}'),
                      trailing: isInChurch
                          ? const Text('Already Joined', style: TextStyle(color: Colors.grey))
                          : hasRequested
                          ? canCancel
                          ? ElevatedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: _cancelJoinRequest,
                      )
                          : const Text('Requested', style: TextStyle(color: Colors.grey))
                          : ElevatedButton(
                        onPressed: () => _requestJoin(doc),
                        child: const Text('Request'),
                      ),
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
