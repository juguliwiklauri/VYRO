import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
            const SizedBox(height: 12),
            Text(data['displayName'] ?? user.displayName ?? 'VYRO user',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('@${data['username'] ?? ''}', style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            Text(data['bio'] ?? ''),
            const SizedBox(height: 24),
            OutlinedButton.icon(onPressed: () async {
              await AuthService().signOut();
            }, icon: const Icon(Icons.logout), label: const Text('გასვლა')),
          ],
        )));
      },
    );
  }
}
