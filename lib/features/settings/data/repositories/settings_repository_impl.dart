import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:lexiora/core/constants/app_constants.dart';
import 'package:lexiora/core/constants/translation_languages.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/features/settings/domain/entities/app_settings.dart';
import 'package:lexiora/features/settings/domain/repositories/settings_repository.dart';

/// Drift-backed [SettingsRepository]. Settings are stored as simple key-value
/// rows so the schema never needs migrating when a new preference is added.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  static const String _kThemeMode = 'themeMode';
  static const String _kFontScale = 'fontScale';
  static const String _kScrollAxis = 'scrollAxis';
  static const String _kColorMode = 'colorMode';
  static const String _kHighlightColors = 'highlightColors';
  static const String _kDefaultHighlightColor = 'defaultHighlightColor';
  static const String _kKeepAwake = 'keepScreenAwake';
  static const String _kAutoResume = 'autoResume';
  static const String _kTranslationLanguage = 'translationLanguage';

  @override
  Stream<AppSettings> watchSettings() =>
      _db.select(_db.settings).watch().map(_fromRows);

  @override
  Future<AppSettings> getSettings() async =>
      _fromRows(await _db.select(_db.settings).get());

  @override
  Future<void> updateSettings(AppSettings settings) async {
    final Map<String, String> values = _toMap(settings);
    final List<SettingsCompanion> rows = values.entries
        .map((MapEntry<String, String> e) =>
            SettingsCompanion.insert(key: e.key, value: e.value))
        .toList();
    await _db.batch((Batch batch) {
      batch.insertAll(_db.settings, rows, mode: InsertMode.insertOrReplace);
    });
  }

  AppSettings _fromRows(List<SettingRow> rows) {
    final Map<String, String> map = <String, String>{
      for (final SettingRow r in rows) r.key: r.value,
    };
    return AppSettings(
      themeMode: ThemeMode.values[_enumIndex(
        map[_kThemeMode],
        ThemeMode.values.length,
        ThemeMode.system.index,
      )],
      fontScale: _clampDouble(_double(map[_kFontScale], 1.0), 0.8, 1.6),
      readingScrollAxis: ReaderScrollAxis.values[_enumIndex(
        map[_kScrollAxis],
        ReaderScrollAxis.values.length,
        ReaderScrollAxis.vertical.index,
      )],
      readerColorMode: ReaderColorMode.values[_enumIndex(
        map[_kColorMode],
        ReaderColorMode.values.length,
        ReaderColorMode.day.index,
      )],
      highlightColors: _colors(map[_kHighlightColors]),
      defaultHighlightColor: _int(
        map[_kDefaultHighlightColor],
        AppConstants.defaultHighlightColors[0],
      ),
      keepScreenAwake: _bool(map[_kKeepAwake], false),
      autoResume: _bool(map[_kAutoResume], true),
      translationLanguage: _language(map[_kTranslationLanguage]),
    );
  }

  Map<String, String> _toMap(AppSettings s) => <String, String>{
        _kThemeMode: s.themeMode.index.toString(),
        _kFontScale: s.fontScale.toString(),
        _kScrollAxis: s.readingScrollAxis.index.toString(),
        _kColorMode: s.readerColorMode.index.toString(),
        _kHighlightColors: s.highlightColors.join(','),
        _kDefaultHighlightColor: s.defaultHighlightColor.toString(),
        _kKeepAwake: s.keepScreenAwake ? '1' : '0',
        _kAutoResume: s.autoResume ? '1' : '0',
        _kTranslationLanguage: s.translationLanguage,
      };

  String _language(String? v) => (v != null && isSupportedTranslationLanguage(v))
      ? v
      : kDefaultTranslationLanguage;

  int _int(String? v, int fallback) =>
      v == null ? fallback : (int.tryParse(v) ?? fallback);

  double _double(String? v, double fallback) =>
      v == null ? fallback : (double.tryParse(v) ?? fallback);

  double _clampDouble(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  bool _bool(String? v, bool fallback) {
    if (v == null) return fallback;
    return v == '1' || v.toLowerCase() == 'true';
  }

  int _enumIndex(String? v, int length, int fallback) {
    final int i = _int(v, fallback);
    return (i >= 0 && i < length) ? i : fallback;
  }

  List<int> _colors(String? v) {
    if (v == null || v.isEmpty) return AppConstants.defaultHighlightColors;
    final List<int> parsed = v
        .split(',')
        .map((String s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    return parsed.isEmpty ? AppConstants.defaultHighlightColors : parsed;
  }
}
