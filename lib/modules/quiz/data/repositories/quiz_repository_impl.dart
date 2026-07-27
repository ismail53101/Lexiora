import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_content.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_settings.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_topic.dart';
import 'package:lexiora/modules/quiz/domain/quiz_dates.dart';
import 'package:lexiora/modules/quiz/domain/quiz_grading.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';
import 'package:uuid/uuid.dart';

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._local);

  final QuizLocalDataSource _local;
  static const Uuid _uuid = Uuid();

  // ── Subjects (v0.9.1) ────────────────────────────────────────────────────────

  @override
  Stream<List<QuizSubjectSummary>> watchSubjects({bool includeArchived = false}) =>
      _local.watchSubjectSummaries(includeArchived).map((List<QueryRow> rows) =>
          rows
              .map((QueryRow r) => QuizSubjectSummary(
                    subject: _toSubject(_local.subjectRowFrom(r)),
                    topicCount: r.read<int>('topic_count'),
                    questionCount: r.read<int>('question_count'),
                  ))
              .toList(growable: false));

  @override
  Future<QuizSubject?> subject(String id) async {
    final QuizSubjectRow? r = await _local.subject(id);
    return r == null ? null : _toSubject(r);
  }

  @override
  Future<void> saveSubject(QuizSubject s) =>
      _local.upsertSubject(_subjectCompanion(s));

  @override
  Future<void> deleteSubject(String id) => _local.deleteSubject(id);

  @override
  Future<void> reorderSubjects(List<String> orderedIds) =>
      _local.reorder('quiz_subjects', orderedIds);

  // ── Topics ───────────────────────────────────────────────────────────────────

  @override
  Stream<List<QuizTopicSummary>> watchTopics(String subjectId,
          {bool includeArchived = false}) =>
      _local.watchTopicSummaries(subjectId, includeArchived).map(
          (List<QueryRow> rows) => rows
              .map((QueryRow r) => QuizTopicSummary(
                    topic: _toTopic(_local.topicRowFrom(r)),
                    quizCount: r.read<int>('quiz_count'),
                    questionCount: r.read<int>('question_count'),
                  ))
              .toList(growable: false));

  @override
  Future<QuizTopic?> topic(String id) async {
    final QuizTopicRow? r = await _local.topic(id);
    return r == null ? null : _toTopic(r);
  }

  @override
  Future<void> saveTopic(QuizTopic t) => _local.upsertTopic(_topicCompanion(t));

  @override
  Future<void> deleteTopic(String id) => _local.deleteTopic(id);

  @override
  Future<void> reorderTopics(String subjectId, List<String> orderedIds) =>
      _local.reorder('quiz_topics', orderedIds);

  // ── Banks ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<QuizBankSummary>> watchBanksIn({
    String? subjectId,
    String? topicId,
    bool topicless = false,
    bool includeArchived = false,
  }) =>
      _local
          .watchBankSummariesIn(
            subjectId: subjectId,
            topicId: topicId,
            topicIsNull: topicless,
            includeArchived: includeArchived,
          )
          .map((List<QueryRow> rows) => rows
              .map((QueryRow r) => QuizBankSummary(
                    bank: _toBank(_local.bankRowFrom(r)),
                    questionCount: r.read<int>('question_count'),
                  ))
              .toList(growable: false));

  @override
  Stream<List<QuizBankSummary>> watchBanks({bool includeArchived = false}) =>
      _local.watchBankSummaries(includeArchived).map((List<QueryRow> rows) => rows
          .map((QueryRow r) => QuizBankSummary(
                bank: _toBank(_local.bankRowFrom(r)),
                questionCount: r.read<int>('question_count'),
              ))
          .toList(growable: false));

  @override
  Future<QuizBank?> bank(String id) async {
    final QuizBankRow? r = await _local.bank(id);
    return r == null ? null : _toBank(r);
  }

  @override
  Future<void> saveBank(QuizBank b) => _local.upsertBank(_bankCompanion(b));

  @override
  Future<void> setBankArchived(String id, bool archived) => _local.updateBank(
      id,
      QuizBanksCompanion(
          archived: Value<bool>(archived),
          updatedAt: Value<DateTime>(DateTime.now())));

  @override
  Future<void> deleteBank(String id) => _local.deleteBank(id);

  // ── Questions ───────────────────────────────────────────────────────────────

  @override
  Future<List<QuizQuestion>> questions(QuizFilter filter,
          {int limit = 50, int offset = 0}) async =>
      (await _local.searchQuestions(filter, limit: limit, offset: offset))
          .map(_toQuestion)
          .toList();

  @override
  Future<int> countQuestions(QuizFilter filter) => _local.countQuestions(filter);

  @override
  Future<QuizQuestion?> question(String id) async {
    final QuizQuestionRow? r = await _local.question(id);
    return r == null ? null : _toQuestion(r);
  }

  @override
  Future<void> saveQuestion(QuizQuestion q) =>
      _local.upsertQuestion(_questionCompanion(q));

  @override
  Future<void> deleteQuestion(String id) => _local.deleteQuestion(id);

  @override
  Future<void> setBookmarked(String id, bool value) => _local.updateQuestion(
      id,
      QuizQuestionsCompanion(
          bookmarked: Value<bool>(value),
          updatedAt: Value<DateTime>(DateTime.now())));

  // ── Play / attempts ─────────────────────────────────────────────────────────

  @override
  Future<List<QuizQuestion>> buildSession({
    String? bankId,
    QuizFilter? filter,
    int limit = 50,
    bool shuffle = true,
  }) async {
    final QuizFilter f =
        (filter ?? const QuizFilter()).copyWith(bankId: bankId);
    return (await _local.session(f, limit: limit, shuffle: shuffle))
        .map(_toQuestion)
        .toList();
  }

  @override
  Future<QuizAttempt> recordAttempt({
    required QuizMode mode,
    required List<QuestionOutcome> outcomes,
    String? bankId,
    String? title,
    int durationMs = 0,
  }) async {
    final GradedAttempt g = gradeAttempt(outcomes);
    final DateTime now = DateTime.now();
    final DateTime started =
        now.subtract(Duration(milliseconds: durationMs.clamp(0, 1 << 31)));
    final String attemptId = _uuid.v4();

    await _local.insertAttempt(QuizAttemptsCompanion.insert(
      id: attemptId,
      bankId: Value<String?>(bankId),
      mode: Value<int>(mode.index),
      title: Value<String?>(title),
      totalQuestions: Value<int>(g.total),
      correct: Value<int>(g.correct),
      wrong: Value<int>(g.wrong),
      skipped: Value<int>(g.skipped),
      startedAt: started,
      finishedAt: Value<DateTime?>(now),
      durationMs: Value<int>(durationMs),
      day: Value<String>(todayKey()),
      createdAt: now,
    ));

    final List<QuizAttemptAnswersCompanion> answers =
        <QuizAttemptAnswersCompanion>[];
    for (int i = 0; i < outcomes.length; i++) {
      final QuestionOutcome o = outcomes[i];
      final bool skipped =
          o.skipped || o.given == null || o.given!.isEmpty;
      answers.add(QuizAttemptAnswersCompanion.insert(
        id: _uuid.v4(),
        attemptId: attemptId,
        questionId: o.question.id,
        givenJson: Value<String?>(
            o.given == null ? null : jsonEncode(o.given!.toJson())),
        isCorrect: Value<bool>(o.isCorrect),
        skipped: Value<bool>(skipped),
        subject: Value<String?>(o.question.subject),
        orderIndex: Value<int>(i),
        timeMs: Value<int>(o.timeMs),
        createdAt: now,
      ));
    }
    await _local.insertAnswers(answers);

    // Auto-populate the Wrong-Answer Notebook (dedup by question).
    for (final QuestionOutcome o in outcomes) {
      final bool isWrong = !o.skipped &&
          o.given != null &&
          !o.given!.isEmpty &&
          !o.isCorrect;
      if (!isWrong) continue;
      final QuizWrongRow? existing = await _local.wrong(o.question.id);
      await _local.upsertWrong(QuizWrongAnswersCompanion.insert(
        questionId: o.question.id,
        bankId: Value<String?>(o.question.bankId),
        subject: Value<String?>(o.question.subject),
        lastGivenJson: Value<String?>(jsonEncode(o.given!.toJson())),
        wrongCount: Value<int>((existing?.wrongCount ?? 0) + 1),
        lastWrongAt: now,
        createdAt: existing?.createdAt ?? now,
      ));
    }

    return QuizAttempt(
      id: attemptId,
      bankId: bankId,
      mode: mode,
      title: title,
      totalQuestions: g.total,
      correct: g.correct,
      wrong: g.wrong,
      skipped: g.skipped,
      startedAt: started,
      finishedAt: now,
      durationMs: durationMs,
    );
  }

  @override
  Stream<List<QuizAttempt>> watchAttempts({int limit = 50}) => _local
      .watchAttempts(limit)
      .map((List<QuizAttemptRow> rows) =>
          rows.map(_toAttempt).toList(growable: false));

  @override
  Future<List<AnsweredQuestion>> attemptReview(String attemptId) async {
    final List<QuizAnswerRow> answers = await _local.attemptAnswers(attemptId);
    final List<QuizQuestionRow> qRows = await _local
        .questionsByIds(answers.map((QuizAnswerRow a) => a.questionId).toList());
    final Map<String, QuizQuestion> byId = <String, QuizQuestion>{
      for (final QuizQuestionRow r in qRows) r.id: _toQuestion(r),
    };
    final List<AnsweredQuestion> out = <AnsweredQuestion>[];
    for (final QuizAnswerRow a in answers) {
      final QuizQuestion? q = byId[a.questionId];
      if (q == null) continue; // question deleted since the attempt
      out.add(AnsweredQuestion(
        question: q,
        given: _decodeGiven(a.givenJson),
        isCorrect: a.isCorrect,
        skipped: a.skipped,
      ));
    }
    return out;
  }

  // ── Wrong-answer notebook ───────────────────────────────────────────────────

  @override
  Future<List<WrongAnswerEntry>> wrongAnswers(
      {String? subjectId, int limit = 50, int offset = 0}) async {
    final List<QuizWrongRow> rows = await _local.wrongAnswers(
        subjectId: subjectId, limit: limit, offset: offset);
    final Map<String, QuizQuestion> byId = <String, QuizQuestion>{
      for (final QuizQuestionRow r
          in await _local.questionsByIds(rows.map((QuizWrongRow w) => w.questionId).toList()))
        r.id: _toQuestion(r),
    };
    final List<WrongAnswerEntry> out = <WrongAnswerEntry>[];
    for (final QuizWrongRow w in rows) {
      final QuizQuestion? q = byId[w.questionId];
      if (q == null) continue;
      out.add(WrongAnswerEntry(
        question: q,
        wrongCount: w.wrongCount,
        lastWrongAt: w.lastWrongAt,
        lastGiven: _decodeGiven(w.lastGivenJson),
      ));
    }
    return out;
  }

  @override
  Future<void> deleteWrongAnswer(String questionId) =>
      _local.deleteWrong(questionId);

  @override
  Future<void> clearWrongAnswers() => _local.clearWrong();

  @override
  Stream<int> watchWrongCount() => _local.watchWrongCount();

  // ── Bookmarks / analytics ───────────────────────────────────────────────────

  @override
  Stream<int> watchBookmarkCount() => _local.watchBookmarkCount();

  @override
  Future<List<SubjectAccuracy>> subjectAccuracies() async =>
      (await _local.subjectAccuracies())
          .map((SubjectAgg a) => SubjectAccuracy(
              subject: a.subject, correct: a.correct, total: a.total))
          .toList();

  @override
  Stream<QuizStats> watchStats() =>
      _local.watchStats().asyncMap((StatsAgg a) async {
        final List<SubjectAgg> subs = await _local.subjectAccuracies();
        SubjectAccuracy? strongest;
        SubjectAccuracy? weakest;
        for (final SubjectAgg s in subs) {
          if (s.total < 3) continue; // ignore tiny samples
          final SubjectAccuracy acc = SubjectAccuracy(
              subject: s.subject, correct: s.correct, total: s.total);
          if (strongest == null || acc.accuracy > strongest.accuracy) {
            strongest = acc;
          }
          if (weakest == null || acc.accuracy < weakest.accuracy) {
            weakest = acc;
          }
        }
        return QuizStats(
          totalQuizzes: a.totalQuizzes,
          questionsSolved: a.correct + a.wrong,
          correct: a.correct,
          wrong: a.wrong,
          skipped: a.skipped,
          totalTimeMs: a.totalTimeMs,
          dailyQuizzes: a.daily,
          weeklyQuizzes: a.weekly,
          monthlyQuizzes: a.monthly,
          strongestSubject: strongest,
          weakestSubject: weakest,
        );
      });

  // ── Colours + suggestions ───────────────────────────────────────────────────

  @override
  Stream<Map<String, int>> watchSubjectColors() =>
      _local.watchSubjectRows().map((List<StudySubjectRow> rows) =>
          <String, int>{for (final StudySubjectRow r in rows) r.nameLower: r.color});

  @override
  Future<List<String>> subjectSuggestions() => _local.subjectValues();

  @override
  Future<List<String>> tagSuggestions() async {
    final List<String> raw = await _local.tagRawValues();
    final Set<String> tags = <String>{};
    for (final String v in raw) {
      for (final String t in v.split(',')) {
        final String tt = t.trim();
        if (tt.isNotEmpty) tags.add(tt);
      }
    }
    final List<String> list = tags.toList()
      ..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  // ── Settings ─────────────────────────────────────────────────────────────────

  @override
  Future<QuizSettings> loadSettings() async =>
      QuizSettings.fromMap(await _local.allSettings());

  @override
  Future<void> saveSettings(QuizSettings settings) =>
      _local.saveSettings(settings.toMap());

  // ── Import ────────────────────────────────────────────────────────────────────

  @override
  Future<int> importPayload(QuizImportPayload payload, ImportStrategy strategy,
      {String? subjectId, String? topicId}) async {
    final DateTime now = DateTime.now();

    QuizBankRow? existing;
    if (payload.externalId != null && payload.externalId!.isNotEmpty) {
      existing = await _local.bankByExternalId(payload.externalId!);
    }

    final String bankId = existing?.id ?? _uuid.v4();
    final QuizBank bankEntity = QuizBank(
      id: bankId,
      name: payload.name,
      subject: payload.subject,
      topic: payload.topic,
      description: payload.description,
      color: payload.color,
      tags: payload.tags,
      version: payload.version,
      source: payload.source.id,
      externalId: payload.externalId,
      subjectId: subjectId ?? existing?.subjectId,
      topicId: topicId ?? existing?.topicId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _local.upsertBank(_bankCompanion(bankEntity));

    if (existing != null && strategy == ImportStrategy.replace) {
      await _local.deleteQuestionsForBank(bankId);
    }

    final Set<String> skipExternal = (existing != null &&
            strategy == ImportStrategy.merge)
        ? await _local.existingExternalIds(bankId)
        : <String>{};

    final List<QuizQuestionsCompanion> toInsert = <QuizQuestionsCompanion>[];
    for (final QuizQuestion q in payload.questions) {
      if (q.externalId != null && skipExternal.contains(q.externalId)) {
        continue; // already present (merge dedup)
      }
      toInsert.add(_questionCompanion(
        q.copyWith(subjectId: subjectId, topicId: topicId),
        bankId: bankId,
      ));
    }
    if (toInsert.isNotEmpty) await _local.insertQuestions(toInsert);
    return toInsert.length;
  }

  // ── Backup ────────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> exportBackup() async => <String, dynamic>{
        'app': 'sapiora',
        'type': 'quiz_backup',
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'subjects':
            (await _local.allSubjects()).map((QuizSubjectRow r) => r.toJson()).toList(),
        'topics':
            (await _local.allTopics()).map((QuizTopicRow r) => r.toJson()).toList(),
        'banks': (await _local.allBanks()).map((QuizBankRow r) => r.toJson()).toList(),
        'questions':
            (await _local.allQuestions()).map((QuizQuestionRow r) => r.toJson()).toList(),
        'attempts':
            (await _local.allAttempts()).map((QuizAttemptRow r) => r.toJson()).toList(),
        'answers':
            (await _local.allAnswers()).map((QuizAnswerRow r) => r.toJson()).toList(),
        'wrong':
            (await _local.allWrong()).map((QuizWrongRow r) => r.toJson()).toList(),
      };

  @override
  Future<void> importBackup(Map<String, dynamic> data) async {
    List<Map<String, dynamic>> rows(String key) =>
        ((data[key] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => (e as Map).cast<String, dynamic>())
            .toList();
    await _local.replaceAll(
      subjects: rows('subjects')
          .map((Map<String, dynamic> m) =>
              QuizSubjectRow.fromJson(m).toCompanion(true))
          .toList(),
      topics: rows('topics')
          .map((Map<String, dynamic> m) =>
              QuizTopicRow.fromJson(m).toCompanion(true))
          .toList(),
      banks: rows('banks')
          .map((Map<String, dynamic> m) =>
              QuizBankRow.fromJson(m).toCompanion(true))
          .toList(),
      questions: rows('questions')
          .map((Map<String, dynamic> m) =>
              QuizQuestionRow.fromJson(m).toCompanion(true))
          .toList(),
      attempts: rows('attempts')
          .map((Map<String, dynamic> m) =>
              QuizAttemptRow.fromJson(m).toCompanion(true))
          .toList(),
      answers: rows('answers')
          .map((Map<String, dynamic> m) =>
              QuizAnswerRow.fromJson(m).toCompanion(true))
          .toList(),
      wrong: rows('wrong')
          .map((Map<String, dynamic> m) =>
              QuizWrongRow.fromJson(m).toCompanion(true))
          .toList(),
    );
  }

  // ── Mapping ─────────────────────────────────────────────────────────────────

  QuizBank _toBank(QuizBankRow r) => QuizBank(
        id: r.id,
        name: r.name,
        subject: r.subject,
        topic: r.topic,
        description: r.description,
        color: r.color,
        tags: r.tags,
        version: r.version,
        source: r.source,
        externalId: r.externalId,
        subjectId: r.subjectId,
        topicId: r.topicId,
        orderIndex: r.orderIndex,
        archived: r.archived,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  QuizBanksCompanion _bankCompanion(QuizBank b) {
    final String search = <String?>[b.name, b.subject, b.topic, b.tags]
        .whereType<String>()
        .join(' ')
        .toLowerCase();
    return QuizBanksCompanion.insert(
      id: b.id,
      name: b.name,
      subject: Value<String?>(b.subject),
      topic: Value<String?>(b.topic),
      description: Value<String?>(b.description),
      color: Value<int?>(b.color),
      tags: Value<String?>(b.tags),
      version: Value<String?>(b.version),
      source: Value<String>(b.source),
      externalId: Value<String?>(b.externalId),
      subjectId: Value<String?>(b.subjectId),
      topicId: Value<String?>(b.topicId),
      orderIndex: Value<int>(b.orderIndex),
      archived: Value<bool>(b.archived),
      searchText: Value<String>(search),
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
    );
  }

  QuizSubject _toSubject(QuizSubjectRow r) => QuizSubject(
        id: r.id,
        name: r.name,
        description: r.description,
        icon: r.icon,
        color: r.color,
        orderIndex: r.orderIndex,
        archived: r.archived,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  QuizSubjectsCompanion _subjectCompanion(QuizSubject s) => QuizSubjectsCompanion.insert(
        id: s.id,
        name: s.name,
        description: Value<String?>(s.description),
        icon: Value<int?>(s.icon),
        color: Value<int?>(s.color),
        orderIndex: Value<int>(s.orderIndex),
        archived: Value<bool>(s.archived),
        searchText: Value<String>(s.name.toLowerCase()),
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
      );

  QuizTopic _toTopic(QuizTopicRow r) => QuizTopic(
        id: r.id,
        subjectId: r.subjectId,
        name: r.name,
        description: r.description,
        icon: r.icon,
        color: r.color,
        orderIndex: r.orderIndex,
        archived: r.archived,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  QuizTopicsCompanion _topicCompanion(QuizTopic t) => QuizTopicsCompanion.insert(
        id: t.id,
        subjectId: t.subjectId,
        name: t.name,
        description: Value<String?>(t.description),
        icon: Value<int?>(t.icon),
        color: Value<int?>(t.color),
        orderIndex: Value<int>(t.orderIndex),
        archived: Value<bool>(t.archived),
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );

  QuizQuestion _toQuestion(QuizQuestionRow r) {
    final QuestionType type = QuestionType.fromIndex(r.type);
    final List<String> options = _decodeStringList(r.optionsJson);
    int? answerIndex;
    bool? answerBool;
    List<String> answerTexts = const <String>[];
    List<int> answerIndexes = const <int>[];
    final dynamic ans = r.answerJson == null ? null : jsonDecode(r.answerJson!);
    switch (type) {
      case QuestionType.mcqSingle:
        if (ans is int) answerIndex = ans;
      case QuestionType.trueFalse:
        if (ans is bool) answerBool = ans;
      case QuestionType.fillBlank:
        if (ans is List) answerTexts = ans.map((dynamic e) => '$e').toList();
      case QuestionType.multiCorrect:
        if (ans is List) answerIndexes = ans.whereType<int>().toList();
      case QuestionType.matching:
        break;
    }
    return QuizQuestion(
      id: r.id,
      bankId: r.bankId,
      type: type,
      prompt: r.prompt,
      options: options,
      answerIndex: answerIndex,
      answerBool: answerBool,
      answerTexts: answerTexts,
      answerIndexes: answerIndexes,
      explanation: r.explanation,
      subject: r.subject,
      topic: r.topic,
      tags: r.tags,
      difficulty: QuizDifficulty.fromIndex(r.difficulty),
      bookmarked: r.bookmarked,
      externalId: r.externalId,
      subjectId: r.subjectId,
      topicId: r.topicId,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  QuizQuestionsCompanion _questionCompanion(QuizQuestion q, {String? bankId}) {
    final String targetBank = bankId ?? q.bankId;
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
    final String search = <String?>[
      q.prompt,
      q.options.join(' '),
      q.subject,
      q.topic,
      q.tags,
    ].whereType<String>().join(' ').toLowerCase();
    return QuizQuestionsCompanion.insert(
      id: q.id.startsWith('import_') ? _uuid.v4() : q.id,
      bankId: targetBank,
      type: Value<int>(q.type.index),
      prompt: q.prompt,
      optionsJson: Value<String?>(q.options.isEmpty ? null : jsonEncode(q.options)),
      answerJson: Value<String?>(answer == null ? null : jsonEncode(answer)),
      explanation: Value<String?>(q.explanation),
      subject: Value<String?>(q.subject),
      topic: Value<String?>(q.topic),
      tags: Value<String?>(q.tags),
      difficulty: Value<int>(q.difficulty.index),
      bookmarked: Value<bool>(q.bookmarked),
      externalId: Value<String?>(q.externalId),
      subjectId: Value<String?>(q.subjectId),
      topicId: Value<String?>(q.topicId),
      searchText: Value<String>(search),
      createdAt: q.createdAt,
      updatedAt: q.updatedAt,
    );
  }

  QuizAttempt _toAttempt(QuizAttemptRow r) => QuizAttempt(
        id: r.id,
        bankId: r.bankId,
        mode: QuizMode.fromIndex(r.mode),
        title: r.title,
        totalQuestions: r.totalQuestions,
        correct: r.correct,
        wrong: r.wrong,
        skipped: r.skipped,
        startedAt: r.startedAt,
        finishedAt: r.finishedAt,
        durationMs: r.durationMs,
      );

  QuizGivenAnswer? _decodeGiven(String? json) {
    if (json == null) return null;
    final dynamic m = jsonDecode(json);
    return m is Map ? QuizGivenAnswer.fromJson(m.cast<String, dynamic>()) : null;
  }

  List<String> _decodeStringList(String? json) {
    if (json == null) return const <String>[];
    final dynamic m = jsonDecode(json);
    return m is List ? m.map((dynamic e) => '$e').toList() : const <String>[];
  }
}
