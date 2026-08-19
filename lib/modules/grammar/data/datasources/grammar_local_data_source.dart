import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';

/// All local-database access for the Grammar tree (Category → Subcategory →
/// Lesson). Navigation reads children of a node; leaves decode a full lesson
/// from JSON. Progress and favorites are keyed by a leaf's topic id.
class GrammarLocalDataSource {
  GrammarLocalDataSource(this._db);

  final AppDatabase _db;

  static const String _summarySelect =
      'SELECT t.id AS id, t.title AS title, t.subtitle AS subtitle, '
      't.is_leaf AS is_leaf, t.order_index AS order_index, '
      'COALESCE(p.status, 0) AS status, '
      'EXISTS(SELECT 1 FROM grammar_favorites f WHERE f.lesson_id = t.id) AS fav '
      'FROM grammar_topics t '
      'LEFT JOIN grammar_progress p ON p.lesson_id = t.id ';

  Set<ResultSetImplementation<Object, Object>> get _reads =>
      <ResultSetImplementation<Object, Object>>{
        _db.grammarTopics,
        _db.grammarProgress,
        _db.grammarFavorites,
      };

  // ── Navigation ──────────────────────────────────────────────────────────────

  Stream<List<GrammarTopicSummary>> watchChildren(String? parentId) {
    final String where =
        parentId == null ? 'WHERE t.parent_id IS NULL ' : 'WHERE t.parent_id = ? ';
    final List<Variable<Object>> vars = parentId == null
        ? const <Variable<Object>>[]
        : <Variable<Object>>[Variable<String>(parentId)];
    return _db
        .customSelect(
          '$_summarySelect $where ORDER BY t.order_index ASC',
          variables: vars,
          readsFrom: _reads,
        )
        .watch()
        .map((List<QueryRow> rows) =>
            rows.map(_summaryFromRow).toList(growable: false));
  }

  Future<List<GrammarTopicSummary>> children(String? parentId) async {
    final String where =
        parentId == null ? 'WHERE t.parent_id IS NULL ' : 'WHERE t.parent_id = ? ';
    final List<Variable<Object>> vars = parentId == null
        ? const <Variable<Object>>[]
        : <Variable<Object>>[Variable<String>(parentId)];
    final List<QueryRow> rows = await _db
        .customSelect(
          '$_summarySelect $where ORDER BY t.order_index ASC',
          variables: vars,
          readsFrom: _reads,
        )
        .get();
    return rows.map(_summaryFromRow).toList(growable: false);
  }

