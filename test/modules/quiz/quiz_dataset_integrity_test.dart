import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/quiz_duplicate_check.dart';
import 'package:lexiora/modules/quiz/domain/quiz_json.dart';

/// Enforces the duplicate-prevention contract on the SHIPPED dataset.
///
/// Every bank bundled under `assets/quiz/` is parsed through the same
/// [QuizJsonParser] the seeder uses, and the ENTIRE corpus (all 46 banks,
/// ~3,700 questions) is then checked with the real [QuizDuplicateChecker].
/// Any exact / reordered-option / different-option / reworded / same-concept
/// duplicate fails the suite, so a future edit that re-introduces a duplicate
/// question is caught in CI before it ships. This is the dataset-level
/// counterpart of `addGeneratedQuestions`, which guards new MCQs at save time.
void main() {
  const QuizDuplicateChecker checker = QuizDuplicateChecker();

  group('bundled quiz dataset integrity', () {
    test('every bundled bank parses with no blocking errors', () {
      final List<Map<String, dynamic>> manifests = _readManifest();
      expect(manifests, isNotEmpty, reason: 'manifest must list at least one bank');

      for (final Map<String, dynamic> entry in manifests) {
        final String ref = '${entry['ref']}';
        final File f = File('assets/quiz/$ref');
        expect(f.existsSync(), isTrue,
            reason: 'manifest references missing bank file: $ref');

        final QuizImportPayload payload =
            QuizJsonParser.parse(f.readAsStringSync(), fallbackName: ref);
        final ImportPreview preview = QuizJsonParser.validate(payload);
        expect(preview.hasBlockingErrors, isFalse,
            reason: 'bank $ref has blocking validation errors: '
                '${preview.errors.map((ImportIssue e) => e.message).join('; ')}');
        expect(payload.questions, isNotEmpty,
            reason: 'bank $ref contains no questions');
      }
    });

    test('the whole shipped corpus passes the duplicate-prevention check', () {
      final List<_BankQuestion> corpus = _loadCorpus();
      expect(corpus, isNotEmpty,
          reason: 'no questions were loaded from the bundled banks');

      final List<String> failures = <String>[];
      int compared = 0;

      // Pass 1: group by answer key so comparisons only run between questions
      // that COULD collide (the checker never matches different answers/types).
      // This catches exact, reordered-option, reworded and same-concept dups.
      final Map<String, List<_BankQuestion>> buckets =
          <String, List<_BankQuestion>>{};
      for (final _BankQuestion bq in corpus) {
        final String? key = _answerKey(bq.question);
        if (key == null) continue; // reserved types are never graded/checked
        buckets.putIfAbsent(key, () => <_BankQuestion>[]).add(bq);
      }
      for (final List<_BankQuestion> group in buckets.values) {
        for (int i = 0; i < group.length; i++) {
          for (int j = i + 1; j < group.length; j++) {
            compared++;
            _failIfDuplicate(
                checker, group[i], group[j], failures);
          }
        }
      }

      // Pass 2: identical content-bearing stems are duplicates EVEN when the
      // answer text differs (the checker's differentOptions rule: re-asking the
      // same stem is a contradictory duplicate). Generic instruction stems
      // (e.g. 'Choose the correct sentence:') carry their content in the
      // options, so they are only duplicates when their correct answers match
      // — already covered by pass 1.
      final Map<String, List<_BankQuestion>> byStem =
          <String, List<_BankQuestion>>{};
      for (final _BankQuestion bq in corpus) {
        final String stem =
            QuizDuplicateChecker.normalizePrompt(bq.question.prompt);
        if (stem.isEmpty || _isGenericInstruction(stem)) continue;
        byStem.putIfAbsent(stem, () => <_BankQuestion>[]).add(bq);
      }
      for (final List<_BankQuestion> group in byStem.values) {
        for (int i = 0; i < group.length; i++) {
          for (int j = i + 1; j < group.length; j++) {
            compared++;
            _failIfDuplicate(
                checker, group[i], group[j], failures);
          }
        }
      }

      expect(compared, greaterThan(0),
          reason: 'no candidate pairs were compared — buckets are empty?');
      expect(failures, isEmpty,
          reason: 'bundled corpus contains ${failures.length} duplicate '
              'group(s) rejected by QuizDuplicateChecker:\n'
              '${failures.join('\n')}');
    });

    test('no bank has a repeated question id within the file', () {
      for (final Map<String, dynamic> entry in _readManifest()) {
        final String ref = '${entry['ref']}';
        final File f = File('assets/quiz/$ref');
        if (!f.existsSync()) continue;
        final QuizImportPayload payload =
            QuizJsonParser.parse(f.readAsStringSync(), fallbackName: ref);
        final List<String> ids = payload.questions
            .map((QuizQuestion q) => q.externalId ?? '')
            .where((String id) => id.isNotEmpty)
            .toList();
        expect(ids.toSet().length, ids.length,
            reason: 'bank $ref has repeated question ids');
      }
    });
  });
}

