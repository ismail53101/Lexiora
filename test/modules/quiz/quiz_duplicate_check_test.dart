import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:lexiora/modules/quiz/data/repositories/quiz_admin_repository_impl.dart';
import 'package:lexiora/modules/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/quiz_duplicate_check.dart';

void main() {
  final DateTime now = DateTime.now();
  const QuizDuplicateChecker checker = QuizDuplicateChecker();

  QuizQuestion mcq(
    String id,
    String bankId,
    String prompt, {
    List<String> options = const <String>['A', 'B', 'C'],
    int answerIndex = 0,
  }) =>
      QuizQuestion(
        id: id,
        bankId: bankId,
        type: QuestionType.mcqSingle,
        prompt: prompt,
        options: options,
        answerIndex: answerIndex,
        createdAt: now,
        updatedAt: now,
      );

  group('QuizDuplicateChecker', () {
    test('exact duplicate is rejected', () {
      final QuizQuestion existing = mcq(
          'e1', 'b1', 'What is the capital of Punjab?',
          options: const <String>['Lahore', 'Karachi', 'Peshawar']);
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'What is the capital of Punjab?',
          options: const <String>['Lahore', 'Karachi', 'Peshawar']);

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isTrue);
      expect(v.kind, DuplicateKind.exact);
      expect(v.match?.id, 'e1');
    });

    test('same question with reordered options is rejected', () {
      final QuizQuestion existing = mcq(
          'e1', 'b1', 'What is the capital of Punjab?',
          options: const <String>['Lahore', 'Karachi', 'Peshawar']);
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'What is the capital of Punjab?',
          options: const <String>['Peshawar', 'Lahore', 'Karachi'], answerIndex: 1);

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isTrue);
      expect(v.kind, DuplicateKind.reorderedOptions);
    });

    test('same question with different options is rejected', () {
      final QuizQuestion existing = mcq(
          'e1', 'b1', 'What is the capital of Punjab?',
          options: const <String>['Lahore', 'Karachi', 'Peshawar']);
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'What is the capital of Punjab?',
          options: const <String>['Lahore', 'Multan', 'Faisalabad']);

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isTrue);
      expect(v.kind, DuplicateKind.differentOptions);
    });

    test('reworded duplicate with the same answer is rejected', () {
      final QuizQuestion existing = mcq(
          'e1', 'b1', 'What is the national animal of Pakistan?',
          options: const <String>['Markhor', 'Lion', 'Tiger']);
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'Which animal is the national animal of Pakistan?',
          options: const <String>['Markhor', 'Leopard', 'Bear']);

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isTrue);
      expect(v.kind, DuplicateKind.reworded);
    });

    test('same-concept paraphrase is rejected even when short', () {
      final QuizQuestion existing = mcq(
          'e1', 'b1',
          'Which companion of the Prophet was given the title Sword of Allah?',
          options: const <String>['Khalid bin Waleed', 'Ali', 'Umar']);
      // All of the candidate's significant tokens sit inside the longer
      // existing prompt, but its Jaccard overlap is below the reworded bar —
      // this is the same-concept (containment) case.
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'Sword of Allah was the title of whom?',
          options: const <String>['Khalid bin Waleed', 'Abu Bakr', 'Uthman']);

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isTrue);
      expect(v.kind, DuplicateKind.sameConcept);
    });

    test('generic instruction stem with different correct sentences stays unique', () {
      final QuizQuestion existing = mcq(
          'e1', 'b1', 'Choose the correct sentence:',
          options: const <String>[
            'He asked me where I was going.',
            'He asked me where was I going.',
            'He asked me that where I was going.',
          ],
          );
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'Choose the correct sentence:',
          options: const <String>[
            'He is afraid of dogs.',
            'He is afraid from dogs.',
            'He is afraid at dogs.',
          ],
          );

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isFalse, reason: 'different sentences = different questions');
    });

    test('generic instruction stem with the SAME correct sentence is rejected', () {
      final QuizQuestion existing = mcq(
          'e1', 'b1', 'Choose the correct sentence:',
          options: const <String>[
            'He asked me where I was going.',
            'He asked me where was I going.',
            'He asked me that where I was going.',
          ],
          );
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'Choose the correct sentence:',
          options: const <String>[
            'He asked me where I was going.',
            'He asked me where I had gone.',
            'He asked me where was I going.',
          ],
          );

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isTrue);
      expect(v.kind, DuplicateKind.differentOptions);
    });

    test('same answer but a DIFFERENT fact is kept (unique)', () {
      // Both are Iskander Mirza, but they ask different facts (office vs office).
      final QuizQuestion existing = mcq(
          'e1', 'b1', 'Who was the first President of Pakistan?',
          options: const <String>['Iskander Mirza', 'Ayub Khan', 'Yahya Khan']);
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'Who was the last Governor-General of Pakistan?',
          options: const <String>['Iskander Mirza', 'Ghulam Muhammad', 'Malik Ghulam']);

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isFalse);
    });

    test('same answer but a DIFFERENT landmark is kept (unique)', () {
      final QuizQuestion existing = mcq(
          'e1', 'b1', 'Where is the Badshahi Mosque located?',
          options: const <String>['Lahore', 'Karachi', 'Multan']);
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'Where are the Shalimar Gardens located?',
          options: const <String>['Lahore', 'Peshawar', 'Quetta']);

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isFalse);
    });

    test('genuinely new question passes', () {
      final QuizQuestion existing = mcq(
          'e1', 'b1', 'What is the capital of Punjab?',
          options: const <String>['Lahore', 'Karachi', 'Peshawar']);
      final QuizQuestion candidate = mcq(
          'c1', 'b2', 'Who wrote the national anthem of Pakistan?',
          options: const <String>['Hafeez Jalandhari', 'Allama Iqbal', 'Faiz']);

      final DuplicateVerdict v = checker.check(candidate, <QuizQuestion>[existing]);
      expect(v.isDuplicate, isFalse);
    });

    test('normalization ignores case, punctuation and whitespace', () {
      expect(QuizDuplicateChecker.normalizePrompt('  What IS the  Capital? '),
          'what is the capital');
    });
  });

  group('QuizAdminRepositoryImpl.addGeneratedQuestions', () {
    late AppDatabase db;
    late QuizRepositoryImpl repo;
    late QuizAdminRepositoryImpl admin;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = QuizRepositoryImpl(QuizLocalDataSource(db));
      admin = QuizAdminRepositoryImpl(repo);
    });

    tearDown(() async {
      await db.close();
    });

    test('saves only unique candidates and rejects duplicates', () async {
      await repo.saveBank(QuizBank(
          id: 'b1', name: 'Pakistan Affairs', createdAt: now, updatedAt: now));

      // Pre-existing content in the bank (never to be modified).
      await repo.saveQuestion(mcq(
          'e1', 'b1', 'What is the capital of Punjab?',
          options: const <String>['Lahore', 'Karachi', 'Peshawar']));

      final QuizDedupReport report = await admin.addGeneratedQuestions(
        bankId: 'b1',
        candidates: <QuizQuestion>[
          mcq('c1', 'b1', 'What is the capital of Punjab?', // exact dup
              options: const <String>['Lahore', 'Karachi', 'Peshawar']),
          mcq('c2', 'b1', 'Which city is the capital of Punjab?', // reworded dup
              options: const <String>['Lahore', 'Multan', 'Sialkot']),
          mcq('c3', 'b1', 'Who wrote the national anthem of Pakistan?', // unique
              options: const <String>['Hafeez Jalandhari', 'Iqbal', 'Faiz']),
          mcq('c4', 'b1', 'When did Pakistan gain independence?', // unique
              options: const <String>['1947', '1948', '1956']),
        ],
      );

      expect(report.requested, 4);
      expect(report.savedCount, 2, reason: 'two of four are duplicates');
      expect(report.rejectedCount, 2);
      expect(report.rejected[0].kind, DuplicateKind.exact);
      expect(report.rejected[0].matchedQuestionId, 'e1');
      expect(report.rejected[1].kind, DuplicateKind.reworded);
      expect(report.rejected[1].matchedQuestionId, 'e1');

      // Existing row untouched; exactly 3 questions in the bank now.
      final List<QuizQuestion> all =
          await repo.questions(const QuizFilter(), limit: 1 << 30);
      expect(all.length, 3);
      expect(all.map((QuizQuestion q) => q.prompt),
          contains('What is the capital of Punjab?'));
      final QuizQuestion? existing =
          await repo.question('e1');
      expect(existing?.prompt, 'What is the capital of Punjab?');
    });

    test('intra-batch duplicates are also caught (second copy rejected)', () async {
      await repo.saveBank(QuizBank(
          id: 'b1', name: 'English', createdAt: now, updatedAt: now));

      final QuizDedupReport report = await admin.addGeneratedQuestions(
        bankId: 'b1',
        candidates: <QuizQuestion>[
          mcq('c1', 'b1', 'What is the antonym of "ancient"?',
              options: const <String>['Modern', 'Old', 'Elderly']),
          mcq('c2', 'b1', 'What is the antonym of "ancient"?',
              options: const <String>['Modern', 'Old', 'Elderly']),
        ],
      );

      expect(report.savedCount, 1);
      expect(report.rejectedCount, 1);
      expect(report.rejected.single.kind, DuplicateKind.exact);
      expect((await repo.questions(const QuizFilter(), limit: 1 << 30)).length, 1);
    });

    test('re-running the same batch never creates duplicates', () async {
      await repo.saveBank(QuizBank(
          id: 'b1', name: 'GSA', createdAt: now, updatedAt: now));
      final List<QuizQuestion> candidates = <QuizQuestion>[
        mcq('c1', 'b1', 'What is the SI unit of force?',
            options: const <String>['Newton', 'Joule', 'Watt']),
      ];

      final QuizDedupReport first = await admin.addGeneratedQuestions(
          bankId: 'b1', candidates: candidates);
      expect(first.savedCount, 1);

      // Second run with identical candidates: everything rejected.
      final QuizDedupReport second = await admin.addGeneratedQuestions(
          bankId: 'b1', candidates: candidates);
      expect(second.savedCount, 0);
      expect(second.rejectedCount, 1);

      final int total = await repo.countQuestions(const QuizFilter());
      expect(total, 1, reason: 'no duplicate rows after re-run');
    });
  });
}
