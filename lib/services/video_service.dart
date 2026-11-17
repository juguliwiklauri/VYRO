
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadVideo({
    required File videoFile,
    required String caption,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('ვიდეოს ასატვირთად საჭიროა ავტორიზაცია.');
    }

    if (!await videoFile.exists()) {
      throw Exception('ვიდეოფაილი ვერ მოიძებნა.');
    }

    if (await videoFile.length() == 0) {
      throw Exception('ვიდეოფაილი ცარიელია.');
    }

    final videoId = _db.collection('videos').doc().id;
    final extension = videoFile.path.split('.').last.toLowerCase();

    final contentType = extension == 'mov'
        ? 'video/quicktime'
        : 'video/mp4';

    final storagePath = '${user.uid}/$videoId.$extension';

    try {
      await _supabase.storage.from('videos').upload(
        storagePath,
        videoFile,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      final videoUrl = _supabase.storage
          .from('videos')
          .getPublicUrl(storagePath);

      await _db.collection('videos').doc(videoId).set({
        'videoId': videoId,
        'userId': user.uid,
        'caption': caption.trim(),
        'videoUrl': videoUrl,
        'storagePath': storagePath,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'viewsCount': 0,
      });

      return videoId;
    } catch (error) {
      try {
        await _supabase.storage.from('videos').remove([storagePath]);
      } catch (_) {
        // ფაილი შესაძლოა ჯერ არ ატვირთულა.
      }

      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getVideos() {
    return _db
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
