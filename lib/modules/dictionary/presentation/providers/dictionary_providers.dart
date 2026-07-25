import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/dictionary/data/dictionary_seeder.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/repositories/dictionary_repository.dart';
import 'package:lexiora/modules/dictionary/domain/usecases/dictionary_usecases.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final Provider<DictionaryRepository> dictionaryRepositoryProvider =
    Provider<DictionaryRepository>((Ref ref) => sl<DictionaryRepository>());

final Provider<DictionarySeeder> dictionarySeederProvider =
    Provider<DictionarySeeder>((Ref ref) => sl<DictionarySeeder>());

// ── Use cases ─────────────────────────────────────────────────────────────────

final Provider<SearchDictionary> searchDictionaryProvider =
    Provider<SearchDictionary>(
  (Ref ref) => SearchDictionary(ref.watch(dictionaryRepositoryProvider)),
);

final Provider<GetWordDetails> getWordDetailsProvider =
    Provider<GetWordDetails>(
  (Ref ref) => GetWordDetails(ref.watch(dictionaryRepositoryProvider)),
);

final Provider<LookUpWord> lookUpWordProvider = Provider<LookUpWord>(
  (Ref ref) => LookUpWord(ref.watch(dictionaryRepositoryProvider)),
);

final Provider<ToggleWordFavorite> toggleWordFavoriteProvider =
    Provider<ToggleWordFavorite>(
  (Ref ref) => ToggleWordFavorite(ref.watch(dictionaryRepositoryProvider)),
);

// ── Reactive queries ──────────────────────────────────────────────────────────

/// Streams the saved-words list (most recently saved first).
final StreamProvider<List<DictionaryResult>> favoritesProvider =
    StreamProvider<List<DictionaryResult>>(
  (Ref ref) => WatchFavorites(ref.watch(dictionaryRepositoryProvider))
      .call(const NoParams()),
);

/// Reactive favorite state for a single word (keeps the ⭐ in sync everywhere).
final isWordFavoriteProvider = StreamProvider.family<bool, String>(
  (Ref ref, String wordLower) =>
      ref.watch(dictionaryRepositoryProvider).watchIsFavorite(wordLower),
);

/// Loads all senses for a headword (Word Details screen). Ensures the
/// dictionary is seeded first, so deep links / cold opens still work.
final wordDetailsProvider = FutureProvider.family<WordDetails?, String>(
  (Ref ref, String wordLower) async {
    await ref.watch(dictionarySeederProvider).ensureSeeded();
    final result =
        await ref.watch(getWordDetailsProvider).call(wordLower);
    return result.fold(
      (failure) => throw StateError(failure.message),
      (WordDetails? details) => details,
    );
  },
);

/// Primary-sense lookup for the lightweight reader popup. Ensures the
/// dictionary is seeded (handles first use from the reader before the
/// Dictionary screen has ever been opened).
final wordLookupProvider = FutureProvider.family<DictionaryResult?, String>(
  (Ref ref, String wordLower) async {
    await ref.watch(dictionarySeederProvider).ensureSeeded();
    final result = await ref.watch(lookUpWordProvider).call(wordLower);
    return result.fold(
      (failure) => throw StateError(failure.message),
      (DictionaryResult? r) => r,
    );
  },
);
