import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/translation/data/translation_seeder.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/domain/repositories/translation_repository.dart';
import 'package:lexiora/modules/translation/domain/usecases/translation_usecases.dart';

final Provider<TranslationRepository> translationRepositoryProvider =
    Provider<TranslationRepository>((Ref ref) => sl<TranslationRepository>());

final Provider<TranslationSeeder> translationSeederProvider =
    Provider<TranslationSeeder>((Ref ref) => sl<TranslationSeeder>());

final Provider<TranslateWord> translateWordProvider = Provider<TranslateWord>(
  (Ref ref) => TranslateWord(ref.watch(translationRepositoryProvider)),
);

/// Word + target language identifying a translation request.
typedef TranslateKey = ({String word, String lang});

/// Ensures the offline data is seeded (first use), then translates. Keyed by
/// (word, language) so switching language or word re-queries.
final translationProvider =
    FutureProvider.family<Translation?, TranslateKey>((Ref ref, TranslateKey key) async {
  await ref.watch(translationSeederProvider).ensureSeeded();
  final result =
      await ref.watch(translateWordProvider).call(TranslateParams(key.word, key.lang));
  return result.fold(
    (failure) => throw StateError(failure.message),
    (Translation? t) => t,
  );
});
