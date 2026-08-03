/// Compile-time build flags — evaluated once, at compile time, via
/// `--dart-define`. Unlike a runtime setting, code gated behind one of
/// these doesn't exist at all in a build where the flag is off (dead-code
/// eliminated), not just hidden.
abstract final class BuildFlags {
  /// Whether this build includes the Admin Panel (personal-use content
  /// curation). Never set for the public Play Store build — build a
  /// private/dev APK with `--dart-define=SAPIORA_ENABLE_ADMIN=true` to
  /// include it.
  static const bool enableAdmin =
      bool.fromEnvironment('SAPIORA_ENABLE_ADMIN');
}