  /// The title of a node (for app-bar breadcrumbs), or null when unknown.
  Future<String?> topicTitle(String id) async {
    final GrammarTopicRow? row = await (_db.select(_db.grammarTopics)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    return row?.title;
  }

  /// The full lesson body for a leaf, or null when the id is not a leaf.
  Future<GrammarLesson?> leaf(String id) async {
    final GrammarTopicRow? row = await (_db.select(_db.grammarTopics)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    if (row == null || !row.isLeaf) return null;
    final String? json = row.contentJson;
    if (json == null || json.isEmpty) {
      return GrammarLesson(id: row.id, title: row.title);
    }
    return _decodeLeaf(row.id, row.title, json);
  }

  Future<List<GrammarTopicSummary>> search(String query) async {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return const <GrammarTopicSummary>[];
    final List<QueryRow> rows = await _db
        .customSelect(
          '$_summarySelect WHERE t.is_leaf = 1 AND instr(t.search_text, ?) > 0 '
          'ORDER BY t.order_index ASC LIMIT 50',
          variables: <Variable<Object>>[Variable<String>(q)],
          readsFrom: _reads,
        )
        .get();
    return rows.map(_summaryFromRow).toList(growable: false);
  }

  Stream<List<GrammarTopicSummary>> watchContinueLearning() => _db
      .customSelect(
        '$_summarySelect WHERE t.is_leaf = 1 AND p.status = 1 '
        'ORDER BY p.last_viewed_at DESC',
        readsFrom: _reads,
      )
      .watch()
      .map((List<QueryRow> rows) =>
          rows.map(_summaryFromRow).toList(growable: false));

  Stream<List<GrammarTopicSummary>> watchRecent() => _db
      .customSelect(
        '$_summarySelect WHERE t.is_leaf = 1 AND p.last_viewed_at IS NOT NULL '
        'ORDER BY p.last_viewed_at DESC LIMIT 20',
        readsFrom: _reads,
      )
      .watch()
      .map((List<QueryRow> rows) =>
          rows.map(_summaryFromRow).toList(growable: false));

  // ── Progress ────────────────────────────────────────────────────────────────

  Future<void> markViewed(String leafId) async {
    final GrammarProgressRow? existing = await _progressRow(leafId);
    final int status = existing == null
        ? GrammarProgressStatus.inProgress.index
        : (existing.status == GrammarProgressStatus.notStarted.index
            ? GrammarProgressStatus.inProgress.index
            : existing.status);
    await _db.into(_db.grammarProgress).insertOnConflictUpdate(
          GrammarProgressCompanion(
            lessonId: Value<String>(leafId),
            status: Value<int>(status),
            scrollProgress: Value<double>(existing?.scrollProgress ?? 0),
            lastViewedAt: Value<DateTime>(DateTime.now()),
            completedAt: Value<DateTime?>(existing?.completedAt),
          ),
        );
  }

  Future<void> setCompleted(String leafId, {required bool completed}) async {
    final GrammarProgressRow? existing = await _progressRow(leafId);
    final DateTime now = DateTime.now();
    await _db.into(_db.grammarProgress).insertOnConflictUpdate(
          GrammarProgressCompanion(
            lessonId: Value<String>(leafId),
            status: Value<int>(
              completed
                  ? GrammarProgressStatus.completed.index
                  : GrammarProgressStatus.inProgress.index,
            ),
            scrollProgress: Value<double>(completed ? 1 : (existing?.scrollProgress ?? 0)),
            lastViewedAt: Value<DateTime>(now),
            completedAt: Value<DateTime?>(completed ? now : null),
          ),
        );
  }

  Stream<GrammarProgressStatus> watchStatus(String leafId) =>
      (_db.select(_db.grammarProgress)
            ..where((t) => t.lessonId.equals(leafId)))
          .watchSingleOrNull()
          .map((GrammarProgressRow? row) =>
              GrammarProgressStatus.fromIndex(row?.status));

  // ── Favorites ─────────────────────────────────────────────────────────────

  Future<bool> isFavorite(String leafId) async {
    final GrammarFavoriteRow? row = await (_db.select(_db.grammarFavorites)
          ..where((t) => t.lessonId.equals(leafId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Stream<bool> watchIsFavorite(String leafId) =>
      (_db.select(_db.grammarFavorites)..where((t) => t.lessonId.equals(leafId)))
          .watch()
          .map((List<GrammarFavoriteRow> rows) => rows.isNotEmpty);

  Future<void> addFavorite({required String leafId, required String title}) async {
    await _db.into(_db.grammarFavorites).insert(
          GrammarFavoritesCompanion.insert(
            lessonId: leafId,
            title: title,
            category: 'Grammar',
            createdAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> removeFavorite(String leafId) async {
    await (_db.delete(_db.grammarFavorites)
          ..where((t) => t.lessonId.equals(leafId)))
        .go();
  }

  Stream<List<GrammarTopicSummary>> watchFavorites() => _db
      .customSelect(
        'SELECT t.id AS id, t.title AS title, t.subtitle AS subtitle, '
        't.is_leaf AS is_leaf, t.order_index AS order_index, '
        'COALESCE(p.status, 0) AS status, 1 AS fav '
        'FROM grammar_favorites f '
        'JOIN grammar_topics t ON t.id = f.lesson_id '
        'LEFT JOIN grammar_progress p ON p.lesson_id = t.id '
        'ORDER BY f.created_at DESC',
        readsFrom: _reads,
      )
      .watch()
      .map((List<QueryRow> rows) =>
          rows.map(_summaryFromRow).toList(growable: false));

  // ── Seeding support ─────────────────────────────────────────────────────────

  Future<String?> seededVersion() async {
    final SettingRow? row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(GrammarConstants.topicsSeedVersionKey))
          ..limit(1))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSeededVersion(String version) async {
    await _db.into(_db.settings).insert(
          SettingsCompanion.insert(
            key: GrammarConstants.topicsSeedVersionKey,
            value: version,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> clearTopics() => _db.delete(_db.grammarTopics).go();

  Future<void> insertTopics(List<GrammarTopicsCompanion> batch) =>
      _db.batch((Batch b) => b.insertAll(_db.grammarTopics, batch));

  Future<int> topicCount() async {
    final Expression<int> countExp = _db.grammarTopics.id.count();
    final query = _db.selectOnly(_db.grammarTopics)
      ..addColumns(<Expression<Object>>[countExp]);
    final TypedResult row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<GrammarProgressRow?> _progressRow(String leafId) =>
      (_db.select(_db.grammarProgress)
            ..where((t) => t.lessonId.equals(leafId))
            ..limit(1))
          .getSingleOrNull();

  GrammarTopicSummary _summaryFromRow(QueryRow r) => GrammarTopicSummary(
        id: r.read<String>('id'),
        title: r.read<String>('title'),
        subtitle: r.readNullable<String>('subtitle'),
        isLeaf: r.read<int>('is_leaf') != 0,
        status: GrammarProgressStatus.fromIndex(r.read<int>('status')),
        isFavorite: r.read<int>('fav') != 0,
      );

  GrammarLesson _decodeLeaf(String id, String title, String contentJson) {
    final Map<String, dynamic> o =
        jsonDecode(contentJson) as Map<String, dynamic>;
    return GrammarLesson(
      id: id,
      title: title,
      introduction: _str(o['introduction']),
      urduExplanation: _str(o['urduExplanation']),
      englishExplanation: _str(o['englishExplanation']),
      types: _types(o['types']),
      additionalTypes: _types(o['additionalTypes']),
      degreeTypes: _types(o['degreeTypes']),
      degreeNote: _str(o['degreeNote']),
      degreeExamples: _strList(o['degreeExamples']),
      rules: _strList(o['rules']),
      structure: _strList(o['structure']),
      examples: _examples(o['examples']),
      commonMistakes: _mistakes(o['commonMistakes']),
      examTips: _strList(o['examTips']),
      practice: _questions(o['practice']),
      quiz: _questions(o['quiz']),
      summary: _str(o['summary']),
    );
  }

  static String _str(Object? v) => v?.toString().trim() ?? '';

  static List<String> _strList(Object? v) {
    if (v is! List) return const <String>[];
    return v
        .map((Object? e) => e?.toString().trim() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
  }

  static String? _nullStr(Object? v) {
    if (v == null) return null;
    final String s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static List<GrammarType> _types(Object? v) {
    if (v is! List) return const <GrammarType>[];
    final List<GrammarType> out = <GrammarType>[];
    for (final Object? e in v) {
      if (e is Map) {
        final String name = e['name']?.toString().trim() ?? '';
        final String desc = e['description']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          out.add(GrammarType(
            name: name,
            description: desc,
            urduExplanation: _str(e['urduExplanation']),
            wordFocus: _str(e['wordFocus']),
            exampleWords: _str(e['exampleWords']),
            pronounTable: _pronounRows(e['pronounTable']),
            tableTitle: _str(e['tableTitle']),
            tableColumns: _strList(e['tableColumns']),
            tableRows: _tableRows(e['tableRows']),
            tableGroups: _tableGroups(e['tableGroups']),
            childTypes: _types(e['childTypes']),
            subjectVerbAgreement: _str(e['subjectVerbAgreement']),
            subjectVerbAgreementUrdu: _str(e['subjectVerbAgreementUrdu']),
            examples: _examples(e['examples']),
            rules: _strList(e['rules']),
            ruleExamples: _strList(e['ruleExamples']),
            commonMistakes: _mistakes(e['commonMistakes']),
            practice: _questions(e['practice']),
          ));
        }
      }
    }
    return out;
  }

  static List<GrammarTableGroup> _tableGroups(Object? v) {
    if (v is! List) return const <GrammarTableGroup>[];
    return v.whereType<Map<String, dynamic>>().map((Map<String, dynamic> e) => GrammarTableGroup(
      title: _str(e['title']),
      columns: _strList(e['columns']),
      rows: _tableRows(e['rows']),
    )).where((GrammarTableGroup group) => group.title.isNotEmpty).toList(growable: false);
  }

  static List<GrammarTableRow> _tableRows(Object? v) {
    if (v is! List) return const <GrammarTableRow>[];
    return v.whereType<List<dynamic>>().map((List<dynamic> row) => GrammarTableRow(cells: row.map((e) => e.toString()).toList())).toList();
  }

  static List<GrammarPronounRow> _pronounRows(Object? v) {
    if (v is! List) return const <GrammarPronounRow>[];
    return v.whereType<Map<String, dynamic>>().map((Map<String, dynamic> e) => GrammarPronounRow(
      person: _str(e['person']),
      subject: _str(e['subject']),
      object: _str(e['object']),
    )).where((GrammarPronounRow row) => row.person.isNotEmpty).toList(growable: false);
  }

  static List<GrammarExample> _examples(Object? v) {
    if (v is! List) return const <GrammarExample>[];
    final List<GrammarExample> out = <GrammarExample>[];
    for (final Object? e in v) {
      if (e is String && e.isNotEmpty) {
        out.add(GrammarExample(text: e));
      } else if (e is Map) {
        final String text = e['text']?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          out.add(GrammarExample(
            text: text,
            urdu: _nullStr(e['urdu']),
            note: _nullStr(e['note']),
            referenceText: _nullStr(e['referenceText']),
            referenceUrdu: _nullStr(e['referenceUrdu']),
          ));
        }
      }
    }
    return out;
  }

  static List<GrammarMistake> _mistakes(Object? v) {
    if (v is! List) return const <GrammarMistake>[];
    final List<GrammarMistake> out = <GrammarMistake>[];
    for (final Object? e in v) {
      if (e is Map) {
        final String wrong = e['wrong']?.toString() ?? '';
        final String right = e['right']?.toString() ?? '';
        if (wrong.isNotEmpty || right.isNotEmpty) {
          out.add(GrammarMistake(
              wrong: wrong,
              right: right,
              note: _nullStr(e['note']),
              urdu: _nullStr(e['urdu']),
            ));
        }
      }
    }
    return out;
  }

  static List<GrammarQuestion> _questions(Object? v) {
    if (v is! List) return const <GrammarQuestion>[];
    final List<GrammarQuestion> out = <GrammarQuestion>[];
    for (final Object? e in v) {
      if (e is Map) {
        final String question = e['question']?.toString() ?? '';
        final List<String> options = _strList(e['options']);
        if (question.isEmpty || options.isEmpty) continue;
        final Object? raw = e['answerIndex'];
        final int idx = raw is int
            ? raw
            : (raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0);
        out.add(GrammarQuestion(
          question: question,
          options: options,
          answerIndex: idx.clamp(0, options.length - 1),
          explanation: _nullStr(e['explanation']),
        ));
      }
    }
    return out;
  }
}
