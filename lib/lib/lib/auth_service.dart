import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register({
    required String displayName,
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim();

    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(cleanUsername)) {
      throw Exception(
        'მომხმარებლის სახელი უნდა შეიცავდეს 3-20 ლათინურ ასოს, ციფრს ან ქვედა ტირეს.',
      );
    }

    final usernameRef = _db.collection('usernames').doc(cleanUsername);

    final existing = await usernameRef.get();
    if (existing.exists) {
      throw Exception('ეს მომხმარებლის სახელი უკვე დაკავებულია.');
    }

    UserCredential credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'რეგისტრაცია ვერ შესრულდა.');
    }

    final user = credential.user!;
    final batch = _db.batch();

    batch.set(usernameRef, {'uid': user.uid});

    batch.set(_db.collection('users').doc(user.uid), {
      'uid': user.uid,
      'displayName': displayName.trim(),
      'username': cleanUsername,
      'email': cleanEmail,
      'bio': '',
      'photoUrl': '',
      'followersCount': 0,
      'followingCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await user.updateDisplayName(displayName.trim());
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
