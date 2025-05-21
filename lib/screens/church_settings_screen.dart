import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/role_permissions.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ChurchSettingsScreen extends StatefulWidget {
  final String churchId;

  const ChurchSettingsScreen({super.key, required this.churchId});

  @override
  State<ChurchSettingsScreen> createState() => _ChurchSettingsScreenState();
}

class _ChurchSettingsScreenState extends State<ChurchSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _meetingTimesController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _denominationController = TextEditingController();
  bool _isLoading = true;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadChurchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _meetingTimesController.dispose();
    _contactEmailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _denominationController.dispose();
    super.dispose();
  }

  Future<void> _loadChurchData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('churches')
              .doc(widget.churchId)
              .get();

      final data = doc.data();
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _meetingTimesController.text = data['meetingTimes'] ?? '';
          _contactEmailController.text = data['contactEmail'] ?? '';
          _addressController.text = data['address'] ?? '';

          // Format the phone number if it exists
          if (data['phone'] != null && data['phone'].isNotEmpty) {
            final digitsOnly = data['phone'].replaceAll(RegExp(r'\D'), '');
            if (digitsOnly.length == 10) {
              _phoneMaskFormatter.formatEditUpdate(
                TextEditingValue(text: ''),
                TextEditingValue(text: digitsOnly),
              );
              _phoneController.text = _phoneMaskFormatter.getMaskedText();
            } else {
              _phoneController.text = data['phone'];
            }
          } else {
            _phoneController.text = '';
          }

          _websiteController.text = data['website'] ?? '';
          _denominationController.text = data['denomination'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading church data: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Get the unformatted phone number (just digits)
      final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');

      await FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.churchId)
          .update({
            'name': _nameController.text.trim(),
            'meetingTimes': _meetingTimesController.text.trim(),
            'contactEmail': _contactEmailController.text.trim(),
            'address': _addressController.text.trim(),
            'phone': phoneNumber,
            'website': _websiteController.text.trim(),
            'denomination': _denominationController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Church settings updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating church settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Settings'),
        actions: [
          TextButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: 'Basic Information',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Church Name',
                    icon: Icon(Icons.church),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Church name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _denominationController,
                  decoration: const InputDecoration(
                    labelText: 'Denomination/Affiliation',
                    icon: Icon(Icons.people_outline),
                    hintText: 'e.g., Baptist, Catholic, Non-denominational',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _meetingTimesController,
                  decoration: const InputDecoration(
                    labelText: 'Meeting Times',
                    icon: Icon(Icons.schedule),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'Contact Information',
              children: [
                TextFormField(
                  controller: _contactEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    icon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.trim().isNotEmpty ?? false) {
                      if (!value!.contains('@')) {
                        return 'Please enter a valid email';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    icon: Icon(Icons.phone),
                    hintText: '(555) 555-5555',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_phoneMaskFormatter],
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    icon: Icon(Icons.language),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: 'Location',
              children: [
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    icon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
