
import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'search_screen.dart';
import 'upload_screen.dart';
import 'video_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  Future<void> _openUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UploadScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const VideoFeedScreen(),
      const SearchScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: IndexedStack(
        index: tab,
        children: pages,
      ),
      floatingActionButton: tab == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFFD600),
              foregroundColor: Colors.black,
              onPressed: _openUpload,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF101010),
        indicatorColor: const Color(0xFFFFD600),
        selectedIndex: tab,
        onDestinationSelected: (value) {
          setState(() => tab = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'მთავარი',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'ძიება',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'პროფილი',
          ),
        ],
      ),
    );
  }
}
