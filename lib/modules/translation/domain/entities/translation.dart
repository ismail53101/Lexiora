import 'package:equatable/equatable.dart';

/// Where a translation came from — used to label the reader popup.
enum TranslationSource {
  /// Served from the local database (bundled data set or the offline cache).
  offline,

  /// Fetched from the online provider on this lookup (and saved for reuse).
  online,
}

/// A translation of a single English word into a target language.
class Translation extends Equatable {
  const Translation({
    required this.word,
    required this.languageCode,
    required this.text,
    this.source = TranslationSource.offline,
  });

  /// The original (English) word that was translated.
  final String word;

  /// Two-letter target language code (e.g. "ur").
  final String languageCode;

  /// The translation text (one or more senses, joined).
  final String text;

  /// Whether this result was served locally or fetched online.
  final TranslationSource source;

  Translation copyWith({TranslationSource? source}) => Translation(
        word: word,
        languageCode: languageCode,
        text: text,
        source: source ?? this.source,
      );

  @override
  List<Object?> get props => <Object?>[word, languageCode, text, source];
}
