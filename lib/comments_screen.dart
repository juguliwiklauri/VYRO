
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/comment_service.dart';

class CommentsScreen extends StatefulWidget {
  final String videoId;

  const CommentsScreen({
    super.key,
    required this.videoId,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final CommentService _service = CommentService();
  final TextEditingController _controller = TextEditingController();

  bool _sending = false;

  Future<void> _sendComment() async {
    if (_sending) return;

    setState(() => _sending = true);

    try {
      await _service.addComment(
        videoId: widget.videoId,
        text: _controller.text,
      );

      _controller.clear();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('შეცდომა: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _service.deleteComment(
        videoId: widget.videoId,
        commentId: commentId,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('წაშლა ვერ მოხერხდა: $error')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: const Text(
          'კომენტარები',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getComments(widget.videoId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'კომენტარების ჩატვირთვა ვერ მოხერხდა',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD600),
                    ),
                  );
                }

                final comments = snapshot.data?.docs ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'ჯერ კომენტარები არ არის. დაწერე პირველი!',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final doc = comments[index];
                    final data = doc.data();
                    final userId = data['userId'] as String? ?? '';
                    final username =
                        data['username'] as String? ?? 'მომხმარებელი';
                    final message = data['text'] as String? ?? '';
                    final isOwner = userId == currentUserId;

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFD600),
                        child: Icon(
                          Icons.person,
                          color: Colors.black,
                        ),
                      ),
                      title: Text(
                        username,
                        style: const TextStyle(
                          color: Color(0xFFFFD600),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        message,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: isOwner
                          ? IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white54,
                              ),
                              onPressed: () =>
                                  _deleteComment(doc.id),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 1000,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'დაწერე კომენტარი...',
                        hintStyle:
                            const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _sendComment,
                    icon: _sending
                        ? const CircularProgressIndicator(
                            color: Color(0xFFFFD600),
                          )
                        : const Icon(
                            Icons.send,
                            color: Color(0xFFFFD600),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
