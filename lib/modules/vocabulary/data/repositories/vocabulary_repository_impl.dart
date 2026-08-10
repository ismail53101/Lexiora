import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/vocabulary/data/datasources/vocabulary_local_data_source.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_list.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/domain/repositories/vocabulary_repository.dart';

/// Maps Drift rows to domain entities. No business logic beyond translation.
class VocabularyRepositoryImpl implements VocabularyRepository {
  VocabularyRepositoryImpl(this._local);

  final VocabularyLocalDataSource _local;

  @override
  Stream<List<VocabularyListSummary>> watchLists() =>
      _local.watchLists().map((List<VocabularyListRow> rows) =>
          rows.map(_toList).toList(growable: false));

  @override
  Stream<List<VocabularyWord>> watchWords(String listId) =>
      _local.watchWords(listId).map((List<VocabularyWordRow> rows) =>
          rows.map(_toWord).toList(growable: false));

  @override
  Future<VocabularyWord?> lookupWord(String wordLower) async {
    final VocabularyWordRow? row = await _local.lookupWord(wordLower);
    return row == null ? null : _toWord(row);
  }

  VocabularyListSummary _toList(VocabularyListRow r) => VocabularyListSummary(
        id: r.id,
        title: r.title,
        subtitle: r.subtitle,
        wordCount: r.wordCount,
      );

  VocabularyWord _toWord(VocabularyWordRow r) => VocabularyWord(
        id: r.id,
        listId: r.listId,
        word: r.word,
        letter: r.letter,
        urduMeaning: r.urduMeaning,
        englishMeaning: r.englishMeaning,
        ipa: r.ipa,
        partOfSpeech: r.partOfSpeech,
      );
}
