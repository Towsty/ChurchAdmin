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
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchChurches() async {
    final search = _searchController.text.trim();
    if (search.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      QuerySnapshot? results;

      // Check if input is a ZIP code (5 digits)
      if (search.length == 5 && int.tryParse(search) != null) {
        results =
            await FirebaseFirestore.instance
                .collection('churches')
                .where('zipCode', isEqualTo: search)
                .get();
      } else {
        // Search by name
        results =
            await FirebaseFirestore.instance
                .collection('churches')
                .where('name', isGreaterThanOrEqualTo: search.toUpperCase())
                .where('name', isLessThan: search.toUpperCase() + 'z')
                .get();
      }

      setState(() {
        _results = results?.docs ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching churches: $e';
        _isLoading = false;
        _results = [];
      });
    }
  }

  Future<void> _requestToJoin(DocumentSnapshot church) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to join a church')),
        );
        return;
      }

      // Get user's display name from their profile
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final userName =
          userDoc.data()?['name'] ??
          user.displayName ??
          user.email?.split('@')[0] ??
          'Anonymous';

      // Create join request
      await FirebaseFirestore.instance
          .collection('churches')
          .doc(church.id)
          .collection('joinRequests')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'userName': userName,
            'userEmail': user.email,
            'requestedAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          });

      // Update user's pending status
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'pendingChurchId': church.id, 'pendingChurchName': church['name']},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join request sent to ${church['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error sending join request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending join request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Church')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name or ZIP code',
                hintText: 'Enter church name or 5-digit ZIP code',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchChurches();
                  },
                ),
              ),
              onChanged: (_) => _searchChurches(),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_results.isEmpty && _searchController.text.isNotEmpty)
              const Center(
                child: Text(
                  'No churches found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final church = _results[index];
                    final data = church.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          data['name'] ?? 'Unnamed Church',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('ZIP: ${data['zipCode'] ?? 'N/A'}'),
                        trailing: ElevatedButton(
                          onPressed: () => _requestToJoin(church),
                          child: const Text('Request to Join'),
                        ),
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
