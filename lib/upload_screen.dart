
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/video_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final VideoService _videoService = VideoService();
  final TextEditingController _captionController =
      TextEditingController();

  File? _videoFile;
  bool _uploading = false;

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile == null || !mounted) return;

      setState(() {
        _videoFile = File(pickedFile.path);
      });
    } catch (error) {
      _showMessage('ვიდეოს არჩევა ვერ მოხერხდა: $error');
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) {
      _showMessage('ჯერ აირჩიე ვიდეო.');
      return;
    }

    if (_uploading) return;

    setState(() => _uploading = true);

    try {
      await _videoService.uploadVideo(
        videoFile: _videoFile!,
        caption: _captionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ვიდეო წარმატებით აიტვირთა!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      _showMessage('ატვირთვა ვერ მოხერხდა: $error');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        foregroundColor: Colors.white,
        title: const Text('ვიდეოს ატვირთვა'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _uploading ? null : _pickVideo,
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD600),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.video_library_outlined,
                        size: 60,
                        color: Color(0xFFFFD600),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _videoFile == null
                            ? 'აირჩიე ვიდეო გალერეიდან'
                            : 'ვიდეო არჩეულია',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                      if (_videoFile != null) ...[
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _captionController,
                maxLength: 500,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'დაუწერე ვიდეოს აღწერა...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploading ? null : _uploadVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD600),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _uploading
                    ? const CircularProgressIndicator(
                        color: Colors.black,
                      )
                    : const Text(
                        'ვიდეოს ატვირთვა',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
