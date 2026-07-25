/// A target language offered by the offline Translate feature.
class TranslationLanguage {
  const TranslationLanguage(this.code, this.englishName, this.nativeName);

  /// Two-letter code stored in settings and in the translation table.
  final String code;
  final String englishName;
  final String nativeName;

  String get label => englishName == nativeName
      ? englishName
      : '$englishName · $nativeName';
}

/// The languages that have bundled offline translation data. Adding a language
/// here (plus its data in the bundled asset) is all that's needed to offer it.
///
/// **Urdu is listed first** and is the default (see [kDefaultTranslationLanguage]),
/// prioritising it for the app's primary (Pakistani) audience while keeping the
/// list fully user-selectable.
const List<TranslationLanguage> kTranslationLanguages = <TranslationLanguage>[
  TranslationLanguage('ur', 'Urdu', 'اردو'),
  TranslationLanguage('fr', 'French', 'Français'),
  TranslationLanguage('pt', 'Portuguese', 'Português'),
  TranslationLanguage('hi', 'Hindi', 'हिन्दी'),
  TranslationLanguage('ar', 'Arabic', 'العربية'),
];

/// Default target language when the user hasn't chosen one yet. Urdu-first for
/// the app's Pakistani audience; users can change it in Settings.
const String kDefaultTranslationLanguage = 'ur';

/// Resolves a stored code to a [TranslationLanguage], falling back to the first
/// supported language for unknown/empty codes.
TranslationLanguage translationLanguageByCode(String code) =>
    kTranslationLanguages.firstWhere(
      (TranslationLanguage l) => l.code == code,
      orElse: () => kTranslationLanguages.first,
    );

/// Whether [code] is a supported target language.
bool isSupportedTranslationLanguage(String code) =>
    kTranslationLanguages.any((TranslationLanguage l) => l.code == code);
