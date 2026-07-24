import 'dart:developer' as developer;

/// Minimal structured logger built on `dart:developer` (so it is stripped in
/// release output but visible via `flutter logs` / logcat, and never triggers
/// the `avoid_print` lint). Used across navigation, file checks and PDF loading
/// so failures are always diagnosable instead of silent.
abstract final class AppLogger {
  static const String _tag = 'Lexiora';

  static void d(String message, {String name = _tag}) =>
      developer.log(message, name: name, level: 500);

  static void i(String message, {String name = _tag}) =>
      developer.log(message, name: name, level: 800);

  static void w(String message, {String name = _tag}) =>
      developer.log(message, name: name, level: 900);

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = _tag,
  }) =>
      developer.log(
        message,
        name: name,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
}
