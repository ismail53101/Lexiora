import 'dart:convert';

import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/quiz_duplicate_check.dart';
import 'package:lexiora/modules/quiz/domain/quiz_json.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_admin_repository.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';
import 'package:uuid/uuid.dart';

/// Hidden Admin implementation (no UI in this version). It is fully functional
/// so a future Admin CMS is a thin front-end over these calls; nothing in the
/// engine changes when the UI is added.
class QuizAdminRepositoryImpl implements QuizAdminRepository {
  QuizAdminRepositoryImpl(this._repo);

  final QuizRepository _repo;
  static const Uuid _uuid = Uuid();

  @override
  Future<QuizBank> createBank({
    required String name,
    String? subject,
    String? topic,
    String? description,
    int? color,
    String? tags,
    String? version,
  }) async {
    final DateTime now = DateTime.now();
    final QuizBank bank = QuizBank(
      id: _uuid.v4(),
      name: name,
      subject: subject,
      topic: topic,
      description: description,
      color: color,
      tags: tags,
      version: version,
      source: QuizContentSource.admin.id,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.saveBank(bank);
    return bank;
  }

  @override
  Future<void> updateBank(QuizBank bank) =>
      _repo.saveBank(bank.copyWith(updatedAt: DateTime.now()));

  @override
  Future<void> deleteBank(String id) => _repo.deleteBank(id);

  @override
  Future<int> importJson(
    String jsonText, {
    ImportStrategy strategy = ImportStrategy.merge,
    String? fallbackName,
  }) =>
      importJsonInto(
          jsonText: jsonText, strategy: strategy, fallbackName: fallbackName);

  @override
  Future<int> importJsonInto({
    required String jsonText,
    String? subjectId,
    String? topicId,
    ImportStrategy strategy = ImportStrategy.merge,
    String? fallbackName,
  }) async {
    final QuizImportPayload payload =
        QuizJsonParser.parse(jsonText, fallbackName: fallbackName);
    final ImportPreview preview = QuizJsonParser.validate(payload);
    if (preview.hasBlockingErrors) {
      throw FormatException(
          'Import blocked: ${preview.errors.length} error(s) in the JSON.');
    }
    return _repo.importPayload(payload, strategy,
        subjectId: subjectId, topicId: topicId);
  }

  static const QuizDuplicateChecker _duplicateChecker = QuizDuplicateChecker();

  @override
  Future<QuizDedupReport> addGeneratedQuestions({
    required String bankId,
    required List<QuizQuestion> candidates,
  }) async {
    // The full existing corpus: every question in every bank, so a generated
    // MCQ is checked against the ENTIRE question bank, not just its target.
    final List<QuizQuestion> corpus =
        await _repo.questions(const QuizFilter(), limit: 1 << 30);
    final DateTime now = DateTime.now();

    final List<QuizQuestion> saved = <QuizQuestion>[];
    final List<QuizDedupRejection> rejected = <QuizDedupRejection>[];

    for (final QuizQuestion candidate in candidates) {
      final DuplicateVerdict verdict =
          _duplicateChecker.check(candidate, corpus);
      if (verdict.isDuplicate) {
        rejected.add(QuizDedupRejection(
          candidate: candidate,
          kind: verdict.kind,
          matchedQuestionId: verdict.match?.id,
          reason: verdict.reason,
        ));
        continue;
      }

      // Fresh row: never reuse the candidate's id (could collide on re-seed)
      // and never touch existing rows.
      final QuizQuestion unique = QuizQuestion(
        id: _uuid.v4(),
        bankId: bankId,
        type: candidate.type,
        prompt: candidate.prompt,
        options: candidate.options,
        answerIndex: candidate.answerIndex,
        answerBool: candidate.answerBool,
        answerTexts: candidate.answerTexts,
        answerIndexes: candidate.answerIndexes,
        explanation: candidate.explanation,
        subject: candidate.subject,
        topic: candidate.topic,
        tags: candidate.tags,
        difficulty: candidate.difficulty,
        subjectId: candidate.subjectId,
        topicId: candidate.topicId,
        createdAt: now,
        updatedAt: now,
      );
      await _repo.saveQuestion(unique);
      saved.add(unique);
      // Accept the newly saved question into the corpus so later candidates
      // are also checked against it (no intra-batch duplicates).
      corpus.add(unique);
    }

    return QuizDedupReport(
      requested: candidates.length,
      saved: saved,
      rejected: rejected,
    );
  }

  @override
  Future<String> duplicateQuiz(String bankId) async {
    final QuizBank? src = await _repo.bank(bankId);
    if (src == null) throw StateError('Quiz not found: $bankId');
    final DateTime now = DateTime.now();
    final String newId = _uuid.v4();
    await _repo.saveBank(QuizBank(
      id: newId,
      name: '${src.name} (copy)',
      subject: src.subject,
      topic: src.topic,
      description: src.description,
      color: src.color,
      tags: src.tags,
      version: src.version,
      source: src.source,
      subjectId: src.subjectId,
      topicId: src.topicId,
      orderIndex: src.orderIndex + 1,
      createdAt: now,
      updatedAt: now,
    ));
    final List<QuizQuestion> questions =
        await _repo.questions(QuizFilter(bankId: bankId), limit: 1 << 30);
    for (final QuizQuestion q in questions) {
      await _repo.saveQuestion(QuizQuestion(
        id: _uuid.v4(),
        bankId: newId,
        type: q.type,
        prompt: q.prompt,
        options: q.options,
        answerIndex: q.answerIndex,
        answerBool: q.answerBool,
        answerTexts: q.answerTexts,
        answerIndexes: q.answerIndexes,
        explanation: q.explanation,
        subject: q.subject,
        topic: q.topic,
        tags: q.tags,
        difficulty: q.difficulty,
        subjectId: q.subjectId,
        topicId: q.topicId,
        createdAt: now,
        updatedAt: now,
      ));
    }
    return newId;
  }

  @override
  Future<void> moveQuiz(String bankId,
      {String? subjectId, String? topicId}) async {
    final QuizBank? src = await _repo.bank(bankId);
    if (src == null) return;
    await _repo.saveBank(src.copyWith(
      subjectId: subjectId,
      topicId: topicId,
      clearSubjectId: subjectId == null,
      clearTopicId: topicId == null,
      updatedAt: DateTime.now(),
    ));
    final List<QuizQuestion> questions =
        await _repo.questions(QuizFilter(bankId: bankId), limit: 1 << 30);
    for (final QuizQuestion q in questions) {
      await _repo.saveQuestion(
          q.copyWith(subjectId: subjectId, topicId: topicId));
    }
  }

  @override
  Future<String> exportBankJson(String bankId) async {
    final QuizBank? bank = await _repo.bank(bankId);
    if (bank == null) throw StateError('Bank not found: $bankId');
    final List<QuizQuestion> questions =
        await _repo.questions(QuizFilter(bankId: bankId), limit: 1 << 30);
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'bank': <String, dynamic>{
        'name': bank.name,
        'subject': bank.subject,
        'topic': bank.topic,
        'description': bank.description,
        'color': bank.color,
        'tags': bank.tags,
        'version': bank.version,
        'id': bank.externalId ?? bank.id,
      },
      'questions':
          questions.map((QuizQuestion q) => _questionJson(q)).toList(),
    });
  }

  @override
  Future<void> publishUpdates() async {
    // Future hook (e.g. push to Cloud). Intentionally a no-op in this version.
  }

  Map<String, dynamic> _questionJson(QuizQuestion q) {
    dynamic answer;
    switch (q.type) {
      case QuestionType.mcqSingle:
        answer = q.answerIndex;
      case QuestionType.trueFalse:
        answer = q.answerBool;
      case QuestionType.fillBlank:
        answer = q.answerTexts;
      case QuestionType.multiCorrect:
        answer = q.answerIndexes;
      case QuestionType.matching:
        answer = null;
    }
    return <String, dynamic>{
      'type': q.type.name,
      'prompt': q.prompt,
      if (q.options.isNotEmpty) 'options': q.options,
      'answer': answer,
      if (q.explanation != null) 'explanation': q.explanation,
      if (q.subject != null) 'subject': q.subject,
      if (q.topic != null) 'topic': q.topic,
      if (q.tags != null) 'tags': q.tags,
      'difficulty': q.difficulty.name,
      if (q.externalId != null) 'id': q.externalId,
    };
  }
}
