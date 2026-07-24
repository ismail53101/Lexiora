import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/widgets/error_view.dart';

void main() {
  testWidgets('ErrorView shows the message and fires Retry/Back', (
    WidgetTester tester,
  ) async {
    bool retried = false;
    bool backed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            title: 'Cannot open document',
            message: 'The document failed to load.',
            details: 'some technical detail',
            onRetry: () => retried = true,
            onBack: () => backed = true,
          ),
        ),
      ),
    );

    expect(find.text('Cannot open document'), findsOneWidget);
    expect(find.text('The document failed to load.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);

    await tester.tap(find.text('Back'));
    expect(backed, isTrue);
  });
}
