import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/features/settings/domain/entities/app_settings.dart';
import 'package:lexiora/features/settings/domain/repositories/settings_repository.dart';

/// Exposes the [SettingsRepository] from the service locator.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((Ref ref) => sl<SettingsRepository>());

/// Reactive stream of the current [AppSettings]. Drives the theme and reader.
final StreamProvider<AppSettings> settingsProvider =
    StreamProvider<AppSettings>(
  (Ref ref) => ref.watch(settingsRepositoryProvider).watchSettings(),
);

/// Imperative controller for mutating settings. Each setter reads the latest
/// snapshot then persists the single changed field.
final Provider<SettingsController> settingsControllerProvider =
    Provider<SettingsController>(
  (Ref ref) => SettingsController(ref.watch(settingsRepositoryProvider)),
);

class SettingsController {
  const SettingsController(this._repo);

  final SettingsRepository _repo;

  Future<void> setThemeMode(ThemeMode mode) =>
      _mutate((AppSettings s) => s.copyWith(themeMode: mode));

  Future<void> setFontScale(double scale) =>
      _mutate((AppSettings s) => s.copyWith(fontScale: scale));

  Future<void> setScrollAxis(ReaderScrollAxis axis) =>
      _mutate((AppSettings s) => s.copyWith(readingScrollAxis: axis));

  Future<void> setColorMode(ReaderColorMode mode) =>
      _mutate((AppSettings s) => s.copyWith(readerColorMode: mode));

  Future<void> setDefaultHighlightColor(int color) =>
      _mutate((AppSettings s) => s.copyWith(defaultHighlightColor: color));

  Future<void> setKeepScreenAwake(bool value) =>
      _mutate((AppSettings s) => s.copyWith(keepScreenAwake: value));

  Future<void> setAutoResume(bool value) =>
      _mutate((AppSettings s) => s.copyWith(autoResume: value));

  Future<void> setTranslationLanguage(String code) =>
      _mutate((AppSettings s) => s.copyWith(translationLanguage: code));

  Future<void> _mutate(AppSettings Function(AppSettings) update) async {
    final AppSettings current = await _repo.getSettings();
    await _repo.updateSettings(update(current));
  }
}
