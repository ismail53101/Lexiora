import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/card_editor_utils.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_content.dart';

void main() {
  group('FcRichTextController', () {
    test('formats selected text and keeps plain editable text', () {
      final FcRichTextController controller = FcRichTextController(text: 'English');
      controller.toggleFormat(
        'b',
        const TextRange(start: 0, end: 7),
      );

      expect(controller.text, 'English');
      expect(controller.markupText, '[b]English[/b]');
      controller.dispose();
    });

    test('supports combined bold italic and underline formatting', () {
      final FcRichTextController controller = FcRichTextController(text: 'English');
      const TextRange all = TextRange(start: 0, end: 7);

      controller.toggleFormat('b', all);
      controller.toggleFormat('i', all);
      controller.toggleFormat('u', all);

      expect(controller.markupText, '[b][i][u]English[/u][/i][/b]');
      controller.dispose();
    });

    test('selected formatting can be toggled off', () {
      final FcRichTextController controller = FcRichTextController();
      controller.loadMarkup('[b]English[/b]');

      controller.toggleFormat(
        'b',
        const TextRange(start: 0, end: 7),
      );

      expect(controller.text, 'English');
      expect(controller.markupText, 'English');
      controller.dispose();
    });

    test('toolbar formatting becomes the style for future typing', () {
      final FcRichTextController controller = FcRichTextController(text: 'English');
      controller.selection = const TextSelection.collapsed(offset: 7);
      controller.toggleFormat('b', controller.selection);
      controller.value = const TextEditingValue(
        text: 'English vocabulary',
        selection: TextSelection.collapsed(offset: 19),
      );

      expect(controller.text, 'English vocabulary');
      expect(controller.markupText, 'English[b] vocabulary[/b]');
      controller.dispose();
    });

    test('loads persisted markup without exposing markup tokens in editor', () {
      final FcRichTextController controller = FcRichTextController();
      controller.loadMarkup('[b]English[/b] [i]grammar[/i]');

      expect(controller.text, 'English grammar');
      expect(controller.markupText, '[b]English[/b] [i]grammar[/i]');
      controller.dispose();
    });

    test('cloze markup remains intact', () {
      final FcRichTextController controller = FcRichTextController();
      controller.loadMarkup('The {{c1::heart}} pumps blood');

      expect(controller.text, 'The {{c1::heart}} pumps blood');
      expect(controller.markupText, 'The {{c1::heart}} pumps blood');
      controller.dispose();
    });
  });

  group('insertSpeechText', () {
    test('inserts speech at the cursor without overwriting existing text', () {
      const TextEditingValue value = TextEditingValue(
        text: 'English grammar',
        selection: TextSelection.collapsed(offset: 7),
      );

      final TextEditingValue next = insertSpeechText(value, 'is important');

      expect(next.text, 'English is important grammar');
      expect(next.selection.baseOffset, 20);
    });

    test('replaces a selected range with speech', () {
      const TextEditingValue value = TextEditingValue(
        text: 'English grammar',
        selection: TextSelection(baseOffset: 8, extentOffset: 15),
      );

      final TextEditingValue next = insertSpeechText(value, 'vocabulary');

      expect(next.text, 'English vocabulary');
      expect(next.selection.baseOffset, 18);
    });
  });
}
