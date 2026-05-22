import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'home/assets_library_screen.dart';
import 'home/tutorials_page.dart';
import 'home/more_tools_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AssetsLibraryScreen(),
    const TutorialsPage(),
    const MoreToolsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white24,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_filled),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_motion_outlined),
              activeIcon: Icon(Icons.auto_awesome_motion_rounded),
              label: 'ASSETS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline_rounded),
              activeIcon: Icon(Icons.play_circle_filled_rounded),
              label: 'TUTORIALS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'STUDIO',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
