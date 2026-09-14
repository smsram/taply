import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taply/core/routing/app_router.dart';
import 'package:taply/core/services/permission_service.dart';
import 'package:taply/core/services/providers.dart';
import 'package:taply/features/onboarding/onboarding_screen.dart';
import 'package:taply/features/splash/splash_screen.dart';
import 'package:taply/main.dart';

import 'test_helpers.dart';

GoRouter _createOnboardingTestRouter() {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Home Screen')),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
}

void main() {
  group('Splash Screen Unit & Widget Tests', () {
    testWidgets(
      'SplashScreen renders solid #2563EB and centered branding icon',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: SplashScreen())),
        );

        // Verify Scaffold has solid primary blue background
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, const Color(0xFF2563EB));

        // Verify centered Taply branding icon
        expect(find.byType(Image), findsOneWidget);

        // Verify no spinners or text
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'Fresh install navigates from Splash to Onboarding without flashing Home',
      (WidgetTester tester) async {
        appRouter.go('/splash');
        final storage = TestStorageService();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [storageServiceProvider.overrideWithValue(storage)],
            child: const TaplyApp(),
          ),
        );

        // At T=0, Splash Screen is visible
        expect(find.byType(SplashScreen), findsOneWidget);

        // Advance through the 950ms animation
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // On fresh install, lands directly on Onboarding
        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
        expect(find.text('Your quick-access assistant'), findsNothing);
      },
    );

    testWidgets(
      'Subsequent launch navigates from Splash to Home Screen directly',
      (WidgetTester tester) async {
        appRouter.go('/splash');
        final storage = TestStorageService({
          'taply_onboarding_completed': true,
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [storageServiceProvider.overrideWithValue(storage)],
            child: const TaplyApp(),
          ),
        );

        // At T=0, Splash Screen is visible
        expect(find.byType(SplashScreen), findsOneWidget);

        // Advance through animation
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        // Lands on Home Screen
        expect(find.text('Your quick-access assistant'), findsOneWidget);
        expect(find.byType(OnboardingScreen), findsNothing);
      },
    );
  });

  group('Onboarding Flow, Selection & Persistence Tests', () {
    testWidgets(
      'Complete 4-step onboarding flow navigates and applies selections',
      (WidgetTester tester) async {
        final storage = TestStorageService();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storage),
              permissionServiceProvider.overrideWithValue(
                MockPermissionService(),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: _createOnboardingTestRouter(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Step 1: Welcome
        expect(find.text('Get Started'), findsOneWidget);

        // Step 1 -> Step 2
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // Step 2: Choose Your Essentials
        expect(find.text('Choose Your Essentials'), findsOneWidget);
        // Toggle an action (e.g. Screenshot or Back)
        expect(find.text('Screenshot'), findsOneWidget);
        await tester.tap(find.text('Screenshot'));
        await tester.pumpAndSettle();

        // Tap Continue
        final continueBtnFinder = find.byWidgetPredicate(
          (w) => w is Text && w.data != null && w.data!.startsWith('Continue'),
        );
        expect(continueBtnFinder, findsOneWidget);
        await tester.tap(continueBtnFinder);
        await tester.pumpAndSettle();

        // Step 3: Permissions
        expect(find.text('Display Over Other Apps'), findsOneWidget);
        expect(find.text('Set Up Later'), findsOneWidget);
        await tester.tap(find.text('Set Up Later'));
        await tester.pumpAndSettle();

        // Step 4: Ready to Tap
        expect(find.text("You're All Set!"), findsOneWidget);
        expect(find.text('Start Using Taply'), findsOneWidget);
        await tester.tap(find.text('Start Using Taply'));
        await tester.pumpAndSettle();

        // Verify onboarding marked completed in storage
        expect(storage.getBool('taply_onboarding_completed'), true);
      },
    );

    testWidgets(
      'Preserves existing customization if user already customized actions',
      (WidgetTester tester) async {
        // Simulate user who already customized action order before visiting onboarding
        final storage = TestStorageService({
          'taply_user_customized_actions': true,
        });

        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            permissionServiceProvider.overrideWithValue(
              MockPermissionService(),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Custom action order
        final customOrder = ['calculator', 'timer', 'notes'];
        container
            .read(settingsProvider.notifier)
            .updatePanelConfig(
              container
                  .read(settingsProvider)
                  .panelConfig
                  .copyWith(actionOrder: customOrder),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: _createOnboardingTestRouter(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Fast skip to completion
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Verify custom order was preserved
        final currentOrder = container
            .read(settingsProvider)
            .panelConfig
            .actionOrder;
        expect(currentOrder, customOrder);
      },
    );
  });

  group('Onboarding Responsive UI & Zero Overflow Tests', () {
    testWidgets(
      'Renders with zero overflow on small screen (320x480) with 2.0x font scaling',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320 * 2.0, 480 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final storage = TestStorageService();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storage),
              permissionServiceProvider.overrideWithValue(
                MockPermissionService(),
              ),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 480),
                textScaler: TextScaler.linear(2.0),
              ),
              child: const MaterialApp(home: OnboardingScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Slide 1: Welcome - button reachable, zero overflow
        expect(tester.takeException(), isNull);
        expect(find.text('Get Started'), findsOneWidget);

        // Advance to Slide 2
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Choose Your Essentials'), findsOneWidget);

        // Advance to Slide 3
        final continueBtnFinder = find.byWidgetPredicate(
          (w) => w is Text && w.data != null && w.data!.startsWith('Continue'),
        );
        await tester.tap(continueBtnFinder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Display Over Other Apps'), findsOneWidget);

        // Advance to Slide 4
        await tester.tap(find.text('Set Up Later'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text("You're All Set!"), findsOneWidget);
        expect(find.text('Start Using Taply'), findsOneWidget);
      },
    );
  });
}
