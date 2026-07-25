import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/services/pronunciation_service.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';
import 'package:lexiora/modules/dictionary/presentation/widgets/pronunciation_button.dart';

/// Fake TTS service: no platform channel, records speak() calls.
class _FakePronunciation implements PronunciationService {
  _FakePronunciation({required this.available});
  final bool available;
  int speakCount = 0;

  @override
  Future<bool> isAvailable(String languageCode) async => available;

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    speakCount++;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  Future<void> pump(WidgetTester tester, _FakePronunciation fake) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pronunciationServiceProvider.overrideWithValue(fake)],
        child: const MaterialApp(
          home: Scaffold(
            body: PronunciationButton(
              text: 'inquire',
              languageCode: 'en-US',
              label: 'US',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hides itself when the accent has no voice available',
      (WidgetTester tester) async {
    await pump(tester, _FakePronunciation(available: false));
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('US'), findsNothing);
  });

  testWidgets('shows an enabled button and speaks on tap when available',
      (WidgetTester tester) async {
    final _FakePronunciation fake = _FakePronunciation(available: true);
    await pump(tester, fake);

    expect(find.text('US'), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(fake.speakCount, 1);
  });
}
