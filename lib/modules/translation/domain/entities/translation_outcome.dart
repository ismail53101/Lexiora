import 'package:equatable/equatable.dart';
import 'package:lexiora/modules/translation/domain/entities/translation.dart';

/// The result of a hybrid (offline-first, online-fallback) translation lookup.
enum TranslationOutcomeStatus {
  /// Found locally (bundled data or the offline cache). No network was used.
  offline,

  /// Not found locally, fetched online and saved to the cache for offline reuse.
  online,

  /// Not found locally and the device is offline — nothing could be fetched.
  unavailableOffline,

  /// The online provider was reached but has no translation for this word.
  notFound,

  /// An unexpected error occurred while contacting the online provider.
  error,
}

/// Value object returned by the hybrid translate use case. Encodes both the
/// outcome [status] and, when successful, the [translation].
class TranslationOutcome extends Equatable {
  const TranslationOutcome(this.status, {this.translation});

  const TranslationOutcome.offline(Translation value)
      : status = TranslationOutcomeStatus.offline,
        translation = value;

  const TranslationOutcome.online(Translation value)
      : status = TranslationOutcomeStatus.online,
        translation = value;

  const TranslationOutcome.unavailableOffline()
      : status = TranslationOutcomeStatus.unavailableOffline,
        translation = null;

  const TranslationOutcome.notFound()
      : status = TranslationOutcomeStatus.notFound,
        translation = null;

  const TranslationOutcome.error()
      : status = TranslationOutcomeStatus.error,
        translation = null;

  final TranslationOutcomeStatus status;
  final Translation? translation;

  /// True when a translation is available (served offline or fetched online).
  bool get hasTranslation => translation != null;

  @override
  List<Object?> get props => <Object?>[status, translation];
}
