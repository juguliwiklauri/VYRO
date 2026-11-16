import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const _FeedPlaceholder(),
      const SearchScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('VYRO', style: TextStyle(
        color: Color(0xFFFFD600), fontWeight: FontWeight.bold, fontSize: 26)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))]),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'მთავარი'),
          NavigationDestination(icon: Icon(Icons.search), label: 'ძიება'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'პროფილი'),
        ]),
    );
  }
}
class _FeedPlaceholder extends StatelessWidget {
  const _FeedPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.play_circle_outline, size: 76, color: Color(0xFFFFD600)),
      SizedBox(height: 12),
      Text('VYRO ვიდეოების სივრცე'),
      SizedBox(height: 6),
      Text('ვიდეოების ატვირთვისა და feed-ის მოდული შემდეგ ეტაპზე დაემატება.',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
    ]));
}
