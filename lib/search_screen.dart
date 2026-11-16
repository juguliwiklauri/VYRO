import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  String query = '';
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.all(16), child: TextField(
      controller: controller, onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'მოძებნე მომხმარებელი'))),
    Expanded(child: query.length < 2
      ? const Center(child: Text('შეიყვანე მინიმუმ 2 სიმბოლო'))
      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users')
          .orderBy('username').startAt([query]).endAt(['$query\uf8ff']).limit(25).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('ძიების შეცდომა. შეამოწმე Firestore-ის წესები.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('მომხმარებელი ვერ მოიძებნა.'));
          return ListView.builder(itemCount: docs.length, itemBuilder: (context, i) {
            final data = docs[i].data();
            return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(data['displayName'] ?? 'VYRO user'),
              subtitle: Text('@${data['username'] ?? ''}'));
          });
        },
      )),
  ]);
}
