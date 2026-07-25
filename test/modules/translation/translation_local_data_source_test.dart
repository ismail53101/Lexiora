import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/translation/data/datasources/translation_local_data_source.dart';

/// Verifies the offline translation lookup against a real in-memory database:
/// language scoping, case-insensitivity and graceful misses.
void main() {
  late AppDatabase db;
  late TranslationLocalDataSource ds;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ds = TranslationLocalDataSource(db);
    await ds.insertEntries(<TranslationEntriesCompanion>[
      TranslationEntriesCompanion.insert(
          langCode: 'fr', wordLower: 'apple', translation: 'pomme'),
      TranslationEntriesCompanion.insert(
          langCode: 'fr', wordLower: 'dog', translation: 'chien'),
      TranslationEntriesCompanion.insert(
          langCode: 'hi', wordLower: 'apple', translation: 'सेब'),
      TranslationEntriesCompanion.insert(
          langCode: 'ar', wordLower: 'book', translation: 'كتاب'),
      TranslationEntriesCompanion.insert(
          langCode: 'ur', wordLower: 'book', translation: 'کِتاب، بُک'),
      TranslationEntriesCompanion.insert(
          langCode: 'ur', wordLower: 'apple', translation: 'سیب'),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  test('translates a word into the requested language', () async {
    expect(await ds.translate('apple', 'fr'), 'pomme');
    expect(await ds.translate('dog', 'fr'), 'chien');
    expect(await ds.translate('book', 'ar'), 'كتاب');
  });

  test('Urdu is a first-class target language', () async {
    expect(await ds.translate('book', 'ur'), 'کِتاب، بُک');
    expect(await ds.translate('apple', 'ur'), 'سیب');
    expect(await ds.translate('Book', 'ur'), 'کِتاب، بُک'); // case-insensitive
  });

  test('lookup is case-insensitive and trims', () async {
    expect(await ds.translate('  APPLE ', 'fr'), 'pomme');
  });

  test('translation is scoped to the language', () async {
    expect(await ds.translate('apple', 'hi'), 'सेब');
    // "dog" only exists for fr, so hi returns null.
    expect(await ds.translate('dog', 'hi'), isNull);
  });

  test('returns null for missing words or unsupported languages', () async {
    expect(await ds.translate('missing', 'fr'), isNull);
    expect(await ds.translate('apple', 'de'), isNull);
    expect(await ds.translate('', 'fr'), isNull);
  });

  test('entryCount reflects inserted rows', () async {
    expect(await ds.entryCount(), 6);
  });
}
