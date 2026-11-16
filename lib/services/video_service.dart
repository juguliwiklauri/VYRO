
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VideoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    final extension =
        videoFile.path.split('.').last.toLowerCase();

    final contentType = extension == 'mov'
        ? 'video/quicktime'
        : 'video/mp4';

    final storagePath = 'videos/${user.uid}/$videoId.$extension';
    final storageRef = _storage.ref().child(storagePath);

    try {
      final uploadTask = storageRef.putFile(
        videoFile,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask;
      final videoUrl = await snapshot.ref.getDownloadURL();

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
        await storageRef.delete();
      } catch (_) {
        // ატვირთული ფაილი შესაძლოა ჯერ არ არსებობდეს.
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
