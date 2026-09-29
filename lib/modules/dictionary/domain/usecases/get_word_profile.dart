import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/data/services/ai_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';

/// Aggregates the fully-offline parts of a word's profile: the curated exam
/// data (when present), the base dictionary senses, and locally-derived related
/// words. Urdu meanings (hybrid) and the bookmark state are supplied by their
/// own reactive providers, so this stays fast and network-free.
class GetWordProfile implements UseCase<WordProfile, String> {
  const GetWordProfile(this._repo, [this._ai]);

  final DictionaryRepository _repo;
  final AiDictionaryService? _ai;

  @override
  ResultFuture<WordProfile> call(String wordLower) => guard(() async {
        final String wl = wordLower.trim().toLowerCase();
        final ExamWordData? exam = await _repo.examData(wl);
        final WordDetails? base = await _repo.wordDetails(wl);
        final List<String> related = await _repo.relatedWords(wl);
        // Complete curated exam-pack words are the source of truth. Do not
        // spend an AI request on them and never let AI replace their checked
        // meanings, synonyms, antonyms, examples, or Urdu content. A curated
        // word with missing sections, or a word outside the curated pack, may
        // still receive AI enrichment when the device is online.
        final List<String> missing = <String>[];
        if (exam?.englishDefinition?.trim().isNotEmpty != true &&
            base?.primary?.meaning == null) {
          missing.add('englishDefinition');
        }
        if (exam?.urduMeanings.isNotEmpty != true) missing.add('urduMeanings');
        if (exam?.partOfSpeech?.trim().isNotEmpty != true &&
            base?.primary?.partOfSpeech == null) {
          missing.add('partOfSpeech');
        }
        if (exam?.synonyms.isNotEmpty != true) missing.add('synonyms');
        if (exam?.antonyms.isNotEmpty != true) missing.add('antonyms');
        if (exam?.usage == null && base?.primary?.exampleSentence == null) {
          missing.add('exampleSentence');
        }
        if (exam?.collocations.isNotEmpty != true) missing.add('collocations');
        if (exam?.examNote?.trim().isNotEmpty != true) missing.add('examNote');
        final AiWordProfile? ai = missing.isEmpty
            ? null
            : await _ai?.define(wl, missingFields: missing);
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
