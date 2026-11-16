import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String displayName,
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();

    if (cleanUsername.isEmpty ||
        !RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(cleanUsername)) {
      throw Exception('Username must be 3-20 characters.');
    }

    final usernameRef = _db.collection('usernames').doc(cleanUsername);
    final existing = await usernameRef.get();

    if (existing.exists) {
      throw Exception('This username is already taken.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    await user.updateDisplayName(displayName.trim());

    final batch = _db.batch();

    batch.set(usernameRef, {
      'uid': user.uid,
      'username': cleanUsername,
    });

    batch.set(_db.collection('users').doc(user.uid), {
      'uid': user.uid,
      'displayName': displayName.trim(),
      'username': cleanUsername,
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'photoUrl': '',
      'bio': '',
      'followersCount': 0,
      'followingCount': 0,
    });

    await batch.commit();

    return credential;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
