import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';

/// All local-database access for the dictionary module.
///
/// Kept separate from the repository so the query/SQL details live in one
/// place. Search is a grouped prefix query that uses the `word_lower` index via
/// a range bound (`>= q AND < q+￿`), which stays fast across 150k+ rows.
class DictionaryLocalDataSource {
  DictionaryLocalDataSource(this._db);

  final AppDatabase _db;

  // ── Search & lookup ────────────────────────────────────────────────────────

  Future<List<DictionaryResult>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return const <DictionaryResult>[];
    // Upper bound for a prefix range scan: any continuation sorts before this
    // high sentinel (U+FFFF), so `word_lower >= q AND word_lower < hi` is
    // exactly "starts with q" — and it uses the word_lower index.
    final String hi = '$q\u{FFFF}';

    final List<QueryRow> rows = await _db.customSelect(
      'SELECT e.word AS word, e.word_lower AS word_lower, '
      'e.part_of_speech AS pos, e.meaning AS meaning, '
      'MIN(e.id) AS rid, COUNT(*) AS sense_count, '
      'EXISTS(SELECT 1 FROM dictionary_favorites f '
      '       WHERE f.word_lower = e.word_lower) AS fav '
      'FROM dictionary_entries e '
      'WHERE e.word_lower >= ? AND e.word_lower < ? '
      'GROUP BY e.word_lower '
      'ORDER BY (e.word_lower = ?) DESC, e.word_lower ASC '
      'LIMIT ? OFFSET ?',
      variables: <Variable<Object>>[
        Variable<String>(q),
        Variable<String>(hi),
        Variable<String>(q),
        Variable<int>(limit),
        Variable<int>(offset),
      ],
      readsFrom: {_db.dictionaryEntries, _db.dictionaryFavorites},
    ).get();

