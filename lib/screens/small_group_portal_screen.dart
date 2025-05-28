import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/small_group.dart';
import '../models/small_group_post.dart';
import '../services/small_group_post_service.dart';
import '../services/group_service.dart';
import '../services/role_permissions.dart';
import 'manage_group_members_screen.dart';

class SmallGroupPortalScreen extends StatefulWidget {
  final String churchId;
  final SmallGroup group;

  const SmallGroupPortalScreen({
    super.key,
    required this.churchId,
    required this.group,
  });

  @override
  State<SmallGroupPortalScreen> createState() => _SmallGroupPortalScreenState();
}

class _SmallGroupPortalScreenState extends State<SmallGroupPortalScreen> {
  final _postService = SmallGroupPostService();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String? _userRole;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) return;
      setState(() {
        _userRole = doc.data()?['role'] as String?;
        _userId = user.uid;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
    }
  }

  Future<void> _createPost() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final post = SmallGroupPost(
        id: '',
        groupId: widget.group.id,
        authorId: user.uid,
        message: _messageController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _postService.createPost(widget.churchId, post);
      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLeader = _userId == widget.group.leaderId;
    final canManageMembers =
        _userRole != null &&
        _userId != null &&
        RolePermissions.canManageSmallGroupMembers(
          _userRole!,
          _userId!,
          widget.group.leaderId,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          if (canManageMembers)
            IconButton(
              icon: const Icon(Icons.group),
              tooltip: 'Manage Members',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ManageGroupMembersScreen(
                          churchId: widget.churchId,
                          group: widget.group,
                        ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Group Info Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (widget.group.description != null &&
                      widget.group.description!.isNotEmpty)
                    Text(widget.group.description!),
                  if (widget.group.meetingTime != null)
                    Text('Meeting Time: ${widget.group.meetingTime}'),
                  if (widget.group.meetingLocation != null)
                    Text('Location: ${widget.group.meetingLocation}'),
                  Text('Members: ${widget.group.members.length}'),
                ],
              ),
            ),
          ),

          // Post Creation
          if (isLeader)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Post a message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createPost,
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Post'),
                  ),
                ],
              ),
            ),

          // Posts Stream
          Expanded(
            child: StreamBuilder<List<SmallGroupPost>>(
              stream: _postService.getGroupPosts(
                widget.churchId,
                widget.group.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!;
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(post.authorId)
                              .get(),
                      builder: (context, authorSnapshot) {
                        final authorData =
                            authorSnapshot.data?.data()
                                as Map<String, dynamic>?;
                        final firstName = authorData?['firstName'] ?? '';
                        final lastName = authorData?['lastName'] ?? '';
                        final authorName = '$firstName $lastName'.trim();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => Dialog(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        constraints: const BoxConstraints(
                                          maxWidth: 600,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        authorName,
                                                        style:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .titleLarge,
                                                      ),
                                                      Text(
                                                        DateFormat.yMMMd()
                                                            .add_jm()
                                                            .format(
                                                              post.createdAt,
                                                            ),
                                                        style:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                ),
                                              ],
                                            ),
                                            const Divider(),
                                            const SizedBox(height: 8),
                                            SelectableText(
                                              post.message,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge,
                                            ),
                                            const SizedBox(height: 16),
                                            if (post.authorId == _userId)
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () async {
                                                      final confirmed = await showDialog<
                                                        bool
                                                      >(
                                                        context: context,
                                                        builder:
                                                            (
                                                              context,
                                                            ) => AlertDialog(
                                                              title: const Text(
                                                                'Delete Post',
                                                              ),
                                                              content: const Text(
                                                                'Are you sure you want to delete this post?',
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                        false,
                                                                      ),
                                                                  child:
                                                                      const Text(
                                                                        'Cancel',
                                                                      ),
                                                                ),
                                                                TextButton(
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                        true,
                                                                      ),
                                                                  style: TextButton.styleFrom(
                                                                    foregroundColor:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                  child:
                                                                      const Text(
                                                                        'Delete',
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                      );

                                                      if (confirmed == true) {
                                                        Navigator.of(
                                                          context,
                                                        ).pop(); // Close the dialog
                                                        try {
                                                          await _postService
                                                              .deletePost(
                                                                widget.churchId,
                                                                widget.group.id,
                                                                post.id,
                                                              );
                                                          if (mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Post deleted successfully',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Error deleting post: $e',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    },
                                                    child: const Text(
                                                      'Delete Post',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                              );
                            },
                            child: ListTile(
                              title: Text(
                                authorName.isNotEmpty ? authorName : 'Unknown',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    post.message,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat.yMMMd().add_jm().format(
                                      post.createdAt,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing:
                                  post.authorId == _userId
                                      ? IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () async {
                                          final confirmed = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    'Delete Post',
                                                  ),
                                                  content: const Text(
                                                    'Are you sure you want to delete this post?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.red,
                                                          ),
                                                      child: const Text(
                                                        'Delete',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );

                                          if (confirmed == true) {
                                            try {
                                              await _postService.deletePost(
                                                widget.churchId,
                                                widget.group.id,
                                                post.id,
                                              );
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Post deleted successfully',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error deleting post: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      )
                                      : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
