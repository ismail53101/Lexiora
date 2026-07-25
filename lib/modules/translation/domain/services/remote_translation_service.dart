/// Contract for an online translation provider used as a **fallback** when no
/// offline translation exists.
///
/// This abstraction is the seam that keeps the provider swappable: the UI and
/// use cases depend only on this interface, so switching from the default
/// (MyMemory) to another provider (LibreTranslate, a paid API, an on-prem
/// service, …) is a single DI binding change with no other code touched.
abstract interface class RemoteTranslationService {
  /// Translates [word] (English) into [targetLanguageCode].
  ///
  /// Returns the translated text, or `null` when the provider responds but has
  /// no usable translation. Throws when the provider cannot be reached or
  /// returns an error (so callers can distinguish "no translation" from a
  /// network failure).
  Future<String?> translate({
    required String word,
    required String targetLanguageCode,
  });

  /// Provider name, for diagnostics/logging.
  String get providerName;
}
