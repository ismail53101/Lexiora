import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/data/services/ai_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/data/services/stands4_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';

/// Aggregates the fully-offline parts of a word's profile: the curated exam
/// data (when present), the base dictionary senses, and locally-derived related
/// words. Urdu meanings (hybrid) and the bookmark state are supplied by their
/// own reactive providers, so this stays fast and network-free.
class GetWordProfile implements UseCase<WordProfile, String> {
  const GetWordProfile(this._repo, [this._ai, this._stands4]);

  final DictionaryRepository _repo;
  final AiDictionaryService? _ai;
  final Stands4DictionaryService? _stands4;

  @override
  ResultFuture<WordProfile> call(String wordLower) => guard(() async {
        final String wl = wordLower.trim().toLowerCase();
        final ExamWordData? exam = await _repo.examData(wl);
        final WordDetails? base = await _repo.wordDetails(wl);
        final List<String> related = await _repo.relatedWords(wl);
        // Any local record is the source of truth and must open immediately.
        // AI is reserved for a truly missing word, avoiding a network wait for
        // entries that already have a meaning, synonyms, antonyms, or example.
        final bool existsOffline = exam != null || base != null;
        AiWordProfile? ai;
        if (!existsOffline) {
          // Missing from the entire local dictionary: AI is the only fallback.
          // STANDS4 is intentionally not called here.
          ai = await _ai?.define(wl);
        } else if (exam == null || exam.synonyms.isEmpty) {
          // Word is in the offline dictionary but has no curated synonyms:
          // enrich ONLY synonyms/antonyms from STANDS4 (synonyms.com). The
          // offline meaning/example stay untouched; failure is silent.
          final AiWordProfile? online = await _stands4?.define(wl);
          if (online != null &&
              (online.synonyms.isNotEmpty || online.antonyms.isNotEmpty)) {
            ai = AiWordProfile(
              word: online.word,
              source: 'stands4',
              synonyms: online.synonyms,
              antonyms: online.antonyms,
            );
          }
        }
        return WordProfile(
          word: exam?.word ?? base?.word ?? wordLower,
          wordLower: wl,
          exam: exam,
          base: base,
          relatedWords: related,
          ai: ai?.hasContent == true ? ai : null,
        );
      });
}
