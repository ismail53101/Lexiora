import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';

/// Aggregates the fully-offline parts of a word's profile: the curated exam
/// data (when present), the base dictionary senses, and locally-derived related
/// words. Urdu meanings (hybrid) and the bookmark state are supplied by their
/// own reactive providers, so this stays fast and network-free.
class GetWordProfile implements UseCase<WordProfile, String> {
  const GetWordProfile(this._repo);

  final DictionaryRepository _repo;

  @override
  ResultFuture<WordProfile> call(String wordLower) => guard(() async {
        final String wl = wordLower.trim().toLowerCase();
        final ExamWordData? exam = await _repo.examData(wl);
        final WordDetails? base = await _repo.wordDetails(wl);
        final List<String> related = await _repo.relatedWords(wl);
        return WordProfile(
          word: exam?.word ?? base?.word ?? wordLower,
          wordLower: wl,
          exam: exam,
          base: base,
          relatedWords: related,
        );
      });
}
