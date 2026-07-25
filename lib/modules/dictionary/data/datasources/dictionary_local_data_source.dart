import 'package:drift/drift.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';

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
}
