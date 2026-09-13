import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taply/main.dart';

void main() {
  testWidgets('TaplyApp builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TaplyApp()));
    await tester.pumpAndSettle();

    // Verify that the title 'Taply' is rendered
    expect(find.text('Taply'), findsWidgets);
    expect(find.text('Your quick-access assistant'), findsOneWidget);
  });
}
