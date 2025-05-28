import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/profile_service.dart';
import '../services/group_service.dart';
import '../services/image_compression_service.dart';
import '../screens/manage_small_groups_screen.dart';
import '../screens/manage_communication_groups_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import '../services/notification_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';
import '../widgets/loading_overlay.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  String? churchName;
  File? _profileImage;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  List<String> _smallGroups = [];
  List<String> _communicationGroups = [];
  final _profileService = ProfileService();
  final _groupService = GroupService();
  final _notificationService = NotificationService();
  bool _isLoading = true;
  final _authService = AuthService();

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;
  String? _error;

  // Add validation methods
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final profile = await _profileService.getProfile(user!.uid);

      if (!mounted) return;

      setState(() {
        userData = profile;
        // Handle first and last name
        if (profile != null) {
          // Check for old name format
          if (profile['name'] != null &&
              profile['firstName'] == null &&
              profile['lastName'] == null) {
            final nameParts = profile['name'].toString().split(' ');
            _firstNameController.text = nameParts.first;
            _lastNameController.text =
                nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          } else {
            _firstNameController.text = profile['firstName'] ?? '';
            _lastNameController.text = profile['lastName'] ?? '';
          }
          _emailController.text = profile['email'] ?? '';
        }

        // Format the phone number if it exists
        if (userData?['phone'] != null && userData!['phone'].isNotEmpty) {
          final digitsOnly = userData!['phone'].replaceAll(RegExp(r'\D'), '');
          if (digitsOnly.length == 10) {
            _phoneMaskFormatter.formatEditUpdate(
              TextEditingValue(text: ''),
              TextEditingValue(text: digitsOnly),
            );
            _phoneController.text = _phoneMaskFormatter.getMaskedText();
          } else {
            _phoneController.text = userData!['phone'];
          }
        } else {
          _phoneController.text = '';
        }
        _addressController.text = userData?['address'] ?? '';
        _smallGroups = List<String>.from(userData?['smallGroups'] ?? []);
        _communicationGroups = List<String>.from(
          userData?['communicationGroups'] ?? [],
        );
      });

      // Check profile completion and create notification if needed
      if (profile != null) {
        await _notificationService.checkProfileCompletion(user!.uid, profile);
      }

      if (userData?['churchId'] != null) {
        final churchDoc =
            await FirebaseFirestore.instance
                .collection('churches')
                .doc(userData!['churchId'])
                .get();

        if (!mounted) return;

        setState(() {
          churchName = churchDoc.data()?['name'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Convert XFile to File
        final File imageFile = File(pickedImage.path);

        // Compress the image using the service
        final File? compressedFile =
            await ImageCompressionService.compressImage(imageFile);

        if (compressedFile == null) {
          throw Exception('Failed to process image');
        }

        // Generate a unique filename
        final String fileName =
            'profile_${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child(fileName);

        // Upload the file
        final UploadTask uploadTask = storageRef.putFile(
          compressedFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Wait for the upload to complete and get the download URL
        final TaskSnapshot taskSnapshot = await uploadTask;
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        // Update the user's profile in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'photoUrl': downloadUrl});

        // Update the local state
        setState(() {
          userData = {...?userData, 'photoUrl': downloadUrl};
          _profileImage = compressedFile;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully')),
        );
      } catch (e) {
        print('Error uploading image: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile photo: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _authService.updateProfile(
        uid: user.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      _loadUserData(); // Reload the profile data
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firstName = userData?['firstName'] as String? ?? '';
    final lastName = userData?['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final userName =
        fullName.isNotEmpty
            ? fullName
            : userData?['name'] as String? ??
                user?.displayName ??
                user?.email?.split('@')[0] ??
                'User';
    final email = user?.email ?? 'No email provided';
    final role = (userData?['role'] ?? 'visitor').toString();
    final capitalizedRole = role[0].toUpperCase() + role.substring(1);
    final photoUrl = userData?['photoUrl'];

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Loading profile...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed:
                  _isSaving
                      ? null
                      : () {
                        if (_isEditing) {
                          _saveProfile();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            photoUrl != null
                                ? NetworkImage(photoUrl) as ImageProvider
                                : _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                        child:
                            photoUrl == null && _profileImage == null
                                ? Text(
                                  userName.substring(0, 2).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                )
                                : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'First Name',
                                    icon: Icon(Icons.person),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Last Name',
                                    icon: Icon(Icons.person_outline),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                ),
                              ),
                            ],
                          ),
                        ] else
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'Name',
                            value: userName,
                          ),
                        const Divider(),
                        _buildInfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: email,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          icon: Icons.badge,
                          label: 'Role',
                          value: capitalizedRole,
                        ),
                        if (churchName != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            icon: Icons.church,
                            label: 'Church',
                            value: churchName!,
                          ),
                        ],
                        const Divider(),
                        _buildEditableField(
                          icon: Icons.phone,
                          label: 'Phone',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                          inputFormatters: [_phoneMaskFormatter],
                        ),
                        const Divider(),
                        _buildEditableField(
                          icon: Icons.location_on,
                          label: 'Address',
                          controller: _addressController,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Small Groups',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isEditing &&
                                (role.toLowerCase() == 'admin' ||
                                    role.toLowerCase() == 'leader'))
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ManageSmallGroupsScreen(
                                            churchId: userData!['churchId'],
                                          ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_smallGroups.isEmpty)
                          const Text('No small groups joined')
                        else
                          Wrap(
                            spacing: 8,
                            children:
                                _smallGroups
                                    .map(
                                      (group) => Chip(
                                        label: Text(group),
                                        onDeleted:
                                            (_isEditing &&
                                                    (role.toLowerCase() ==
                                                            'admin' ||
                                                        role.toLowerCase() ==
                                                            'leader'))
                                                ? () {
                                                  // TODO: Remove from small group
                                                }
                                                : null,
                                      ),
                                    )
                                    .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Communication Groups',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isEditing)
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              ManageCommunicationGroupsScreen(
                                                churchId: userData!['churchId'],
                                              ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_communicationGroups.isEmpty)
                          const Text('No communication groups joined')
                        else
                          Wrap(
                            spacing: 8,
                            children:
                                _communicationGroups
                                    .map(
                                      (group) => Chip(
                                        label: Text(group),
                                        onDeleted:
                                            _isEditing
                                                ? () {
                                                  // TODO: Remove from communication group
                                                }
                                                : null,
                                      ),
                                    )
                                    .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (kDebugMode)
                  ElevatedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await NotificationService().createNotification(
                          userId: user.uid,
                          title: 'Test Notification',
                          message: 'This is a test notification.',
                          type: 'test',
                        );
                      }
                    },
                    child: Text('Create Test Notification'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                _isEditing
                    ? TextFormField(
                      controller: controller,
                      keyboardType: keyboardType,
                      maxLines: maxLines,
                      validator: validator,
                      inputFormatters: inputFormatters,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    )
                    : Text(
                      controller.text.isEmpty
                          ? 'Not provided'
                          : controller.text,
                      style: const TextStyle(fontSize: 16),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
