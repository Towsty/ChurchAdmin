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

  @override
  void initState() {
    super.initState();
    _loadUserJoinRequest();
  }

  void _loadUserJoinRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['joinRequest'] != null) {
      setState(() {
        _requestedChurchId = data['joinRequest']['churchId'];
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

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'joinRequest': {
        'churchId': churchId,
        'requestedAt': FieldValue.serverTimestamp(),
      }
    });

    await FirebaseFirestore.instance
        .collection('churches')
        .doc(churchId)
        .collection('joinRequests')
        .doc(userId)
        .set({
      'userId': userId,
      'requestedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _requestedChurchId = churchId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join request sent to ${church['name']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

                    return ListTile(
                      title: Text(doc['name']),
                      subtitle: Text('ZIP: ${doc['zipCode']}'),
                      trailing: hasRequested
                          ? const Text('Requested', style: TextStyle(color: Colors.grey))
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
