import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/reader_engine/word_action.dart';
import 'package:lexiora/features/reader/presentation/widgets/reader_selection_toolbar.dart';

/// A stand-in [WordAction] for widget tests (no real popup work).
class _FakeAction implements WordAction {
  const _FakeAction(
    this.id,
    this.label,
    this.icon,
    this.priority, {
    this.supportsPhrase = false,
  });
  @override
  final String id;
  @override
  final String label;
  @override
  final IconData icon;
  @override
  final int priority;
  @override
  final bool supportsPhrase;
  @override
  Future<void> invoke(BuildContext context, WordActionContext ctx) async {}
}

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  const List<WordAction> actions = <WordAction>[
    _FakeAction('dictionary.define', 'Look up', Icons.menu_book_outlined, 10),
    _FakeAction('translation.translate', 'Translate', Icons.translate, 20,
        supportsPhrase: true),
  ];

  testWidgets(
      'shows Look up + Translate beside the core actions for a single word',
      (WidgetTester tester) async {
    WordAction? invoked;
    await tester.pumpWidget(host(ReaderSelectionToolbar(
      colors: const <int>[0xFFFFF176],
      onHighlight: (_) {},
      onUnderline: (_) {},
      onNote: () {},
      onBookmark: () {},
      onCopy: () {},
      onDismiss: () {},
      selectedWord: 'run',
      wordActions: actions,
      onWordAction: (WordAction a) => invoked = a,
    )));

    // Both word actions render.
    expect(find.text('Look up'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    // The selected word is shown.
    expect(find.text('“run”'), findsOneWidget);
    // Existing reader actions are preserved.
    expect(find.byTooltip('Underline'), findsOneWidget);
    expect(find.byTooltip('Note'), findsOneWidget);
    expect(find.byTooltip('Bookmark'), findsOneWidget);
    expect(find.byTooltip('Copy'), findsOneWidget);
    expect(find.byTooltip('Dismiss'), findsOneWidget);

    await tester.tap(find.text('Translate'));
    expect(invoked?.id, 'translation.translate');
  });

  testWidgets('hides word actions when the selection is not a single word',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(ReaderSelectionToolbar(
      colors: const <int>[0xFFFFF176],
      onHighlight: (_) {},
      onUnderline: (_) {},
      onNote: () {},
      onBookmark: () {},
      onCopy: () {},
      onDismiss: () {},
      // No single word → no word actions offered.
    )));

    expect(find.text('Look up'), findsNothing);
    expect(find.text('Translate'), findsNothing);
    // Core actions still present.
    expect(find.byTooltip('Underline'), findsOneWidget);
    expect(find.byTooltip('Copy'), findsOneWidget);
  });
}
