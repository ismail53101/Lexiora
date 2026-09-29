import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/connectivity_service.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';
import 'package:lexiora/modules/translation/data/services/word_meaning_service.dart';
import 'package:lexiora/modules/translation/data/translation_seeder.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/domain/entities/translation_outcome.dart';
import 'package:lexiora/modules/translation/domain/repositories/translation_repository.dart';
import 'package:lexiora/modules/translation/domain/services/remote_translation_service.dart';
import 'package:lexiora/modules/translation/domain/usecases/hybrid_translate.dart';
import 'package:lexiora/modules/translation/domain/usecases/translation_usecases.dart';
import 'package:lexiora/modules/vocabulary/presentation/providers/vocabulary_providers.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

final Provider<TranslationRepository> translationRepositoryProvider =
    Provider<TranslationRepository>((Ref ref) => sl<TranslationRepository>());

final Provider<TranslationSeeder> translationSeederProvider =
    Provider<TranslationSeeder>((Ref ref) => sl<TranslationSeeder>());

final Provider<RemoteTranslationService> remoteTranslationServiceProvider =
    Provider<RemoteTranslationService>(
  (Ref ref) => sl<RemoteTranslationService>(),
);

final Provider<ConnectivityService> connectivityServiceProvider =
    Provider<ConnectivityService>((Ref ref) => sl<ConnectivityService>());

/// Resolves a single word's best English meaning (+ curated Urdu when
/// available) across the exam packs, base dictionary and free online
/// dictionary — shared by the popup's English-meaning section and the
/// sense-aware Urdu translation path.
final Provider<WordMeaningService> wordMeaningServiceProvider =
    Provider<WordMeaningService>((Ref ref) => sl<WordMeaningService>());

// ── Use cases ───────────────────────────────────────────────────────────────

final Provider<TranslateWord> translateWordProvider = Provider<TranslateWord>(
  (Ref ref) => TranslateWord(ref.watch(translationRepositoryProvider)),
);

final Provider<HybridTranslate> hybridTranslateProvider =
    Provider<HybridTranslate>(
  (Ref ref) => HybridTranslate(
    translationRepository: ref.watch(translationRepositoryProvider),
    remoteService: ref.watch(remoteTranslationServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    dictionaryRepository: ref.watch(dictionaryRepositoryProvider),
    meaningService: ref.watch(wordMeaningServiceProvider),
  ),
);

/// Word + target language identifying a translation request.
typedef TranslateKey = ({String word, String lang});

// ── Reactive queries ──────────────────────────────────────────────────────────

/// Offline-only translation. Used by the Dictionary's Urdu card (which must
/// never trigger a network call) and as the fast, backward-compatible path.
/// Keyed by (word, language) so switching language or word re-queries.
final translationProvider = FutureProvider.family<Translation?, TranslateKey>(
    (Ref ref, TranslateKey key) async {
  await ref.watch(translationSeederProvider).ensureSeeded();
  final result = await ref
      .watch(translateWordProvider)
      .call(TranslateParams(key.word, key.lang));
  return result.fold(
    (failure) => throw StateError(failure.message),
    (Translation? t) => t,
  );
});

/// Hybrid (offline-first, online-fallback) translation for the reader popup.
///
/// Keyed by (word, language); [FutureProvider.family] caches per key, so
/// repeated/concurrent lookups of the same word reuse one result instead of
/// firing duplicate API requests.
final hybridTranslationProvider =
    FutureProvider.family<TranslationOutcome, TranslateKey>(
        (Ref ref, TranslateKey key) async {
  await ref.watch(translationSeederProvider).ensureSeeded();
  // The sense-aware path reads the bundled dictionary + exam packs, both of
  // which seed lazily — ensure they are ready (idempotent, best-effort).
  try {
    await ref.watch(dictionarySeederProvider).ensureSeeded();
  } on Object {
    // Falls back to online only — acceptable on a broken seed.
  }
  // Curated exam dictionary (exam_words.json + common-words packs) — this is
  // what carries the simple English + Urdu meanings for everyday words, so it
  // must be seeded before the sense-aware resolution runs.
  try {
    await ref.watch(examWordsSeederProvider).ensureSeeded();
  } on Object {
    // Falls back to the base dictionary / online.
  }
  try {
    ref.watch(vocabularySeedProvider);
  } on Object {
    // Falls back to the base dictionary / online.
  }
  final result = await ref
      .watch(hybridTranslateProvider)
      .call(HybridTranslateParams(key.word, key.lang));
  return result.fold(
    (failure) => throw StateError(failure.message),
    (TranslationOutcome outcome) => outcome,
  );
});
