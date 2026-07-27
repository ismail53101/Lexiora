import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:lexiora/modules/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_settings.dart';
import 'package:lexiora/modules/quiz/domain/quiz_grading.dart';
import 'package:lexiora/modules/quiz/domain/quiz_json.dart';

void main() {
  late AppDatabase db;
  late QuizRepositoryImpl repo;
  final DateTime now = DateTime.now();

  QuizBank bank(String id, {String? name, String? subject, String? externalId}) =>
      QuizBank(
        id: id,
        name: name ?? 'Bank $id',
        subject: subject,
        externalId: externalId,
        createdAt: now,
        updatedAt: now,
      );

  QuizQuestion mcq(
    String id,
    String bankId, {
    String prompt = 'prompt',
    int answerIndex = 0,
    String? subject,
    QuizDifficulty difficulty = QuizDifficulty.none,
    bool bookmarked = false,
    String? externalId,
  }) =>
      QuizQuestion(
        id: id,
        bankId: bankId,
        type: QuestionType.mcqSingle,
        prompt: prompt,
        options: const <String>['A', 'B', 'C'],
        answerIndex: answerIndex,
        subject: subject,
        difficulty: difficulty,
        bookmarked: bookmarked,
        externalId: externalId,
        createdAt: now,
        updatedAt: now,
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = QuizRepositoryImpl(QuizLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('bank CRUD with computed question count', () async {
    await repo.saveBank(bank('b1', name: 'English MCQs'));
    await repo.saveQuestion(mcq('q1', 'b1'));
    await repo.saveQuestion(mcq('q2', 'b1'));

    final List<QuizBankSummary> banks = await repo.watchBanks().first;
    expect(banks.single.bank.name, 'English MCQs');
    expect(banks.single.questionCount, 2);

    await repo.setBankArchived('b1', true);
    expect(await repo.watchBanks().first, isEmpty);
    expect((await repo.watchBanks(includeArchived: true).first).length, 1);

    await repo.deleteBank('b1');
    expect(await repo.countQuestions(const QuizFilter()), 0);
  });

  test('question search: text, subject, difficulty, bookmark, type, sort',
      () async {
    await repo.saveBank(bank('b1'));
    await repo.saveQuestion(mcq('q1', 'b1',
        prompt: 'Alpha physics', subject: 'Physics', bookmarked: true));
    await repo.saveQuestion(mcq('q2', 'b1',
        prompt: 'Beta english',
        subject: 'English',
        difficulty: QuizDifficulty.hard));
    await repo.saveQuestion(mcq('q3', 'b1', prompt: 'Gamma physics', subject: 'Physics'));

    Future<List<String>> ids(QuizFilter f) async =>
        (await repo.questions(f)).map((QuizQuestion q) => q.id).toList();

    expect(await ids(const QuizFilter(query: 'physics')),
        containsAll(<String>['q1', 'q3']));
    expect(await ids(const QuizFilter(subject: 'Physics')),
        containsAll(<String>['q1', 'q3']));
    expect(await ids(const QuizFilter(onlyBookmarked: true)), <String>['q1']);
    expect(await ids(const QuizFilter(difficulty: QuizDifficulty.hard)),
        <String>['q2']);
    expect(await ids(const QuizFilter(type: QuestionType.mcqSingle)).then(
            (List<String> l) => l.length),
        3);
    expect(await ids(const QuizFilter(sort: QuizSort.alphabetical)),
        <String>['q1', 'q2', 'q3']);
    expect(await repo.countQuestions(const QuizFilter()), 3);
  });

  test('import: JSON payload creates a bank and questions', () async {
    const String json = '''
    { "bank": { "name": "GK", "subject": "General", "id": "gk1" },
      "questions": [
        { "type": "mcq", "prompt": "q1", "options": ["A","B"], "answer": 1, "id": "e1" },
        { "type": "truefalse", "prompt": "q2", "answer": true, "id": "e2" }
      ] }''';
    final QuizImportPayload payload = QuizJsonParser.parse(json);
    final int n = await repo.importPayload(payload, ImportStrategy.merge);
    expect(n, 2);

    final List<QuizBankSummary> banks = await repo.watchBanks().first;
    expect(banks.single.bank.name, 'GK');
    expect(banks.single.bank.externalId, 'gk1');
    expect(banks.single.questionCount, 2);
  });

  test('import merge dedups by external id; replace wipes first', () async {
    const String v1 = '''
    { "bank": { "name": "GK", "id": "gk1" },
      "questions": [ { "type": "tf", "prompt": "a", "answer": true, "id": "e1" } ] }''';
    const String v2 = '''
    { "bank": { "name": "GK", "id": "gk1" },
      "questions": [
        { "type": "tf", "prompt": "a", "answer": true, "id": "e1" },
        { "type": "tf", "prompt": "b", "answer": false, "id": "e2" }
      ] }''';

    await repo.importPayload(QuizJsonParser.parse(v1), ImportStrategy.merge);
    // Merge: e1 already present, only e2 is added → 1 new, 2 total.
    final int merged =
        await repo.importPayload(QuizJsonParser.parse(v2), ImportStrategy.merge);
    expect(merged, 1);
    expect((await repo.watchBanks().first).single.questionCount, 2);

    // Replace: wipes and re-adds everything in v2 → 2 total (not 4).
    await repo.importPayload(QuizJsonParser.parse(v2), ImportStrategy.replace);
    expect((await repo.watchBanks().first).single.questionCount, 2);
  });

  test('recordAttempt updates stats, wrong notebook, review and history',
      () async {
    await repo.saveBank(bank('b1', subject: 'Physics'));
    final QuizQuestion q1 = mcq('q1', 'b1', answerIndex: 1, subject: 'Physics');
    final QuizQuestion q2 = mcq('q2', 'b1', answerIndex: 2, subject: 'Physics');
    final QuizQuestion q3 = mcq('q3', 'b1', subject: 'Physics');
    await repo.saveQuestion(q1);
    await repo.saveQuestion(q2);
    await repo.saveQuestion(q3);

    final QuizAttempt attempt = await repo.recordAttempt(
      mode: QuizMode.practice,
      bankId: 'b1',
      durationMs: 30000,
      outcomes: <QuestionOutcome>[
        QuestionOutcome(
            question: q1, given: const QuizGivenAnswer.choice(1), skipped: false), // correct
        QuestionOutcome(
            question: q2, given: const QuizGivenAnswer.choice(0), skipped: false), // wrong
        QuestionOutcome(question: q3, given: null, skipped: true), // skipped
      ],
    );

    expect(attempt.correct, 1);
    expect(attempt.wrong, 1);
    expect(attempt.skipped, 1);

    final QuizStats s = await repo.watchStats().first;
    expect(s.totalQuizzes, 1);
    expect(s.correct, 1);
    expect(s.wrong, 1);
    expect(s.accuracy, 50);

    // Wrong-answer notebook auto-populated with q2 only.
    expect(await repo.watchWrongCount().first, 1);
    final List<WrongAnswerEntry> wrong = await repo.wrongAnswers();
    expect(wrong.single.question.id, 'q2');

    // Review reconstructs the answered questions in order.
    final List<AnsweredQuestion> review = await repo.attemptReview(attempt.id);
    expect(review.length, 3);
    expect(review[0].isCorrect, isTrue);
    expect(review[1].isCorrect, isFalse);
    expect(review[2].skipped, isTrue);

    // History stream.
    expect((await repo.watchAttempts().first).single.id, attempt.id);
  });

  test('onlyWrong filter surfaces questions in the notebook', () async {
    await repo.saveBank(bank('b1'));
    final QuizQuestion q1 = mcq('q1', 'b1', answerIndex: 1);
    await repo.saveQuestion(q1);
    await repo.recordAttempt(
      mode: QuizMode.practice,
      bankId: 'b1',
      outcomes: <QuestionOutcome>[
        QuestionOutcome(
            question: q1, given: const QuizGivenAnswer.choice(0), skipped: false),
      ],
    );
    final List<QuizQuestion> wrongQs =
        await repo.questions(const QuizFilter(onlyWrong: true));
    expect(wrongQs.single.id, 'q1');

    await repo.clearWrongAnswers();
    expect(await repo.watchWrongCount().first, 0);
  });

  test('bookmarks toggle and count', () async {
    await repo.saveBank(bank('b1'));
    await repo.saveQuestion(mcq('q1', 'b1'));
    await repo.setBookmarked('q1', true);
    expect(await repo.watchBookmarkCount().first, 1);
    expect((await repo.questions(const QuizFilter(onlyBookmarked: true))).single.id,
        'q1');
  });

  test('strongest/weakest subjects need a few samples', () async {
    await repo.saveBank(bank('b1'));
    final List<QuizQuestion> phys = <QuizQuestion>[
      for (int i = 0; i < 3; i++)
        mcq('p$i', 'b1', answerIndex: 1, subject: 'Physics'),
    ];
    final List<QuizQuestion> eng = <QuizQuestion>[
      for (int i = 0; i < 3; i++)
        mcq('e$i', 'b1', answerIndex: 1, subject: 'English'),
    ];
    for (final QuizQuestion q in <QuizQuestion>[...phys, ...eng]) {
      await repo.saveQuestion(q);
    }
    await repo.recordAttempt(
      mode: QuizMode.exam,
      outcomes: <QuestionOutcome>[
        for (final QuizQuestion q in phys)
          QuestionOutcome(
              question: q, given: const QuizGivenAnswer.choice(1), skipped: false),
        for (final QuizQuestion q in eng)
          QuestionOutcome(
              question: q, given: const QuizGivenAnswer.choice(0), skipped: false),
      ],
    );
    final QuizStats s = await repo.watchStats().first;
    expect(s.strongestSubject?.subject, 'Physics');
    expect(s.weakestSubject?.subject, 'English');
  });

  test('subject colours are read (not duplicated) from Study Hub', () async {
    await db.into(db.studySubjects).insert(StudySubjectsCompanion.insert(
          id: 's1',
          name: 'Physics',
          nameLower: 'physics',
          color: 0xFF2196F3,
          createdAt: now,
          updatedAt: now,
        ));
    expect((await repo.watchSubjectColors().first)['physics'], 0xFF2196F3);
  });

  test('settings round-trip', () async {
    expect((await repo.loadSettings()).questionsPerQuiz, 0);
    await repo.saveSettings(const QuizSettings(
        questionsPerQuiz: 20, defaultMode: QuizMode.exam, shuffleQuestions: false));
    final QuizSettings s = await repo.loadSettings();
    expect(s.questionsPerQuiz, 20);
    expect(s.defaultMode, QuizMode.exam);
    expect(s.shuffleQuestions, isFalse);
  });

  test('backup round-trips banks, questions, attempts and wrong answers',
      () async {
    await repo.saveBank(bank('b1', name: 'Keep me'));
    final QuizQuestion q1 = mcq('q1', 'b1', answerIndex: 1);
    await repo.saveQuestion(q1);
    await repo.recordAttempt(
      mode: QuizMode.practice,
      bankId: 'b1',
      outcomes: <QuestionOutcome>[
        QuestionOutcome(
            question: q1, given: const QuizGivenAnswer.choice(0), skipped: false),
      ],
    );

    final Map<String, dynamic> backup = await repo.exportBackup();
    expect((backup['banks'] as List<dynamic>).length, 1);
    expect((backup['questions'] as List<dynamic>).length, 1);
    expect((backup['attempts'] as List<dynamic>).length, 1);
    expect((backup['wrong'] as List<dynamic>).length, 1);

    await repo.deleteBank('b1');
    await repo.clearWrongAnswers();
    expect(await repo.countQuestions(const QuizFilter()), 0);

    await repo.importBackup(backup);
    expect((await repo.watchBanks().first).single.bank.name, 'Keep me');
    expect(await repo.countQuestions(const QuizFilter()), 1);
    expect(await repo.watchWrongCount().first, 1);
  });
}
