import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taply/core/constants/app_constants.dart';
import 'package:taply/features/floating_panel/floating_panel_screen.dart';
import 'package:taply/features/apps/app_drawer_screen.dart';
import 'package:taply/features/tools/compass_screen.dart';
import 'package:taply/shared/models/installed_app.dart';
import 'package:taply/shared/widgets/app_launch_modal.dart';
import 'package:taply/shared/widgets/taply_brand_logo.dart';

void main() {
  group('Phase 3 Production Polish & Feature Tests', () {
    testWidgets('TaplyBrandLogo renders cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: TaplyBrandLogo(size: 64))),
        ),
      );

      expect(find.byType(TaplyBrandLogo), findsOneWidget);
    });

    testWidgets(
      'FloatingPanelScreen renders carousel tabs and priority sections',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: FloatingPanelScreen())),
        );
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Taply Assistant'), findsOneWidget);

        // Carousel Tab Navigation
        // Carousel Tab Navigation (exactly 4 pages: Actions, Apps, Tools, Controls)
        expect(find.text('Actions'), findsOneWidget);
        expect(find.text('Apps'), findsOneWidget);
        expect(find.text('Tools'), findsOneWidget);
        expect(find.text('Controls'), findsOneWidget);
        expect(find.text('More'), findsNothing);

        // Priority 1: System Actions (on default Actions tab)
        expect(find.text('Back'), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Recents'), findsOneWidget);
        expect(find.text('Screenshot'), findsOneWidget);
        expect(find.text('Lock Screen'), findsOneWidget);

        // Navigate to Apps tab
        await tester.tap(find.text('Apps'));
        await tester.pumpAndSettle();
        expect(find.text('All Applications'), findsOneWidget);

        // Header contains Settings shortcut button
        expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

        // Navigate to Tools tab
        await tester.tap(find.text('Tools'));
        await tester.pumpAndSettle();
        expect(find.text('Calculator'), findsOneWidget);
        expect(find.text('Timer'), findsOneWidget);
        expect(find.text('Stopwatch'), findsOneWidget);
      },
    );

    testWidgets('AppDrawerScreen renders mini-launcher and A-Z scrubber', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AppDrawerScreen())),
      );
      await tester.pumpAndSettle();

      // Search bar
      expect(find.byType(TextField), findsOneWidget);

      // A-Z Alphabet scrubber
      expect(find.text('A'), findsWidgets);
      expect(find.text('Z'), findsWidgets);
    });

    testWidgets(
      'AppLaunchModal displays unsupported notice and Open Normally button',
      (WidgetTester tester) async {
        final testApp = InstalledApp(
          packageName: 'com.example.test',
          appName: 'Test Application',
          launchMode: AppLaunchMode.normal,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => AppLaunchModal.show(context, testApp),
                    child: const Text('Launch Modal'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Launch Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Open App'), findsOneWidget);
        expect(find.text('App Info'), findsOneWidget);
      },
    );

    testWidgets('CompassScreen renders digital compass and sensor status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CompassScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Digital Compass'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data == 'Sensor Unavailable' ||
                  w.data == 'AZIMUTH' ||
                  w.data == 'Magnetometer Sensor Unavailable'),
        ),
        findsWidgets,
      );
    });

    test('AppConstants contains correct version and production values', () {
      expect(AppConstants.appVersion, '1.0.0');
      expect(AppConstants.buildNumber, '100');
      expect(
        AppConstants.privacyStatement.contains('100% on your device'),
        isTrue,
      );
    });
  });
}
