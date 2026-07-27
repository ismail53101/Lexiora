import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/quiz_json.dart';

void main() {
  test('parses a full bank with mcq / true-false / blank', () {
    const String json = '''
    {
      "bank": { "name": "Sample", "subject": "GK", "id": "gk1", "version": "1.0" },
      "questions": [
        { "type": "mcq", "prompt": "2+2?", "options": ["3","4","5"], "answer": 1 },
        { "type": "truefalse", "prompt": "Earth is flat", "answer": false },
        { "type": "blank", "prompt": "Capital of France", "answer": ["Paris"] }
      ]
    }''';
    final QuizImportPayload p = QuizJsonParser.parse(json);
    expect(p.name, 'Sample');
    expect(p.subject, 'GK');
    expect(p.externalId, 'gk1');
    expect(p.questions.length, 3);
    expect(p.questions[0].type, QuestionType.mcqSingle);
    expect(p.questions[0].answerIndex, 1);
    expect(p.questions[1].type, QuestionType.trueFalse);
    expect(p.questions[1].answerBool, false);
    expect(p.questions[2].type, QuestionType.fillBlank);
    expect(p.questions[2].answerTexts, <String>['Paris']);
  });

  test('mcq answer given as option text resolves to its index', () {
    const String json =
        '{ "questions": [ { "type": "mcq", "prompt": "?", "options": ["A","B"], "answer": "B" } ] }';
    final QuizImportPayload p = QuizJsonParser.parse(json, fallbackName: 'Q');
    expect(p.name, 'Q');
    expect(p.questions.single.answerIndex, 1);
  });

  test('validation flags bad MCQ index, missing blank answer, reserved types', () {
    const String json = '''
    { "questions": [
      { "type": "mcq", "prompt": "x", "options": ["A","B"], "answer": 9 },
      { "type": "blank", "prompt": "y" },
      { "type": "matching", "prompt": "z" }
    ] }''';
    final ImportPreview preview =
        QuizJsonParser.validate(QuizJsonParser.parse(json));
    expect(preview.hasBlockingErrors, isTrue);
    expect(preview.errors.length, 2); // bad index + missing blank answer
    expect(preview.warnings.length, 1); // reserved matching type
  });

  test('a clean bank has no blocking errors', () {
    const String json =
        '{ "questions": [ { "type": "tf", "prompt": "ok", "answer": true } ] }';
    final ImportPreview preview =
        QuizJsonParser.validate(QuizJsonParser.parse(json));
    expect(preview.hasBlockingErrors, isFalse);
    expect(preview.byType[QuestionType.trueFalse], 1);
  });

  test('malformed JSON throws FormatException', () {
    expect(() => QuizJsonParser.parse('not json'), throwsFormatException);
  });
}