    return rows
        .map(
          (QueryRow r) => DictionaryResult(
            word: r.read<String>('word'),
            wordLower: r.read<String>('word_lower'),
            meaning: r.read<String>('meaning'),
            partOfSpeech: r.readNullable<String>('pos'),
            senseCount: r.read<int>('sense_count'),
            isFavorite: r.read<int>('fav') != 0,
          ),
        )
        .toList(growable: false);
  }

  Future<WordDetails?> wordDetails(String wordLower) async {
    final String wl = wordLower.trim().toLowerCase();
    if (wl.isEmpty) return null;
    final List<DictionaryEntryRow> rows = await (_db.select(_db.dictionaryEntries)
          ..where((t) => t.wordLower.equals(wl))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
    if (rows.isEmpty) return null;
    return WordDetails(
      word: rows.first.word,
      wordLower: wl,
      senses: rows.map(_mapEntry).toList(growable: false),
      isFavorite: await isFavorite(wl),
    );
  }

  Future<DictionaryResult?> lookup(String wordLower) async {
    final String wl = wordLower.trim().toLowerCase();
    if (wl.isEmpty) return null;
    final DictionaryEntryRow? row = await (_db.select(_db.dictionaryEntries)
          ..where((t) => t.wordLower.equals(wl))
          ..orderBy([(t) => OrderingTerm(expression: t.id)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return DictionaryResult(
      word: row.word,
      wordLower: wl,
      meaning: row.meaning,
      partOfSpeech: row.partOfSpeech,
      senseCount: await _countSenses(wl),
      isFavorite: await isFavorite(wl),
    );
  }

  Future<int> entryCount() => _count();

  // ── Favorites ───────────────────────────────────────────────────────────────

  Future<bool> isFavorite(String wordLower) async {
    final DictionaryFavoriteRow? row = await (_db.select(_db.dictionaryFavorites)
          ..where((t) => t.wordLower.equals(wordLower))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Stream<bool> watchIsFavorite(String wordLower) =>
      (_db.select(_db.dictionaryFavorites)
            ..where((t) => t.wordLower.equals(wordLower)))
          .watch()
          .map((List<DictionaryFavoriteRow> rows) => rows.isNotEmpty);

  Stream<List<DictionaryResult>> watchFavorites() {
    final query = _db.select(_db.dictionaryFavorites)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
          (List<DictionaryFavoriteRow> rows) => rows
              .map(
                (DictionaryFavoriteRow r) => DictionaryResult(
                  word: r.word,
                  wordLower: r.wordLower,
                  meaning: r.meaning,
                  partOfSpeech: r.partOfSpeech,
                  isFavorite: true,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<void> addFavorite({
    required String wordLower,
    required String word,
    required String meaning,
    String? partOfSpeech,
  }) async {
    await _db.into(_db.dictionaryFavorites).insert(
          DictionaryFavoritesCompanion.insert(
            wordLower: wordLower,
            word: word,
            meaning: meaning,
            partOfSpeech: Value(partOfSpeech),
            createdAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> removeFavorite(String wordLower) async {
    await (_db.delete(_db.dictionaryFavorites)
          ..where((t) => t.wordLower.equals(wordLower)))
        .go();
  }

  // ── Seeding support ───────────────────────────────────────────────────────

  Future<String?> seededVersion() async {
    final SettingRow? row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(DictionaryConstants.seedVersionKey))
          ..limit(1))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSeededVersion(String version) async {
    await _db.into(_db.settings).insert(
          SettingsCompanion.insert(
            key: DictionaryConstants.seedVersionKey,
            value: version,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> clearEntries() =>
      _db.delete(_db.dictionaryEntries).go();

  Future<void> insertEntries(List<DictionaryEntriesCompanion> batch) =>
      _db.batch((Batch b) => b.insertAll(_db.dictionaryEntries, batch));

  /// Adds a single externally-sourced headword to the dictionary index so it is
  /// searchable. No-op if any entry already exists for the word (so bundled
  /// senses are never duplicated).
  Future<void> registerExternalWord({
    required String word,
    required String meaning,
    String? partOfSpeech,
  }) async {
    final String wl = word.trim().toLowerCase();
    if (wl.isEmpty || meaning.trim().isEmpty) return;
    final DictionaryEntryRow? existing =
        await (_db.select(_db.dictionaryEntries)
              ..where((t) => t.wordLower.equals(wl))
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return;
    await _db.into(_db.dictionaryEntries).insert(
          DictionaryEntriesCompanion.insert(
            word: word.trim(),
            wordLower: wl,
            meaning: meaning.trim(),
            partOfSpeech: Value<String?>(partOfSpeech),
          ),
        );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<int> _count([String? wordLower]) async {
    final Expression<int> countExp = _db.dictionaryEntries.id.count();
    final query = _db.selectOnly(_db.dictionaryEntries)..addColumns([countExp]);
    if (wordLower != null) {
      query.where(_db.dictionaryEntries.wordLower.equals(wordLower));
    }
    final TypedResult row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> _countSenses(String wordLower) => _count(wordLower);

  DictionaryEntry _mapEntry(DictionaryEntryRow r) => DictionaryEntry(
        id: r.id,
        word: r.word,
        meaning: r.meaning,
        partOfSpeech: r.partOfSpeech,
        ipaPronunciation: r.ipaPronunciation,
        exampleSentence: r.exampleSentence,
      );

  // ── Curated exam word pack (Dictionary v2) ──────────────────────────────────

  /// The curated exam data for a word, or `null` when it is not in the pack.
  Future<ExamWordData?> examData(String wordLower) async {
    final String wl = wordLower.trim().toLowerCase();
    if (wl.isEmpty) return null;
    final DictionaryExamEntryRow? row = await (_db.select(_db.dictionaryExamEntries)
          ..where((t) => t.wordLower.equals(wl))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _decodeExam(row.word, row.contentJson);
  }

  Future<String?> examSeededVersion() async {
    final SettingRow? row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(ExamDictionaryConstants.seedVersionKey))
          ..limit(1))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setExamSeededVersion(String version) async {
    await _db.into(_db.settings).insert(
          SettingsCompanion.insert(
            key: ExamDictionaryConstants.seedVersionKey,
            value: version,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> clearExamEntries() =>
      _db.delete(_db.dictionaryExamEntries).go();

  Future<void> insertExamEntries(
    List<DictionaryExamEntriesCompanion> batch,
  ) =>
      _db.batch((Batch b) => b.insertAll(_db.dictionaryExamEntries, batch));

  Future<int> examCount() async {
    final Expression<int> countExp = _db.dictionaryExamEntries.wordLower.count();
    final query = _db.selectOnly(_db.dictionaryExamEntries)
      ..addColumns(<Expression<Object>>[countExp]);
    final TypedResult row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  // ── Related words (derived from the base dictionary) ─────────────────────────

  /// Locally-derived morphological family for [wordLower] — words in the base
  /// dictionary that share the same root (e.g. economy → economic, economics,
  /// economist). Uses the indexed `word_lower` prefix range; returns display
  /// forms, shortest first. Empty for very short words (too noisy).
  Future<List<String>> relatedWords(String wordLower, {int limit = 8}) async {
    final String wl = wordLower.trim().toLowerCase();
    if (wl.length < 4) return const <String>[];
    // Root = the word minus a trailing "e" (English families share this stem,
    // e.g. inquire → inquir → inquiry/inquirer/inquiring; govern → govern →
    // government/governor/governance). Matching the full root — not a fixed-
    // length prefix — keeps results in-family and excludes look-alikes such as
    // policy → police.
    final String root = wl.endsWith('e') ? wl.substring(0, wl.length - 1) : wl;
    if (root.length < 4) return const <String>[];
    final String hi = '$root\u{FFFF}';
    final List<QueryRow> rows = await _db.customSelect(
      'SELECT word AS word, word_lower AS word_lower FROM dictionary_entries '
      'WHERE word_lower >= ? AND word_lower < ? AND word_lower != ? '
      'GROUP BY word_lower '
      'ORDER BY length(word_lower) ASC, word_lower ASC '
      'LIMIT ?',
      variables: <Variable<Object>>[
        Variable<String>(root),
        Variable<String>(hi),
        Variable<String>(wl),
        Variable<int>(limit),
      ],
      readsFrom: <ResultSetImplementation<Object, Object>>{_db.dictionaryEntries},
    ).get();
    return rows
        .map((QueryRow r) => r.read<String>('word'))
        .toList(growable: false);
  }

  // ── Search history (capped, auto-pruned) ────────────────────────────────────

  /// Records a search, then prunes to the most recent
  /// [SearchHistoryConstants.maxEntries].
  Future<void> addSearchHistory(String word) async {
    final String wl = word.trim().toLowerCase();
    if (wl.isEmpty) return;
    await _db.into(_db.dictionarySearchHistory).insert(
          DictionarySearchHistoryCompanion.insert(
            wordLower: wl,
            word: word.trim(),
            searchedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
    // Prune to the most recent entries. Ordering is by the monotonic rowid
    // (INSERT OR REPLACE assigns a fresh, larger rowid on every re-search),
    // which is reliable regardless of the DateTime column's storage precision.
    await _db.customStatement(
      'DELETE FROM dictionary_search_history WHERE rowid NOT IN ('
      'SELECT rowid FROM dictionary_search_history '
      'ORDER BY rowid DESC LIMIT ?)',
      <Object>[SearchHistoryConstants.maxEntries],
    );
  }

  Stream<List<String>> watchRecentSearches({int limit = 20}) => _db
      .customSelect(
        'SELECT word FROM dictionary_search_history '
        'ORDER BY rowid DESC LIMIT ?',
        variables: <Variable<Object>>[Variable<int>(limit)],
        readsFrom: <ResultSetImplementation<Object, Object>>{
          _db.dictionarySearchHistory,
        },
      )
      .watch()
      .map((List<QueryRow> rows) =>
          rows.map((QueryRow r) => r.read<String>('word')).toList(growable: false));

  Future<void> clearSearchHistory() =>
      _db.delete(_db.dictionarySearchHistory).go();

  // ── Exam JSON decoding ──────────────────────────────────────────────────────

  ExamWordData _decodeExam(String word, String contentJson) {
    final Map<String, dynamic> o =
        jsonDecode(contentJson) as Map<String, dynamic>;
    return ExamWordData(
      word: word,
      urduMeanings: _strList(o['urduMeanings']),
      englishDefinition: _nullStr(o['englishDefinition']),
      pronunciation: _nullStr(o['pronunciation']),
      pronunciationUk: _nullStr(o['pronunciationUk']),
      pronunciationUs: _nullStr(o['pronunciationUs']),
      partOfSpeech: _nullStr(o['partOfSpeech']),
      otherMeanings: _otherMeanings(o['otherMeanings']),
      synonyms: _strList(o['synonyms']),
      antonyms: _strList(o['antonyms']),
      usage: _usage(o['usage']),
      collocations: _strList(o['collocations']),
      wordForms: _strList(o['wordForms']),
      idioms: _strList(o['idioms']),
      examNote: _nullStr(o['examNote']),
    );
  }

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

  static List<OtherMeaning> _otherMeanings(Object? v) {
    if (v is! List) return const <OtherMeaning>[];
    final List<OtherMeaning> out = <OtherMeaning>[];
    for (final Object? e in v) {
      if (e is Map) {
        final List<String> urdu = _strList(e['urdu']);
        final String? english = _nullStr(e['english']);
        if (urdu.isNotEmpty || english != null) {
          out.add(OtherMeaning(urdu: urdu, english: english));
        }
      }
    }
    return out;
  }

  static WordUsage? _usage(Object? v) {
    if (v is! Map) return null;
    final String english = v['english']?.toString().trim() ?? '';
    if (english.isEmpty) return null;
    return WordUsage(
      context: v['context']?.toString().trim() ?? '',
      english: english,
      urdu: v['urdu']?.toString().trim() ?? '',
    );
  }
}
