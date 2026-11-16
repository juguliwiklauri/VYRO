
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
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
    final cleanName = displayName.trim();
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      throw Exception('შეიყვანე სახელი.');
    }

    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(cleanUsername)) {
      throw Exception('მომხმარებლის სახელი უნდა შეიცავდეს 3-20 ლათინურ სიმბოლოს.');
    }

    if (password.length < 6) {
      throw Exception('პაროლი მინიმუმ 6 სიმბოლო უნდა იყოს.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user!;

    try {
      await _db.runTransaction((transaction) async {
        final usernameRef =
            _db.collection('usernames').doc(cleanUsername);
        final userRef = _db.collection('users').doc(user.uid);

        final existing = await transaction.get(usernameRef);

        if (existing.exists) {
          throw Exception('ეს მომხმარებლის სახელი უკვე დაკავებულია.');
        }

        transaction.set(usernameRef, {
          'uid': user.uid,
          'username': cleanUsername,
        });

        transaction.set(userRef, {
          'uid': user.uid,
          'displayName': cleanName,
          'username': cleanUsername,
          'email': cleanEmail,
          'photoUrl': '',
          'bio': '',
          'followersCount': 0,
          'followingCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      await user.updateDisplayName(cleanName);
      return credential;
    } catch (error) {
      await user.delete();
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
