import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/localization.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: Ku.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: Ku.search,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_rounded),
              label: Ku.add,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              label: Ku.messages,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: Ku.profile,
            ),
          ],
        ),
      ),
    );
  }
}
