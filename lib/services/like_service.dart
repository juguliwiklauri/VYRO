
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> toggleLike(String videoId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('მოწონებისთვის საჭიროა ავტორიზაცია.');
    }

    final videoRef = _db.collection('videos').doc(videoId);
    final likeRef = videoRef.collection('likes').doc(user.uid);

    await _db.runTransaction((transaction) async {
      final like = await transaction.get(likeRef);
      final video = await transaction.get(videoRef);

      if (!video.exists) {
        throw Exception('ვიდეო ვერ მოიძებნა.');
      }

      final currentCount =
          (video.data()?['likesCount'] as num?)?.toInt() ?? 0;

      if (like.exists) {
        transaction.delete(likeRef);
        transaction.update(videoRef, {
          'likesCount': currentCount > 0 ? currentCount - 1 : 0,
        });
      } else {
        transaction.set(likeRef, {
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(videoRef, {
          'likesCount': currentCount + 1,
        });
      }
    });
  }

  Stream<bool> isLiked(String videoId) {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream<bool>.value(false);
    }

    return _db
        .collection('videos')
        .doc(videoId)
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<int> likeCount(String videoId) {
    return _db
        .collection('videos')
        .doc(videoId)
        .snapshots()
        .map((snapshot) {
      final count = snapshot.data()?['likesCount'];
      return (count as num?)?.toInt() ?? 0;
    });
  }
}
