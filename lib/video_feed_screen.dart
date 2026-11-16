
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'comments_screen.dart';
import 'services/like_service.dart';

const Color turboYellow = Color(0xFFFFD600);

class VideoFeedScreen extends StatelessWidget {
  const VideoFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('videos')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'ვიდეოების ჩატვირთვა ვერ მოხერხდა',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: turboYellow),
            );
          }

          final videos = snapshot.data?.docs ?? [];

          if (videos.isEmpty) {
            return const Center(
              child: Text(
                'ჯერ ვიდეოები არ არის.\nიყავი პირველი!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.6,
                ),
              ),
            );
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return VideoFeedItem(
                key: ValueKey(videos[index].id),
                videoId: videos[index].id,
                data: videos[index].data(),
              );
            },
          );
        },
      ),
    );
  }
}

class VideoFeedItem extends StatefulWidget {
  final String videoId;
  final Map<String, dynamic> data;

  const VideoFeedItem({
    super.key,
    required this.videoId,
    required this.data,
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  final LikeService _likeService = LikeService();

  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final url = widget.data['videoUrl'] as String?;

    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.play();

      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    try {
      await _likeService.toggleLike(widget.videoId);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('მოწონება ვერ მოხერხდა: $error')),
      );
    }
  }

  void _openComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentsScreen(videoId: widget.videoId),
      ),
    );
  }

  Widget _actionButton({
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: icon,
        iconSize: 31,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.data['caption'] as String? ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),

        if (_hasError)
          const Center(
            child: Text(
              'ვიდეოს დაკვრა ვერ მოხერხდა',
              style: TextStyle(color: Colors.white),
            ),
          )
        else if (_controller == null ||
            !_controller!.value.isInitialized)
          const Center(
            child: CircularProgressIndicator(color: turboYellow),
          )
        else
         GestureDetector(
  onTap: () {
    final controller = _controller!;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }

    setState(() {});
  },
  onDoubleTap: _toggleLike,
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

        // ზედა და ქვედა მუქი გრადიენტი
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.25, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),

        // ზედა ლოგო და სათაური
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Text(
                    'TURBO',
                    style: TextStyle(
                      color: turboYellow,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'შენთვის',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: turboYellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // მარჯვენა ღილაკები
        Positioned(
          right: 12,
          bottom: 105,
          child: Column(
            children: [
              StreamBuilder<bool>(
                stream: _likeService.isLiked(widget.videoId),
                builder: (context, snapshot) {
                  final liked = snapshot.data ?? false;

                  return _actionButton(
                    onTap: _toggleLike,
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? Colors.redAccent : Colors.white,
                    ),
                  );
                },
              ),

              const SizedBox(height: 7),

              StreamBuilder<int>(
                stream: _likeService.likeCount(widget.videoId),
                builder: (context, snapshot) {
                  return Text(
                    '${snapshot.data ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              _actionButton(
                onTap: _openComments,
                icon: const Icon(Icons.chat_bubble_outline),
              ),

              const SizedBox(height: 7),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('videos')
                    .doc(widget.videoId)
                    .collection('comments')
                    .snapshots(),
                builder: (context, snapshot) {
                  return Text(
                    '${snapshot.data?.docs.length ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              const Icon(
                Icons.play_circle_outline,
                color: turboYellow,
                size: 35,
              ),
            ],
          ),
        ),

        // ვიდეოს აღწერა
        Positioned(
          left: 18,
          right: 85,
          bottom: 35,
          child: Text(
            caption.isEmpty ? 'TURBO ვიდეო' : caption,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
