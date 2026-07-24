import 'package:lexiora/features/settings/domain/entities/app_settings.dart';

/// Domain contract for reading and persisting [AppSettings].
///
/// The presentation layer depends only on this interface; the Drift-backed
/// implementation lives in the data layer.
abstract interface class SettingsRepository {
  /// Emits the current settings and every subsequent change.
  Stream<AppSettings> watchSettings();

  /// One-shot read of the current settings.
  Future<AppSettings> getSettings();

  /// Persists the full settings snapshot.
  Future<void> updateSettings(AppSettings settings);
}
