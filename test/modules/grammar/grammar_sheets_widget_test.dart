import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/presentation/pages/lesson_page.dart';

/// The DIS reference-sheet and intro views were previously only exercised on
/// real devices; a runtime rendering failure shipped silently. These tests
/// pump the actual bundled JSON through the views (at 1x and a large text
/// scale, with a viewport tall enough to build every section) so any missing
/// section, clipped text or build exception fails CI.

Map<String, dynamic> _leafContent(String id) {
  final Map<String, dynamic> doc = jsonDecode(
    File('assets/grammar/grammar_topics.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  Map<String, dynamic>? content;
  void walk(Object? node) {
    if (content != null || node is! Map) return;
    if (node['id'] == id && node['content'] is Map) {
      content = (node['content'] as Map).cast<String, dynamic>();
      return;
    }
    node.forEach((dynamic _, dynamic value) => walk(value));
  }

  walk(doc);
  if (content == null) {
    fail('lesson $id not found in assets/grammar/grammar_topics.json');
  }
  return content!;
}

GrammarLesson _lesson(
  String id, {
  Map<String, dynamic>? intro,
  Map<String, dynamic>? sheet,
}) {
  return GrammarLesson(
    id: id,
    title: id,
    narrationIntro: intro,
    narrationSheet: sheet,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1000, 40000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: child)),
  );
  await tester.pump();
}

void main() {
  const String commandsId =
      'direct-indirect-speech/commands-requests-punctuation';
  const String introId = 'direct-indirect-speech/introduction';

  testWidgets(
    'commands reference sheet renders every section on real data',
    (WidgetTester tester) async {
      final Map<String, dynamic> content = _leafContent(commandsId);
      await _pump(
        tester,
        NarrationSheetView(
          lesson: _lesson(
            commandsId,
            sheet: content['narrationSheet'] as Map<String, dynamic>?,
          ),
        ),
      );

      // Section A — all three command categories and their example panels.
      expect(find.textContaining('COMMANDS AND REQUESTS'), findsWidgets);
      expect(find.textContaining('Positive Command'), findsWidgets);
      expect(find.textContaining('Negative Command'), findsWidgets);
      expect(find.textContaining('Sit down.'), findsWidgets);
      expect(find.textContaining('to sit down'), findsWidgets);
      expect(find.textContaining('not to be late'), findsWidgets);
      expect(find.textContaining('Kindly wait here.'), findsWidgets);
      expect(find.textContaining('to send him the notes'), findsWidgets);
      // Section B — punctuation changes.
      expect(find.textContaining('PUNCTUATION CHANGES'), findsWidgets);
      expect(find.textContaining('Come here.'), findsWidgets);
      expect(find.textContaining('What is this?'), findsWidgets);
      // Section C — tense exceptions.
      expect(find.textContaining('WHEN TENSE DOES NOT CHANGE'), findsWidgets);
      expect(find.textContaining('Universal Truth'), findsWidgets);
      expect(find.textContaining('Fact Still True'), findsWidgets);
      // Section D — checklist.
      expect(find.textContaining('FINAL CONVERSION CHECKLIST'), findsWidgets);
      expect(
        find.textContaining('Use normal statement word order.'),
        findsWidgets,
      );
      // Remember strip.
      expect(
        find.textContaining('do not always change the tense'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'commands reference sheet renders without errors at large text scale',
    (WidgetTester tester) async {
      final Map<String, dynamic> content = _leafContent(commandsId);
      tester.view.physicalSize = const Size(1000, 80000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: NarrationSheetView(
                lesson: _lesson(
                  commandsId,
                  sheet: content['narrationSheet'] as Map<String, dynamic>?,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Sit down.'), findsWidgets);
      expect(find.textContaining('Universal Truth'), findsWidgets);
      expect(
        find.textContaining('Use normal statement word order.'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'intro lesson renders all sections on real data',
    (WidgetTester tester) async {
      final Map<String, dynamic> content = _leafContent(introId);
      await _pump(
        tester,
        NarrationIntroView(
          lesson: _lesson(
            introId,
            intro: content['narrationIntro'] as Map<String, dynamic>?,
          ),
        ),
      );

      // Side-by-side panels.
      expect(find.textContaining('Features of Direct Speech'), findsWidgets);
      expect(find.textContaining('Features of Indirect Speech'), findsWidgets);
      expect(find.textContaining('reporting clause'), findsWidgets);
      // Standalone worked-example section.
      expect(find.textContaining('Example with Explanation'), findsWidgets);
      expect(find.textContaining('the reporting clause'), findsWidgets);
      expect(find.textContaining('joining word'), findsWidgets);
      // Step chips with their full example lines.
      expect(find.textContaining('Step-by-Step Method'), findsWidgets);
      expect(find.textContaining('Find who said it. Ali said,'), findsWidgets);
      expect(
        find.textContaining('Add a joining word. Ali said that'),
        findsWidgets,
      );
      // Key difference + exam tip.
      expect(find.textContaining('Key Difference'), findsWidgets);
      expect(find.textContaining('Important Rule / Exam Tip'), findsWidgets);
    },
  );

  testWidgets(
    'intro lesson renders without errors at large text scale',
    (WidgetTester tester) async {
      final Map<String, dynamic> content = _leafContent(introId);
      tester.view.physicalSize = const Size(1000, 80000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: NarrationIntroView(
                lesson: _lesson(
                  introId,
                  intro: content['narrationIntro'] as Map<String, dynamic>?,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Features of Direct Speech'), findsWidgets);
      expect(find.textContaining('Example with Explanation'), findsWidgets);
      expect(find.textContaining('Key Difference'), findsWidgets);
    },
  );
}
