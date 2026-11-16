
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
    final userRef = _db.collection('users').doc(user.uid);

    final videoDoc = await videoRef.get();

    if (!videoDoc.exists) {
      throw Exception('ვიდეო ვერ მოიძებნა.');
    }

    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw Exception('მომხმარებლის პროფილი ვერ მოიძებნა.');
    }

    final username =
        userDoc.data()?['username'] ?? 'მომხმარებელი';

    final commentRef = videoRef.collection('comments').doc();

    await commentRef.set({
      'commentId': commentRef.id,
      'userId': user.uid,
      'username': username,
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
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

    final commentRef = _db
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(commentId);

    final commentDoc = await commentRef.get();

    if (!commentDoc.exists) {
      throw Exception('კომენტარი ვერ მოიძებნა.');
    }

    if (commentDoc.data()?['userId'] != user.uid) {
      throw Exception('შეგიძლია მხოლოდ შენი კომენტარის წაშლა.');
    }

    await commentRef.delete();
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
