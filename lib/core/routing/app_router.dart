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
import '../../features/quick_actions/quick_actions_screen.dart';
import '../../features/settings/licenses_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tools/battery_diagnostics_screen.dart';
import '../../features/tools/calculator_screen.dart';
import '../../features/tools/compass_screen.dart';
import '../../features/tools/device_info_screen.dart';
import '../../features/tools/flashlight_screen.dart';
import '../../features/tools/notes_screen.dart';
import '../../features/tools/qr_tool_screen.dart';
import '../../features/tools/screen_magnifier_screen.dart';
import '../../features/tools/stopwatch_screen.dart';
import '../../features/tools/storage_analyzer_screen.dart';
import '../../features/tools/timer_screen.dart';
import '../../features/tools/tools_screen.dart';
import '../../features/tools/unit_converter_screen.dart';
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
  initialLocation: '/splash',
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
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/licenses',
      builder: (context, state) => const LicensesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quick-actions',
      builder: (context, state) => const QuickActionsScreen(),
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
      path: '/tools/battery-diagnostics',
      builder: (context, state) => const BatteryDiagnosticsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tools/storage-analyzer',
      builder: (context, state) => const StorageAnalyzerScreen(),
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

    // Backward-compatibility & Shortcut Redirects
    GoRoute(path: '/compass', redirect: (context, state) => '/tools/compass'),
    GoRoute(
      path: '/screen-magnifier',
      redirect: (context, state) => '/tools/magnifier',
    ),
    GoRoute(
      path: '/battery-diagnostics',
      redirect: (context, state) => '/tools/battery-diagnostics',
    ),
    GoRoute(
      path: '/storage-analyzer',
      redirect: (context, state) => '/tools/storage-analyzer',
    ),
    GoRoute(path: '/home', redirect: (context, state) => '/'),
  ],
  errorBuilder: (context, state) {
    debugPrint('[GoRouter] Route error: ${state.error} for uri: ${state.uri}');
    return Scaffold(
      appBar: AppBar(title: const Text('Taply')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.near_me_disabled_rounded,
                size: 64,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Could not locate: ${state.uri}',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
