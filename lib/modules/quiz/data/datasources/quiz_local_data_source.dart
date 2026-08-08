import 'package:drift/drift.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/quiz_dates.dart';

typedef StatsAgg = ({
  int totalQuizzes,
  int correct,
  int wrong,
  int skipped,
  int totalTimeMs,
  int daily,
  int weekly,
  int monthly,
});

typedef SubjectAgg = ({String subject, int correct, int total});

/// All Drift queries for the Quiz Engine. Reads of `study_subjects` (for colours)
/// are strictly read-only; no other module is modified. Built for 100k+ rows via
/// indexed columns, LIMIT/OFFSET pagination and search over `search_text`.
class QuizLocalDataSource {
  QuizLocalDataSource(this._db);

  final AppDatabase _db;
  static const int _hardDifficulty = 3;

  // ── Banks ─────────────────────────────────────────────────────────────────

  Stream<List<QueryRow>> watchBankSummaries(bool includeArchived) {
    final String where = includeArchived ? '' : 'WHERE b.archived = 0';
    return _db
        .customSelect(
          'SELECT b.*, '
          '(SELECT COUNT(*) FROM quiz_questions q WHERE q.bank_id = b.id) '
          'AS question_count '
          'FROM quiz_banks b $where ORDER BY b.name COLLATE NOCASE',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizBanks,
            _db.quizQuestions,
          },
        )
        .watch();
  }

  QuizBankRow bankRowFrom(QueryRow r) => _db.quizBanks.map(r.data);

  Future<QuizBankRow?> bank(String id) =>
      (_db.select(_db.quizBanks)..where(($QuizBanksTable t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<QuizBankRow?> bankByExternalId(String externalId) =>
      (_db.select(_db.quizBanks)
            ..where(($QuizBanksTable t) => t.externalId.equals(externalId)))
          .getSingleOrNull();

  /// External ids already present in [bankId] (for merge deduplication).
  Future<Set<String>> existingExternalIds(String bankId) async {
    final List<TypedResult> rows = await (_db.selectOnly(_db.quizQuestions)
          ..addColumns(<Expression<Object>>[_db.quizQuestions.externalId])
          ..where(_db.quizQuestions.bankId.equals(bankId) &
              _db.quizQuestions.externalId.isNotNull()))
        .get();
    return rows
        .map((TypedResult r) => r.read(_db.quizQuestions.externalId))
        .whereType<String>()
        .toSet();
  }

  Future<void> upsertBank(QuizBanksCompanion b) =>
      _db.into(_db.quizBanks).insertOnConflictUpdate(b);

  Future<void> updateBank(String id, QuizBanksCompanion b) =>
      (_db.update(_db.quizBanks)..where(($QuizBanksTable t) => t.id.equals(id)))
          .write(b);

  Future<void> deleteBank(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.quizQuestions)
            ..where(($QuizQuestionsTable t) => t.bankId.equals(id)))
          .go();
      await (_db.delete(_db.quizBanks)
            ..where(($QuizBanksTable t) => t.id.equals(id)))
          .go();
    });
  }

  /// Bank summaries filtered by subject and/or topic (topic-less when topicId
  /// is explicitly the sentinel handled by the caller via [topicIsNull]).
  Stream<List<QueryRow>> watchBankSummariesIn({
    String? subjectId,
    String? topicId,
    bool topicIsNull = false,
    bool includeArchived = false,
  }) {
    final StringBuffer where = StringBuffer('WHERE 1 = 1');
    final List<Variable<Object>> vars = <Variable<Object>>[];
    if (!includeArchived) where.write(' AND b.archived = 0');
    if (subjectId != null) {
      where.write(' AND b.subject_id = ?');
      vars.add(Variable.withString(subjectId));
    }
    if (topicId != null) {
      where.write(' AND b.topic_id = ?');
      vars.add(Variable.withString(topicId));
    } else if (topicIsNull) {
      where.write(' AND b.topic_id IS NULL');
    }
    return _db
        .customSelect(
          'SELECT b.*, '
          '(SELECT COUNT(*) FROM quiz_questions q WHERE q.bank_id = b.id) '
          'AS question_count '
          'FROM quiz_banks b $where ORDER BY b.order_index, b.name COLLATE NOCASE',
          variables: vars,
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizBanks,
            _db.quizQuestions,
          },
        )
        .watch();
  }

  // ── Subjects (v0.9.1) ────────────────────────────────────────────────────────

  Stream<List<QueryRow>> watchSubjectSummaries(bool includeArchived) {
    final String where = includeArchived ? '' : 'WHERE s.archived = 0';
    return _db
        .customSelect(
          'SELECT s.*, '
          '(SELECT COUNT(*) FROM quiz_topics t WHERE t.subject_id = s.id '
          '  AND t.archived = 0) AS topic_count, '
          '(SELECT COUNT(*) FROM quiz_questions q WHERE q.subject_id = s.id) '
          'AS question_count '
          'FROM quiz_subjects s $where ORDER BY s.order_index, s.name COLLATE NOCASE',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizSubjects,
            _db.quizTopics,
            _db.quizQuestions,
          },
        )
        .watch();
  }

  QuizSubjectRow subjectRowFrom(QueryRow r) => _db.quizSubjects.map(r.data);

  Future<QuizSubjectRow?> subject(String id) => (_db.select(_db.quizSubjects)
        ..where(($QuizSubjectsTable t) => t.id.equals(id)))
      .getSingleOrNull();

  Future<void> upsertSubject(QuizSubjectsCompanion s) =>
      _db.into(_db.quizSubjects).insertOnConflictUpdate(s);

  Future<void> updateSubject(String id, QuizSubjectsCompanion s) =>
      (_db.update(_db.quizSubjects)
            ..where(($QuizSubjectsTable t) => t.id.equals(id)))
          .write(s);

  Future<void> deleteSubject(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.quizQuestions)
            ..where(($QuizQuestionsTable t) => t.subjectId.equals(id)))
          .go();
      await (_db.delete(_db.quizBanks)
            ..where(($QuizBanksTable t) => t.subjectId.equals(id)))
          .go();
      await (_db.delete(_db.quizTopics)
            ..where(($QuizTopicsTable t) => t.subjectId.equals(id)))
          .go();
      await (_db.delete(_db.quizSubjects)
            ..where(($QuizSubjectsTable t) => t.id.equals(id)))
          .go();
    });
  }

  Future<int> subjectCount() =>
      _db.quizSubjects.count().getSingle();

  Future<void> reorder(String table, List<String> orderedIds) async {
    await _db.transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await _db.customUpdate(
          'UPDATE $table SET order_index = ? WHERE id = ?',
          variables: <Variable<Object>>[
            Variable.withInt(i),
            Variable.withString(orderedIds[i]),
          ],
          updates: <ResultSetImplementation<dynamic, dynamic>>{
            table == 'quiz_subjects' ? _db.quizSubjects : _db.quizTopics,
          },
        );
      }
    });
  }

  // ── Topics (v0.9.1) ──────────────────────────────────────────────────────────

  Stream<List<QueryRow>> watchTopicSummaries(
      String subjectId, bool includeArchived) {
    final String archived = includeArchived ? '' : 'AND t.archived = 0';
    return _db
        .customSelect(
          'SELECT t.*, '
          '(SELECT COUNT(*) FROM quiz_banks b WHERE b.topic_id = t.id) AS quiz_count, '
          '(SELECT COUNT(*) FROM quiz_questions q WHERE q.topic_id = t.id) '
          'AS question_count '
          'FROM quiz_topics t WHERE t.subject_id = ? $archived '
          'ORDER BY t.order_index, t.name COLLATE NOCASE',
          variables: <Variable<Object>>[Variable.withString(subjectId)],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizTopics,
            _db.quizBanks,
            _db.quizQuestions,
          },
        )
        .watch();
  }

  QuizTopicRow topicRowFrom(QueryRow r) => _db.quizTopics.map(r.data);

  Future<QuizTopicRow?> topic(String id) => (_db.select(_db.quizTopics)
        ..where(($QuizTopicsTable t) => t.id.equals(id)))
      .getSingleOrNull();

  Future<void> upsertTopic(QuizTopicsCompanion t) =>
      _db.into(_db.quizTopics).insertOnConflictUpdate(t);

  Future<void> updateTopic(String id, QuizTopicsCompanion t) =>
      (_db.update(_db.quizTopics)..where(($QuizTopicsTable r) => r.id.equals(id)))
          .write(t);

  Future<void> deleteTopic(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.quizQuestions)
            ..where(($QuizQuestionsTable t) => t.topicId.equals(id)))
          .go();
      await (_db.delete(_db.quizBanks)
            ..where(($QuizBanksTable t) => t.topicId.equals(id)))
          .go();
      await (_db.delete(_db.quizTopics)
            ..where(($QuizTopicsTable t) => t.id.equals(id)))
          .go();
    });
  }

  // ── Stage quizzes (v0.11.0) ─────────────────────────────────────────────────
  //
  // Stages are deterministic slices of a subject's question pool, ordered by
  // topic → bank → insertion so buckets stay stable across sessions (new
  // questions appended later land at the end). Progress lives in the dedicated
  // quiz_stage_progress table; attempts still feed the normal quiz tables.

  Future<List<QuizQuestionRow>> stageQuestions(String subjectId,
      {required int offset, required int limit}) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT * FROM quiz_questions WHERE subject_id = ? '
          "ORDER BY COALESCE(topic_id, ''), bank_id, created_at, id "
          'LIMIT ? OFFSET ?',
          variables: <Variable<Object>>[
            Variable.withString(subjectId),
            Variable.withInt(limit),
            Variable.withInt(offset),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizQuestions,
          },
        )
        .get();
    return rows.map((QueryRow r) => _db.quizQuestions.map(r.data)).toList();
  }

  Stream<List<QuizStageProgressRow>> watchStageProgress(String subjectId) =>
      (_db.select(_db.quizStageProgress)
            ..where(
                ($QuizStageProgressTable t) => t.subjectId.equals(subjectId))
            ..orderBy(<OrderClauseGenerator<$QuizStageProgressTable>>[
              ($QuizStageProgressTable t) =>
                  OrderingTerm(expression: t.stageIndex),
            ]))
          .watch();

  Future<QuizStageProgressRow?> stageProgress(
          String subjectId, int stageIndex) =>
      (_db.select(_db.quizStageProgress)
            ..where(($QuizStageProgressTable t) =>
                t.subjectId.equals(subjectId) &
                t.stageIndex.equals(stageIndex)))
          .getSingleOrNull();

  Future<void> upsertStageProgress(QuizStageProgressCompanion row) =>
      _db.into(_db.quizStageProgress).insertOnConflictUpdate(row);

  // ── Questions ───────────────────────────────────────────────────────────────

  Future<QuizQuestionRow?> question(String id) =>
      (_db.select(_db.quizQuestions)
            ..where(($QuizQuestionsTable t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<QuizQuestionRow>> questionsByIds(List<String> ids) async {
    if (ids.isEmpty) return const <QuizQuestionRow>[];
    return (_db.select(_db.quizQuestions)
          ..where(($QuizQuestionsTable t) => t.id.isIn(ids)))
        .get();
  }

  Future<void> upsertQuestion(QuizQuestionsCompanion q) =>
      _db.into(_db.quizQuestions).insertOnConflictUpdate(q);

  Future<void> insertQuestions(List<QuizQuestionsCompanion> qs) =>
      _db.batch((Batch b) => b.insertAll(_db.quizQuestions, qs));

  Future<void> deleteQuestion(String id) =>
      (_db.delete(_db.quizQuestions)
            ..where(($QuizQuestionsTable t) => t.id.equals(id)))
          .go();

  Future<void> deleteQuestionsForBank(String bankId) =>
      (_db.delete(_db.quizQuestions)
            ..where(($QuizQuestionsTable t) => t.bankId.equals(bankId)))
          .go();

  Future<void> updateQuestion(String id, QuizQuestionsCompanion q) =>
      (_db.update(_db.quizQuestions)
            ..where(($QuizQuestionsTable t) => t.id.equals(id)))
          .write(q);

  /// Builds the dynamic WHERE for [searchQuestions]/[countQuestions].
  (String, List<Variable<Object>>) _where(QuizFilter f) {
    final StringBuffer sql = StringBuffer(' WHERE 1 = 1');
    final List<Variable<Object>> vars = <Variable<Object>>[];
    final String q = f.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      sql.write(' AND search_text LIKE ?');
      vars.add(Variable.withString('%$q%'));
    }
    if (f.bankId != null) {
      sql.write(' AND bank_id = ?');
      vars.add(Variable.withString(f.bankId!));
    }
    if (f.subjectId != null) {
      sql.write(' AND subject_id = ?');
      vars.add(Variable.withString(f.subjectId!));
    }
    if (f.topicId != null) {
      sql.write(' AND topic_id = ?');
      vars.add(Variable.withString(f.topicId!));
    }
    if (f.subject != null && f.subject!.isNotEmpty) {
      sql.write(" AND LOWER(COALESCE(subject,'')) = ?");
      vars.add(Variable.withString(f.subject!.toLowerCase()));
    }
    if (f.topic != null && f.topic!.isNotEmpty) {
      sql.write(" AND LOWER(COALESCE(topic,'')) = ?");
      vars.add(Variable.withString(f.topic!.toLowerCase()));
    }
    if (f.tag != null && f.tag!.isNotEmpty) {
      sql.write(" AND LOWER(COALESCE(tags,'')) LIKE ?");
      vars.add(Variable.withString('%${f.tag!.toLowerCase()}%'));
    }
    if (f.type != null) {
      sql.write(' AND type = ?');
      vars.add(Variable.withInt(f.type!.index));
    }
    if (f.difficulty != null) {
      sql.write(' AND difficulty = ?');
      vars.add(Variable.withInt(f.difficulty!.index));
    }
    if (f.onlyBookmarked) sql.write(' AND bookmarked = 1');
    if (f.onlyWrong) {
      sql.write(' AND id IN (SELECT question_id FROM quiz_wrong_answers)');
    }
    if (f.createdAfter != null) {
      sql.write(' AND created_at >= ?');
      vars.add(Variable.withInt(
          f.createdAfter!.millisecondsSinceEpoch ~/ 1000));
    }
    return (sql.toString(), vars);
  }

  Future<List<QuizQuestionRow>> searchQuestions(
    QuizFilter f, {
    int limit = 50,
    int offset = 0,
  }) async {
    final (String where, List<Variable<Object>> vars) = _where(f);
    final String order = f.sort == QuizSort.alphabetical
        ? ' ORDER BY prompt COLLATE NOCASE'
        : ' ORDER BY created_at DESC';
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT * FROM quiz_questions$where$order LIMIT ? OFFSET ?',
          variables: <Variable<Object>>[
            ...vars,
            Variable.withInt(limit),
            Variable.withInt(offset),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizQuestions,
            _db.quizWrongAnswers,
          },
        )
        .get();
    return rows.map((QueryRow r) => _db.quizQuestions.map(r.data)).toList();
  }

  Future<int> countQuestions(QuizFilter f) async {
    final (String where, List<Variable<Object>> vars) = _where(f);
    final QueryRow row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM quiz_questions$where',
          variables: vars,
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizQuestions,
            _db.quizWrongAnswers,
          },
        )
        .getSingle();
    return row.read<int>('c');
  }

  /// Session cards for the player (optionally shuffled, capped by [limit]).
  Future<List<QuizQuestionRow>> session(
    QuizFilter f, {
    int limit = 50,
    bool shuffle = true,
  }) async {
    final (String where, List<Variable<Object>> vars) = _where(f);
    final String order = shuffle ? ' ORDER BY RANDOM()' : ' ORDER BY created_at';
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT * FROM quiz_questions$where$order LIMIT ?',
          variables: <Variable<Object>>[...vars, Variable.withInt(limit)],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizQuestions,
            _db.quizWrongAnswers,
          },
        )
        .get();
    return rows.map((QueryRow r) => _db.quizQuestions.map(r.data)).toList();
  }

  // ── Attempts / answers ──────────────────────────────────────────────────────

  Future<void> insertAttempt(QuizAttemptsCompanion a) =>
      _db.into(_db.quizAttempts).insert(a);

  Future<void> insertAnswers(List<QuizAttemptAnswersCompanion> answers) =>
      _db.batch((Batch b) => b.insertAll(_db.quizAttemptAnswers, answers));

  Stream<List<QuizAttemptRow>> watchAttempts(int limit) =>
      (_db.select(_db.quizAttempts)
            ..where(($QuizAttemptsTable t) => t.finishedAt.isNotNull())
            ..orderBy(<OrderClauseGenerator<$QuizAttemptsTable>>[
              ($QuizAttemptsTable t) =>
                  OrderingTerm(expression: t.finishedAt, mode: OrderingMode.desc),
            ])
            ..limit(limit))
          .watch();

  Future<List<QuizAnswerRow>> attemptAnswers(String attemptId) =>
      (_db.select(_db.quizAttemptAnswers)
            ..where(($QuizAttemptAnswersTable t) => t.attemptId.equals(attemptId))
            ..orderBy(<OrderClauseGenerator<$QuizAttemptAnswersTable>>[
              ($QuizAttemptAnswersTable t) =>
                  OrderingTerm(expression: t.orderIndex),
            ]))
          .get();

  // ── Wrong-answer notebook ───────────────────────────────────────────────────

  Future<void> upsertWrong(QuizWrongAnswersCompanion w) =>
      _db.into(_db.quizWrongAnswers).insertOnConflictUpdate(w);

  Future<QuizWrongRow?> wrong(String questionId) =>
      (_db.select(_db.quizWrongAnswers)
            ..where(($QuizWrongAnswersTable t) => t.questionId.equals(questionId)))
          .getSingleOrNull();

  Future<List<QuizWrongRow>> wrongAnswers(
      {String? subjectId, int limit = 50, int offset = 0}) async {
    if (subjectId == null) {
      return (_db.select(_db.quizWrongAnswers)
            ..orderBy(<OrderClauseGenerator<$QuizWrongAnswersTable>>[
              ($QuizWrongAnswersTable t) =>
                  OrderingTerm(expression: t.lastWrongAt, mode: OrderingMode.desc),
            ])
            ..limit(limit, offset: offset))
          .get();
    }
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT w.* FROM quiz_wrong_answers w WHERE w.question_id IN '
          '(SELECT id FROM quiz_questions WHERE subject_id = ?) '
          'ORDER BY w.last_wrong_at DESC LIMIT ? OFFSET ?',
          variables: <Variable<Object>>[
            Variable.withString(subjectId),
            Variable.withInt(limit),
            Variable.withInt(offset),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizWrongAnswers,
            _db.quizQuestions,
          },
        )
        .get();
    return rows.map((QueryRow r) => _db.quizWrongAnswers.map(r.data)).toList();
  }

  Future<void> deleteWrong(String questionId) =>
      (_db.delete(_db.quizWrongAnswers)
            ..where(($QuizWrongAnswersTable t) => t.questionId.equals(questionId)))
          .go();

  Future<void> clearWrong() => _db.delete(_db.quizWrongAnswers).go();

  Stream<int> watchWrongCount() => _db
      .quizWrongAnswers
      .count()
      .watchSingle();

  // ── Bookmarks / stats ───────────────────────────────────────────────────────

  Stream<int> watchBookmarkCount() => (_db.selectOnly(_db.quizQuestions)
        ..addColumns(<Expression<Object>>[_db.quizQuestions.id.count()])
        ..where(_db.quizQuestions.bookmarked.equals(true)))
      .map((TypedResult r) => r.read(_db.quizQuestions.id.count()) ?? 0)
      .watchSingle();

  Stream<StatsAgg> watchStats() {
    final String today = todayKey();
    final String week = weekStartKey();
    final String month = monthStartKey();
    return _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM quiz_attempts WHERE finished_at IS NOT NULL) AS quizzes, '
          '(SELECT COALESCE(SUM(correct),0) FROM quiz_attempts WHERE finished_at IS NOT NULL) AS correct, '
          '(SELECT COALESCE(SUM(wrong),0) FROM quiz_attempts WHERE finished_at IS NOT NULL) AS wrong, '
          '(SELECT COALESCE(SUM(skipped),0) FROM quiz_attempts WHERE finished_at IS NOT NULL) AS skipped, '
          '(SELECT COALESCE(SUM(duration_ms),0) FROM quiz_attempts WHERE finished_at IS NOT NULL) AS time_ms, '
          '(SELECT COUNT(*) FROM quiz_attempts WHERE finished_at IS NOT NULL AND day = ?) AS daily, '
          '(SELECT COUNT(*) FROM quiz_attempts WHERE finished_at IS NOT NULL AND day >= ?) AS weekly, '
          '(SELECT COUNT(*) FROM quiz_attempts WHERE finished_at IS NOT NULL AND day >= ?) AS monthly',
          variables: <Variable<Object>>[
            Variable.withString(today),
            Variable.withString(week),
            Variable.withString(month),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.quizAttempts},
        )
        .watchSingle()
        .map((QueryRow r) => (
              totalQuizzes: r.read<int>('quizzes'),
              correct: r.read<int>('correct'),
              wrong: r.read<int>('wrong'),
              skipped: r.read<int>('skipped'),
              totalTimeMs: r.read<int>('time_ms'),
              daily: r.read<int>('daily'),
              weekly: r.read<int>('weekly'),
              monthly: r.read<int>('monthly'),
            ));
  }

  Future<List<SubjectAgg>> subjectAccuracies() async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT subject, '
          'SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) AS correct, '
          'COUNT(*) AS total '
          'FROM quiz_attempt_answers '
          "WHERE skipped = 0 AND subject IS NOT NULL AND subject != '' "
          'GROUP BY subject',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizAttemptAnswers,
          },
        )
        .get();
    return rows
        .map((QueryRow r) => (
              subject: r.read<String>('subject'),
              correct: r.read<int>('correct'),
              total: r.read<int>('total'),
            ))
        .toList();
  }

  // ── Subject colours (reused, read-only) + suggestions ───────────────────────

  Stream<List<StudySubjectRow>> watchSubjectRows() =>
      _db.select(_db.studySubjects).watch();

  Future<List<String>> subjectValues() =>
      _distinct(_db.quizQuestions.subject.name);
  Future<List<String>> tagRawValues() => _distinct(_db.quizQuestions.tags.name);

  Future<List<String>> _distinct(String column) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT DISTINCT $column AS v FROM quiz_questions '
          "WHERE $column IS NOT NULL AND $column != '' "
          'ORDER BY $column COLLATE NOCASE',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.quizQuestions,
          },
        )
        .get();
    return rows.map((QueryRow r) => r.read<String>('v')).toList();
  }

  // ── Settings (key-value) ────────────────────────────────────────────────────

  Future<Map<String, String>> allSettings() async {
    final List<QuizSettingRow> rows = await _db.select(_db.quizSettingsRows).get();
    return <String, String>{for (final QuizSettingRow r in rows) r.key: r.value};
  }

  Future<void> saveSettings(Map<String, String> values) async {
    await _db.batch((Batch b) {
      for (final MapEntry<String, String> e in values.entries) {
        b.insert(
          _db.quizSettingsRows,
          QuizSettingsRowsCompanion.insert(key: e.key, value: e.value),
          onConflict: DoUpdate((_) =>
              QuizSettingsRowsCompanion(value: Value<String>(e.value))),
        );
      }
    });
  }

  // ── Demo seed bookkeeping (v0.9.1) ──────────────────────────────────────────

  Future<String?> seededVersion() async =>
      (await allSettings())[QuizConstants.seedVersionKey];

  Future<void> setSeededVersion(String version) =>
      saveSettings(<String, String>{QuizConstants.seedVersionKey: version});

  // ── Backup ───────────────────────────────────────────────────────────────────

  Future<List<QuizSubjectRow>> allSubjects() => _db.select(_db.quizSubjects).get();
  Future<List<QuizTopicRow>> allTopics() => _db.select(_db.quizTopics).get();
  Future<List<QuizBankRow>> allBanks() => _db.select(_db.quizBanks).get();
  Future<List<QuizQuestionRow>> allQuestions() =>
      _db.select(_db.quizQuestions).get();
  Future<List<QuizAttemptRow>> allAttempts() => _db.select(_db.quizAttempts).get();
  Future<List<QuizAnswerRow>> allAnswers() =>
      _db.select(_db.quizAttemptAnswers).get();
  Future<List<QuizWrongRow>> allWrong() => _db.select(_db.quizWrongAnswers).get();

  Future<void> replaceAll({
    required List<QuizSubjectsCompanion> subjects,
    required List<QuizTopicsCompanion> topics,
    required List<QuizBanksCompanion> banks,
    required List<QuizQuestionsCompanion> questions,
    required List<QuizAttemptsCompanion> attempts,
    required List<QuizAttemptAnswersCompanion> answers,
    required List<QuizWrongAnswersCompanion> wrong,
  }) async {
    await _db.transaction(() async {
      await _db.delete(_db.quizAttemptAnswers).go();
      await _db.delete(_db.quizAttempts).go();
      await _db.delete(_db.quizWrongAnswers).go();
      await _db.delete(_db.quizQuestions).go();
      await _db.delete(_db.quizBanks).go();
      await _db.delete(_db.quizTopics).go();
      await _db.delete(_db.quizSubjects).go();
      await _db.batch((Batch b) {
        b.insertAll(_db.quizSubjects, subjects);
        b.insertAll(_db.quizTopics, topics);
        b.insertAll(_db.quizBanks, banks);
        b.insertAll(_db.quizQuestions, questions);
        b.insertAll(_db.quizAttempts, attempts);
        b.insertAll(_db.quizAttemptAnswers, answers);
        b.insertAll(_db.quizWrongAnswers, wrong);
      });
    });
  }

  int get hardDifficulty => _hardDifficulty;
}
