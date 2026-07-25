/// Domain contract for the offline word-translation feature.
///
/// Fully offline: translations come from a bundled, indexed local table. There
/// is deliberately no network path.
abstract interface class TranslationRepository {
  /// Returns the offline translation of [word] into [languageCode], or `null`
  /// when the word has no bundled translation for that language.
  Future<String?> translate(String word, String languageCode);

  /// Total number of indexed translation rows (diagnostics / seed check).
  Future<int> entryCount();
}
