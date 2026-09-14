import 'package:flutter/material.dart';

import '../../core/utils/extensions.dart';

class TaplyBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const TaplyBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: loc.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.apps_outlined),
          selectedIcon: const Icon(Icons.apps_rounded),
          label: loc.apps,
        ),
        NavigationDestination(
          icon: const Icon(Icons.handyman_outlined),
          selectedIcon: const Icon(Icons.handyman_rounded),
          label: loc.tools,
        ),
        NavigationDestination(
          icon: const Icon(Icons.palette_outlined),
          selectedIcon: const Icon(Icons.palette_rounded),
          label: loc.customize,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: loc.settings,
        ),
      ],
    );
  }
}
