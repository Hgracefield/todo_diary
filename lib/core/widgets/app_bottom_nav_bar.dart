import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          label: '일정',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_graph_outlined),
          label: '통계',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: '설정',
        ),
      ],
    );
  }
}
