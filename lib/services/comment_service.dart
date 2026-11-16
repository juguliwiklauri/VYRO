
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addComment({
    required String videoId,
    required String text,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('კომენტარის დასაწერად საჭიროა ავტორიზაცია.');
    }

    final message = text.trim();

    if (message.isEmpty || message.length > 1000) {
      throw Exception('კომენტარი უნდა იყოს 1-1000 სიმბოლო.');
    }

    final videoRef = _db.collection('videos').doc(videoId);
    final commentRef = videoRef.collection('comments').doc();
    final userRef = _db.collection('users').doc(user.uid);

    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw Exception('მომხმარებლის პროფილი ვერ მოიძებნა.');
    }

    final username = userDoc.data()?['username'] ?? 'მომხმარებელი';

    await _db.runTransaction((transaction) async {
      final video = await transaction.get(videoRef);

      if (!video.exists) {
        throw Exception('ვიდეო ვერ მოიძებნა.');
      }

      final currentCount = (video.data()?['commentsCount'] ?? 0) as int;

      transaction.set(commentRef, {
        'commentId': commentRef.id,
        'userId': user.uid,
        'username': username,
        'text': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(videoRef, {
        'commentsCount': currentCount + 1,
      });
    });
  }

  Future<void> deleteComment({
    required String videoId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('საჭიროა ავტორიზაცია.');
    }

    final videoRef = _db.collection('videos').doc(videoId);
    final commentRef = videoRef.collection('comments').doc(commentId);

    await _db.runTransaction((transaction) async {
      final comment = await transaction.get(commentRef);
      final video = await transaction.get(videoRef);

      if (!comment.exists) {
        throw Exception('კომენტარი ვერ მოიძებნა.');
      }

      if (comment.data()?['userId'] != user.uid) {
        throw Exception('შეგიძლია მხოლოდ შენი კომენტარის წაშლა.');
      }

      if (!video.exists) {
        throw Exception('ვიდეო ვერ მოიძებნა.');
      }

      final currentCount = (video.data()?['commentsCount'] ?? 0) as int;

      transaction.delete(commentRef);
      transaction.update(videoRef, {
        'commentsCount': currentCount > 0 ? currentCount - 1 : 0,
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getComments(
    String videoId,
  ) {
    return _db
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
