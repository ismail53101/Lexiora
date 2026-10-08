import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/data/services/ai_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/data/services/stands4_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/usage_relevance.dart';

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
        // Enrich incomplete local entries as well as completely missing words.
        // The bundled 6k+ dictionary remains the primary source; AI only fills
        // fields that are absent, so we never replace curated/local content.
        final List<String> missingFields = <String>[];
        AiWordProfile? ai;
        final bool hasEnglish = (exam?.englishDefinition?.trim().isNotEmpty == true) ||
            (base?.primary?.meaning.trim().isNotEmpty == true);
        final bool hasUrdu = exam?.urduMeanings.isNotEmpty == true;
        final bool hasSynonyms = exam?.synonyms.isNotEmpty == true;
        final bool hasAntonyms = exam?.antonyms.isNotEmpty == true;
        final bool hasExample = validatedUsage(wl, exam?.usage) != null ||
            base?.primary?.exampleSentence?.trim().isNotEmpty == true;
        final bool hasCollocations = exam?.collocations.isNotEmpty == true;
        final bool hasWordForms = exam?.wordForms.isNotEmpty == true || related.isNotEmpty;
        final bool hasExamNote = exam?.examNote?.trim().isNotEmpty == true;

        if (!hasEnglish) missingFields.add('englishDefinition');
        if (!hasUrdu) missingFields.add('urduMeanings');
        if (!hasSynonyms) missingFields.add('synonyms');
        if (!hasAntonyms) missingFields.add('antonyms');
        if (!hasExample) {
          missingFields.add('exampleSentence');
          missingFields.add('exampleSentenceUrdu');
        }
        if (!hasCollocations) missingFields.add('collocations');
        if (!hasWordForms) missingFields.add('wordForms');
        if (!hasExamNote) missingFields.add('examNote');
        if (missingFields.isNotEmpty) {
          ai = await _ai?.define(wl, missingFields: missingFields);
          ai ??= await _stands4?.define(wl);
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
