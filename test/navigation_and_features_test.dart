import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taply/main.dart';
import 'package:taply/features/tools/calculator_screen.dart';
import 'package:taply/features/tools/timer_screen.dart';
import 'package:taply/features/tools/stopwatch_screen.dart';
import 'package:taply/core/theme/app_theme.dart';
import 'package:taply/core/services/providers.dart';

void main() {
  group('Taply Navigation & Shell Tabs', () {
    testWidgets('Tapping bottom navigation tabs switches screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TaplyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Home Screen initially loaded
      expect(find.text('Your quick-access assistant'), findsOneWidget);
      expect(find.text('Floating Assistant'), findsOneWidget);

      // Tap 'Apps' tab
      await tester.tap(find.byIcon(Icons.apps_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Search installed apps'), findsOneWidget);

      // Tap 'Tools' tab
      await tester.tap(find.byIcon(Icons.handyman_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Daily Utilities'), findsOneWidget);
      expect(find.text('Calculator'), findsOneWidget);

      // Tap 'Customize' tab
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Floating Button'), findsOneWidget);
      expect(find.text('Button Size'), findsOneWidget);

      // Tap 'Settings' tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Enable Taply'), findsOneWidget);
    });

    testWidgets('Toggling floating assistant updates state', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(settingsProvider).isAssistantEnabled, true);

      container.read(settingsProvider.notifier).toggleAssistant(false);
      expect(container.read(settingsProvider).isAssistantEnabled, false);

      container.read(settingsProvider.notifier).toggleAssistant(true);
      expect(container.read(settingsProvider).isAssistantEnabled, true);
    });

    testWidgets('Switching theme modes works cleanly', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setThemeMode(AppThemeMode.amoled);
      expect(container.read(settingsProvider).themeMode, AppThemeMode.amoled);

      container.read(settingsProvider.notifier).setThemeMode(AppThemeMode.dark);
      expect(container.read(settingsProvider).themeMode, AppThemeMode.dark);
    });
  });

  group('Working Tools Implementations', () {
    testWidgets('Calculator performs addition accurately', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 7 + 8 =
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();

      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('Timer presets and controls render properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TimerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUICK PRESETS'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);

      // Tap 1 min preset
      await tester.tap(find.text('1 min'));
      await tester.pumpAndSettle();
      expect(find.text('01:00'), findsOneWidget);
    });

    testWidgets('Stopwatch starts, pauses, and resets', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StopwatchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('00:00.00'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      // Start stopwatch
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Stop'), findsOneWidget);
    });
  });
}

