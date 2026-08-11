import 'package:lexiora/modules/dictionary/data/services/definition_sense.dart';
import 'package:lexiora/modules/dictionary/data/services/online_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
import 'package:lexiora/modules/translation/data/services/core_word_overrides.dart';
import 'package:lexiora/modules/vocabulary/data/base_forms.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/domain/repositories/vocabulary_repository.dart';

/// A word's resolved meaning: a short English definition (the sense that makes
/// sense for CSS/BPSC writing), its part of speech, and — when the word is in a
/// curated exam pack — the pack's simple Urdu meaning (offline, exam-ready).
class WordMeaning {
  const WordMeaning({
    required this.meaning,
    this.partOfSpeech,
    this.urdu,
    required this.fromOnline,
  });

  final String meaning;
  final String? partOfSpeech;

  /// Curated Urdu from the exam packs (CSS/BPSC etc.). `null` when the word is
  /// not in any curated pack, in which case the caller translates [meaning].
  final String? urdu;

  /// True when [meaning] came from the free online dictionary (only reached
  /// when every local source missed).
  final bool fromOnline;
}

/// Resolves the single best English meaning (+ optional curated Urdu) for a
/// word, exam-first:
///
///   1. **Curated vocabulary packs** (CSS/BPSC, IELTS, …) — exact match, then
///      inflected→base-form match ("contributing" → "Contribute"). These carry
///      exactly the short English + Urdu meanings competitive-exam readers
///      need.
///   2. **Dictionary v2 curated exam pack** (`examData`) — rich curated data.
///   3. **Curated core-word overrides** — for common words whose raw dictionary
///      senses are misleading ("people" → "fill with people", "standard" →
///      "any distinctive flag"), a small hand-picked map pins the exam-usable
///      English meaning + simple Urdu, matched on base forms too.
///   4. **Base offline dictionary** — all senses, best (most general) chosen
///      via [pickBestDefinitionIndex], so "attention" → "mental concentration"
///      instead of "treatment" and "tragedy" → "an event resulting in great
///      loss" instead of "a type of drama".
///   5. **Free online dictionary** — best sense, used only as a last resort.
///
/// Every tier is individually guarded: a failure in any source never blocks
/// the others and never throws.
class WordMeaningService {
  WordMeaningService({
    required DictionaryRepository dictionary,
    required VocabularyRepository vocabulary,
    required OnlineDictionaryService online,
  })  : _dictionary = dictionary,
        _vocabulary = vocabulary,
        _online = online;

  final DictionaryRepository _dictionary;
  final VocabularyRepository _vocabulary;
  final OnlineDictionaryService _online;

  static final RegExp _urduScript = RegExp(r'[\u0600-\u06FF\u0750-\u077F]');

  Future<WordMeaning?> resolve(String wordLower) async {
    final String wl = wordLower.trim().toLowerCase();
    if (wl.isEmpty) return null;

    // 1) Curated exam vocabulary packs (exact, then base form).
    try {
      final VocabularyWord? pack = await _vocabulary.lookupWordFlexible(wl);
      if (pack != null) {
        return WordMeaning(
          meaning: pack.englishMeaning,
          partOfSpeech: pack.partOfSpeech,
          urdu: pack.urduMeaning,
          fromOnline: false,
        );
      }
    } on Object {
      // Packs unavailable — continue to the next source.
    }

    // 2) Dictionary v2 curated exam pack.
    try {
      final ExamWordData? exam = await _dictionary.examData(wl);
      final String? definition = exam?.englishDefinition;
      if (exam != null && definition != null && definition.trim().isNotEmpty) {
        return WordMeaning(
          meaning: definition.trim(),
          partOfSpeech: exam.partOfSpeech,
          urdu: exam.urduMeanings.isEmpty ? null : exam.urduMeanings.first,
          fromOnline: false,
        );
      }
    } on Object {
      // Ignore — continue.
    }

    // 3) Curated core-word overrides (exact, then inflected→base form).
    for (final String form in baseForms(wl)) {
      final List<String>? override = kCoreWordOverrides[form];
      if (override != null && override.isNotEmpty) {
        return WordMeaning(
          meaning: override[0],
          partOfSpeech: override.length > 1 ? override[1] : null,
          urdu: override.length > 2 ? override[2] : null,
          fromOnline: false,
        );
      }
    }

    // 4) Base offline dictionary — best (most general) sense across all senses.
    try {
      final WordDetails? details = await _dictionary.wordDetails(wl);
      if (details != null && details.senses.isNotEmpty) {
        final List<String> defs = <String>[];
        final List<String?> poses = <String?>[];
        for (final DictionaryEntry s in details.senses) {
          // The Translation module registers translated text (often Urdu) into
          // the dictionary index; that is not an English definition.
          if (_urduScript.hasMatch(s.meaning)) continue;
          defs.add(s.meaning);
          poses.add(s.partOfSpeech);
        }
        final int? best = pickBestDefinitionIndex(defs);
        if (best != null) {
          return WordMeaning(
            meaning: defs[best],
            partOfSpeech: poses[best],
            fromOnline: false,
          );
        }
      }
    } on Object {
      // Ignore — continue.
    }

    // 5) Free online dictionary — best sense.
    try {
      final OnlineDefinition? online = await _online.define(wl);
      if (online != null) {
        return WordMeaning(
          meaning: online.meaning,
          partOfSpeech: online.partOfSpeech,
          fromOnline: true,
        );
      }
    } on Object {
      // Ignore — the word simply has no resolvable meaning right now.
    }

    return null;
  }
}