List<Map<String, dynamic>> _readManifest() {
  final File f = File('assets/quiz/manifest.json');
  final dynamic decoded = jsonDecode(f.readAsStringSync());
  return (decoded is Map && decoded['banks'] is List)
      ? (decoded['banks'] as List).cast<Map<String, dynamic>>()
      : const <Map<String, dynamic>>[];
}

/// Parses every bank listed in the manifest into a flat corpus of questions,
/// each tagged with its bank file so failures can name the source bank.
List<_BankQuestion> _loadCorpus() {
  final List<_BankQuestion> corpus = <_BankQuestion>[];
  for (final Map<String, dynamic> entry in _readManifest()) {
    final String ref = '${entry['ref']}';
    final File f = File('assets/quiz/$ref');
    if (!f.existsSync()) continue;
    final QuizImportPayload payload =
        QuizJsonParser.parse(f.readAsStringSync(), fallbackName: ref);
    for (int i = 0; i < payload.questions.length; i++) {
      corpus.add(_BankQuestion(ref, i, payload.questions[i]));
    }
  }
  return corpus;
}

void _failIfDuplicate(
  QuizDuplicateChecker checker,
  _BankQuestion a,
  _BankQuestion b,
  List<String> failures,
) {
  final DuplicateVerdict v =
      checker.check(a.question, <QuizQuestion>[b.question]);
  if (!v.isDuplicate) return;
  failures.add('${a.ref} (question ${a.index + 1}) and '
      '${b.ref} (question ${b.index + 1}) — '
      '${v.kind.name}: "${a.question.prompt}" ~ "${b.question.prompt}"');
}

/// Whether a normalized stem is a generic instruction (e.g. 'Choose the
/// correct sentence:') whose real content is carried by the options, matching
/// the checker's own list. Such stems are NOT duplicates on their own — only
/// when their correct answers match (caught by the answer-bucket pass).
bool _isGenericInstruction(String normalizedPrompt) {
  const List<String> stems = <String>[
    'choose the correct sentence',
    'choose the correctly punctuated sentence',
    'select the correct sentence',
    'find the correct sentence',
    'which sentence is correct',
    'which of the following sentences is correct',
    'which of the following statements is correct',
    'choose the correct form',
    'choose the correct option',
    'choose the correct answer',
    'identify the error',
    'find the error',
    'spot the error',
    'the correctly punctuated sentence is',
  ];
  for (final String prefix in stems) {
    if (normalizedPrompt.startsWith(prefix)) return true;
  }
  return false;
}

/// Mirrors the checker's answer-equality rule: the value that determines
/// whether two questions can be duplicates at all. Same type + same
/// normalized answer (by value, not index). Null for reserved types.
String? _answerKey(QuizQuestion q) {
  switch (q.type) {
    case QuestionType.mcqSingle:
      final int? i = q.answerIndex;
      if (i == null || i < 0 || i >= q.options.length) return null;
      return 'mcq:${QuizDuplicateChecker.normalizePrompt(q.options[i])}';
    case QuestionType.trueFalse:
      return q.answerBool == null ? null : 'tf:${q.answerBool}';
    case QuestionType.fillBlank:
      final List<String> norm = q.answerTexts
          .map(QuizDuplicateChecker.normalizePrompt)
          .toSet()
          .toList()
        ..sort();
      return 'blank:${norm.join('|')}';
    case QuestionType.matching:
    case QuestionType.multiCorrect:
      return null; // reserved — not graded or checked
  }
}

class _BankQuestion {
  const _BankQuestion(this.ref, this.index, this.question);

  final String ref;
  final int index;
  final QuizQuestion question;
}
