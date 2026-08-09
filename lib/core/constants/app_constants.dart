/// Global, compile-time constants for Lexiora.
///
/// Anything that might change per-environment lives in settings or the database
/// instead — these are true constants that never require a rewrite.
abstract final class AppConstants {
  static const String appName = 'Sapiora';
  static const String appTagline = 'Read. Study. Master languages.';
  static const String appVersion = '0.12.0';

  /// Shown in the Home greeting and Profile screen. Sapiora has no account
  /// system — this is the developer's own copy of the app for now.
  static const String userDisplayName = 'Ismail';

  /// Sub-directories (inside the app documents dir) used for local storage.
  static const String documentsDirName = 'documents';
  static const String coversDirName = 'covers';

  /// Shared animation timings for a consistent, premium feel.
  static const Duration animFast = Duration(milliseconds: 180);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 550);

  /// Default catalogue of highlight/underline colors (ARGB int values).
  /// Users can pick any of these; the set is data, not hard-coded UI.
  static const List<int> defaultHighlightColors = <int>[
    0xFFFFF176, // amber
    0xFF81C784, // green
    0xFF64B5F6, // blue
    0xFFE57373, // red
    0xFFBA68C8, // purple
    0xFFFFB74D, // orange
  ];

  /// Color pre-selected when creating a new highlight (first of the palette).
  /// Declared separately so it can be used as a const default value.
  static const int primaryHighlightColor = 0xFFFFF176;
}
