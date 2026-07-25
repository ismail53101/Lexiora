import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/guard.dart';
import 'package:lexiora/core/utils/typedefs.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';
import 'package:lexiora/modules/translation/domain/repositories/translation_repository.dart';

/// The word + target language to translate.
class TranslateParams {
  const TranslateParams(this.word, this.languageCode);
  final String word;
  final String languageCode;
}

/// Translates a single word into the target language. Returns `null` inside the
/// [Ok] branch when no offline translation exists.
class TranslateWord implements UseCase<Translation?, TranslateParams> {
  const TranslateWord(this._repo);
  final TranslationRepository _repo;

  @override
  ResultFuture<Translation?> call(TranslateParams params) => guard(() async {
        final String? text =
            await _repo.translate(params.word, params.languageCode);
        if (text == null || text.isEmpty) return null;
        return Translation(
          word: params.word,
          languageCode: params.languageCode,
          text: text,
        );
      });
}
