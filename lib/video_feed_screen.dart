
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'services/like_service.dart';

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
              child: CircularProgressIndicator(
                color: Color(0xFFFFD600),
              ),
            );
          }

          final videos = snapshot.data?.docs ?? [];

          if (videos.isEmpty) {
            return const Center(
              child: Text(
                'ჯერ ვიდეოები არ არის. იყავი პირველი!',
                style: TextStyle(color: Colors.white),
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

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
    );

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
            child: CircularProgressIndicator(
              color: Color(0xFFFFD600),
            ),
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
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

        Positioned(
          left: 16,
          right: 80,
          bottom: 35,
          child: Text(
            caption,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 8),
              ],
            ),
          ),
        ),

        Positioned(
          right: 16,
          bottom: 45,
          child: Column(
            children: [
              StreamBuilder<bool>(
                stream: _likeService.isLiked(widget.videoId),
                builder: (context, snapshot) {
                  final liked = snapshot.data ?? false;

                  return IconButton(
                    onPressed: _toggleLike,
                    iconSize: 36,
                    icon: Icon(
                      liked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: liked
                          ? Colors.red
                          : Colors.white,
                    ),
                  );
                },
              ),

              StreamBuilder<int>(
                stream: _likeService.likeCount(widget.videoId),
                builder: (context, snapshot) {
                  return Text(
                    '${snapshot.data ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
