import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_opener/app_opener_screen.dart';
import '../../features/apps/app_drawer_screen.dart';
import '../../features/apps/apps_screen.dart';
import '../../features/customize/customize_screen.dart';
import '../../features/floating_panel/floating_panel_screen.dart';
import '../../features/gestures/gestures_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/permissions/permissions_screen.dart';
import '../../features/quick_controls/quick_controls_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/tools/calculator_screen.dart';
import '../../features/tools/compass_screen.dart';
import '../../features/tools/device_info_screen.dart';
import '../../features/tools/flashlight_screen.dart';
import '../../features/tools/notes_screen.dart';
import '../../features/tools/qr_tool_screen.dart';
import '../../features/tools/stopwatch_screen.dart';
import '../../features/tools/timer_screen.dart';
import '../../features/tools/tools_screen.dart';
import '../../features/tools/unit_converter_screen.dart';
import '../../features/tools/screen_magnifier_screen.dart';
import '../../shared/widgets/bottom_navigation.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: TaplyBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: _onItemTapped,
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/apps',
              builder: (context, state) => const AppsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tools',
              builder: (context, state) => const ToolsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/customize',
              builder: (context, state) => const CustomizeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Sub-screens (Without Bottom Navigation)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quick-controls',
      builder: (context, state) => const QuickControlsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/app-drawer',
      builder: (context, state) => const AppDrawerScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/app-opener',
      builder: (context, state) => const AppOpenerScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/gestures',
      builder: (context, state) => const GesturesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/permissions',
      builder: (context, state) => const PermissionsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/floating-panel',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 160),
        reverseTransitionDuration: const Duration(milliseconds: 140),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: const FloatingPanelScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Tools sub-routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/calculator',
      builder: (context, state) => const CalculatorScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/timer',
      builder: (context, state) => const TimerScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/stopwatch',
      builder: (context, state) => const StopwatchScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/flashlight',
      builder: (context, state) => const FlashlightScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/notes',
      builder: (context, state) => const NotesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/qr-studio',
      builder: (context, state) => const QRToolScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/device-info',
      builder: (context, state) => const DeviceInfoScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/unit-converter',
      builder: (context, state) => const UnitConverterScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/compass',
      builder: (context, state) => const CompassScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/magnifier',
      builder: (context, state) => const ScreenMagnifierScreen(),
    ),
  ],
);
