import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taply/core/routing/app_router.dart';
import 'package:taply/core/services/providers.dart';
import 'package:taply/main.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('TaplyApp builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TaplyApp()));
    expect(find.byType(TaplyApp), findsOneWidget);
  });

  testWidgets('TaplyApp fresh install opens Onboarding after splash', (
    WidgetTester tester,
  ) async {
    appRouter.go('/splash');
    final storage = TestStorageService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const TaplyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Onboarding Screen is loaded
    expect(find.text('Taply'), findsWidgets);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('TaplyApp subsequent launch opens Home Screen after splash', (
    WidgetTester tester,
  ) async {
    appRouter.go('/splash');
    final storage = TestStorageService({'taply_onboarding_completed': true});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const TaplyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Home Screen is loaded
    expect(find.text('Taply'), findsWidgets);
    expect(find.text('Your quick-access assistant'), findsOneWidget);
  });
}
