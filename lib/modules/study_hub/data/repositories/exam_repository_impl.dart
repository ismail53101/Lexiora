import 'dart:async';

import 'package:lexiora/core/database/raw_sql.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/exam_repository.dart';
import 'package:uuid/uuid.dart';

class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl(
    this._sql, {
    DateTime Function()? clock,
    Uuid uuid = const Uuid(),
  })  : _now = clock ?? DateTime.now,
        _uuid = uuid;

  final RawSql _sql;
  final DateTime Function() _now;
  final Uuid _uuid;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Re-runs [query] on every change, and every 30 minutes so "days left"
  /// stays right when the date rolls over.
  Stream<T> _watch<T>(Future<T> Function() query) {
    late final StreamController<T> c;
    StreamSubscription<void>? sub;
    Timer? timer;
    Future<void> run() async {
      try {
        final T v = await query();
        if (!c.isClosed) c.add(v);
      } on Object catch (e, st) {
        if (!c.isClosed) c.addError(e, st);
      }
    }

    c = StreamController<T>(
      onListen: () {
        sub = _changes.stream.listen((_) => run());
        timer = Timer.periodic(const Duration(minutes: 30), (_) => run());
        run();
      },
      onCancel: () {
        timer?.cancel();
        return sub?.cancel();
      },
    );
    return c.stream;
  }

  static int _i(SqlRow r, String k) => (r[k] as num?)?.toInt() ?? 0;
  static String _s(SqlRow r, String k) => (r[k] as String?) ?? '';
  static int _unix(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
  static DateTime _fromUnix(int s) => DateTime.fromMillisecondsSinceEpoch(s * 1000);

  // ── exams ──────────────────────────────────────────────────────────────────

  StudyExam _exam(SqlRow r) => StudyExam(
        id: _s(r, 'id'),
        subject: _s(r, 'subject'),
        title: _s(r, 'title'),
        day: _s(r, 'exam_date'),
        notes: r['notes'] as String?,
        createdAt: _fromUnix(_i(r, 'created_at')),
        updatedAt: _fromUnix(_i(r, 'updated_at')),
      );

  Future<List<StudyExam>> _exams() async => (await _sql.select(
        'SELECT * FROM sp_exams ORDER BY exam_date, subject COLLATE NOCASE',
      ))
          .map(_exam)
          .toList();

  @override
  Stream<List<StudyExam>> watchExams() => _watch(_exams);

  @override
  Future<StudyExam> saveExam({
    String? id,
    required String subject,
    required String title,
    required String day,
    String? notes,
  }) async {
    final String subj = subject.trim();
    if (subj.isEmpty) throw ArgumentError('Subject is required');
    if (DateTime.tryParse(day) == null) throw ArgumentError('Invalid date: $day');
    final DateTime now = _now();
    final String examId = id ?? _uuid.v4();
    final List<SqlRow> existing = await _sql.select(
        'SELECT created_at FROM sp_exams WHERE id = ?', <Object?>[examId]);
    final DateTime created =
        existing.isEmpty ? now : _fromUnix(_i(existing.first, 'created_at'));
    final String name = title.trim().isEmpty ? 'Exam' : title.trim();
    final String? cleanNotes =
        (notes == null || notes.trim().isEmpty) ? null : notes.trim();
    await _sql.execute(
      'INSERT OR REPLACE INTO sp_exams '
      '(id, subject, title, exam_date, notes, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      <Object?>[examId, subj, name, day, cleanNotes, _unix(created), _unix(now)],
    );
    _notify();
    return StudyExam(
      id: examId,
      subject: subj,
      title: name,
      day: day,
      notes: cleanNotes,
      createdAt: created,
      updatedAt: now,
    );
  }

  @override
  Future<void> deleteExam(String id) async {
    await _sql.execute('DELETE FROM sp_exams WHERE id = ?', <Object?>[id]);
    _notify();
  }

  @override
  Stream<List<ExamCountdown>> watchCountdowns() => _watch(() async {
        final List<StudyExam> exams = await _exams();
        final Map<String, SubjectSyllabus> bySubject = <String, SubjectSyllabus>{
          for (final SubjectSyllabus s in await _syllabi())
            s.subject.trim().toLowerCase(): s,
        };
        return buildCountdowns(exams, bySubject, _now());
      });

  // ── syllabus ───────────────────────────────────────────────────────────────

  SyllabusTopic _topic(SqlRow r) {
    final int? completed = (r['completed_at'] as num?)?.toInt();
    return SyllabusTopic(
      id: _s(r, 'id'),
      subject: _s(r, 'subject'),
      title: _s(r, 'title'),
      done: _i(r, 'done') != 0,
      sortOrder: _i(r, 'sort_order'),
      completedAt: completed == null ? null : _fromUnix(completed),
      createdAt: _fromUnix(_i(r, 'created_at')),
    );
  }

  Future<List<SubjectSyllabus>> _syllabi() async {
    final List<SqlRow> rows = await _sql.select(
      'SELECT * FROM sp_topics ORDER BY subject_key, sort_order, created_at, id',
    );
    final Map<String, List<SyllabusTopic>> grouped = <String, List<SyllabusTopic>>{};
    for (final SqlRow r in rows) {
      grouped.putIfAbsent(_s(r, 'subject_key'), () => <SyllabusTopic>[]).add(_topic(r));
    }
    return <SubjectSyllabus>[
      for (final List<SyllabusTopic> topics in grouped.values)
        SubjectSyllabus(topics.first.subject, topics),
    ];
  }

  @override
  Stream<List<SubjectSyllabus>> watchSyllabi() => _watch(_syllabi);

  @override
  Future<int> addTopics(String subject, List<String> titles) async {
    final String subj = subject.trim();
    if (subj.isEmpty) throw ArgumentError('Subject is required');
    final String subjectKey = subj.toLowerCase();
    final List<SqlRow> existing = await _sql.select(
      'SELECT title_key, sort_order FROM sp_topics WHERE subject_key = ?',
      <Object?>[subjectKey],
    );
    final Set<String> have = <String>{for (final SqlRow r in existing) _s(r, 'title_key')};
    int order = existing.fold<int>(-1, (int m, SqlRow r) => _i(r, 'sort_order') > m ? _i(r, 'sort_order') : m) + 1;
    final int now = _unix(_now());
    final List<({String sql, List<Object?> args})> inserts = <({String sql, List<Object?> args})>[];
    for (final String raw in titles) {
      final String title = raw.trim();
      if (title.isEmpty) continue;
      final String key = title.toLowerCase();
      if (!have.add(key)) continue;
      inserts.add((
        sql: 'INSERT OR IGNORE INTO sp_topics '
            '(id, subject, subject_key, title, title_key, done, sort_order, completed_at, created_at) '
            'VALUES (?, ?, ?, ?, ?, 0, ?, NULL, ?)',
        args: <Object?>[_uuid.v4(), subj, subjectKey, title, key, order++, now],
      ));
    }
    if (inserts.isEmpty) return 0;
    await _sql.executeAll(inserts);
    _notify();
    return inserts.length;
  }

  @override
  Future<void> setTopicDone(String id, bool done) async {
    await _sql.execute(
      'UPDATE sp_topics SET done = ?, completed_at = ? WHERE id = ?',
      <Object?>[done ? 1 : 0, done ? _unix(_now()) : null, id],
    );
    _notify();
  }

  @override
  Future<void> renameTopic(String id, String title) async {
    final String t = title.trim();
    if (t.isEmpty) return;
    final List<SqlRow> row =
        await _sql.select('SELECT subject_key FROM sp_topics WHERE id = ?', <Object?>[id]);
    if (row.isEmpty) return;
    final List<SqlRow> clash = await _sql.select(
      'SELECT id FROM sp_topics WHERE subject_key = ? AND title_key = ? AND id != ?',
      <Object?>[_s(row.first, 'subject_key'), t.toLowerCase(), id],
    );
    if (clash.isNotEmpty) return; // would duplicate another topic
    await _sql.execute(
      'UPDATE sp_topics SET title = ?, title_key = ? WHERE id = ?',
      <Object?>[t, t.toLowerCase(), id],
    );
    _notify();
  }

  @override
  Future<void> deleteTopic(String id) async {
    await _sql.execute('DELETE FROM sp_topics WHERE id = ?', <Object?>[id]);
    _notify();
  }

  @override
  Future<List<String>> topicsFromSessions(String subject) async {
    final String key = subject.trim().toLowerCase();
    if (key.isEmpty) return const <String>[];
    try {
      final List<SqlRow> rows = await _sql.select(
        'SELECT DISTINCT TRIM(topic) AS topic FROM study_tasks '
        "WHERE kind = 'session' AND LOWER(TRIM(COALESCE(subject, title))) = ? "
        "AND topic IS NOT NULL AND TRIM(topic) != '' ORDER BY topic COLLATE NOCASE, topic",
        <Object?>[key],
      );
      final List<SqlRow> have = await _sql.select(
          'SELECT title_key FROM sp_topics WHERE subject_key = ?', <Object?>[key]);
      final Set<String> haveKeys = <String>{for (final SqlRow r in have) _s(r, 'title_key')};
      final Set<String> seen = <String>{...haveKeys};
      return <String>[
        for (final SqlRow r in rows)
          if (seen.add(_s(r, 'topic').toLowerCase())) _s(r, 'topic'),
      ];
    } on Object {
      return const <String>[];
    }
  }
}
