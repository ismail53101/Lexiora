import 'package:drift/drift.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';

/// All Drift queries for the Vocabulary module live here. Read-mostly content
/// (lists + words) is seeded from bundled JSON packs; there is no user state in
/// this module yet (favorites/progress will arrive with Flashcards/Quiz).
class VocabularyLocalDataSource {
  VocabularyLocalDataSource(this._db);

  final AppDatabase _db;

  // ── Reads ───────────────────────────────────────────────────────────────────

  /// Lists ordered by their configured order, then title. Reactive.
  Stream<List<VocabularyListRow>> watchLists() {
    return (_db.select(_db.vocabularyLists)
          ..orderBy(<OrderClauseGenerator<$VocabularyListsTable>>[
            (t) => OrderingTerm(expression: t.orderIndex),
            (t) => OrderingTerm(expression: t.title),
          ]))
        .watch();
  }

  /// Words in [listId] ordered A–Z by lowercased headword. Reactive.
  Stream<List<VocabularyWordRow>> watchWords(String listId) {
    return (_db.select(_db.vocabularyWords)
          ..where((t) => t.listId.equals(listId))
          ..orderBy(<OrderClauseGenerator<$VocabularyWordsTable>>[
            (t) => OrderingTerm(expression: t.wordLower),
          ]))
        .watch();
  }

  /// One-shot, case-insensitive headword lookup across every vocabulary pack.
  /// Used by reader/translation popups to surface the curated English + Urdu
  /// meaning of an exam word; returns the first pack that contains it.
  Future<VocabularyWordRow?> lookupWord(String wordLower) async {
    final String wl = wordLower.trim().toLowerCase();
    if (wl.isEmpty) return null;
    return (_db.select(_db.vocabularyWords)
          ..where((t) => t.wordLower.equals(wl))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> wordCount() async {
    final Expression<int> c = _db.vocabularyWords.id.count();
    final query = _db.selectOnly(_db.vocabularyWords)
      ..addColumns(<Expression<Object>>[c]);
    return (await query.getSingle()).read(c) ?? 0;
  }

  Future<int> listCount() async {
    final Expression<int> c = _db.vocabularyLists.id.count();
    final query = _db.selectOnly(_db.vocabularyLists)
      ..addColumns(<Expression<Object>>[c]);
    return (await query.getSingle()).read(c) ?? 0;
  }

  // ── Seeding (non-destructive: only these two tables) ────────────────────────

  Future<String?> seededVersion() async {
    final SettingRow? row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(VocabularyConstants.seedVersionKey))
          ..limit(1))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSeededVersion(String version) async {
    await _db.into(_db.settings).insert(
          SettingsCompanion.insert(
            key: VocabularyConstants.seedVersionKey,
            value: version,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> clearAll() async {
    await _db.delete(_db.vocabularyWords).go();
    await _db.delete(_db.vocabularyLists).go();
  }

  Future<void> insertLists(List<VocabularyListsCompanion> rows) =>
      _db.batch((Batch b) => b.insertAll(
            _db.vocabularyLists,
            rows,
            mode: InsertMode.insertOrReplace,
          ));

  Future<void> insertWords(List<VocabularyWordsCompanion> rows) =>
      _db.batch((Batch b) => b.insertAll(
            _db.vocabularyWords,
            rows,
            mode: InsertMode.insertOrReplace,
          ));
}
