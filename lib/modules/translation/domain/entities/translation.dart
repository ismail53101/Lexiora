import 'package:equatable/equatable.dart';

/// An offline translation of a single English word into a target language.
class Translation extends Equatable {
  const Translation({
    required this.word,
    required this.languageCode,
    required this.text,
  });

  /// The original (English) word that was translated.
  final String word;

  /// Two-letter target language code (e.g. "fr").
  final String languageCode;

  /// The translation text (one or more senses, joined).
  final String text;

  @override
  List<Object?> get props => [word, languageCode, text];
}
