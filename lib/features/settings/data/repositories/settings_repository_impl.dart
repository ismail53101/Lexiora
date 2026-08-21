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
  static const String _kDisplayName = 'displayName';
  static const String _kDailyTopicsGoal = 'dailyTopicsGoal';
  static const String _kStudyRemindersEnabled = 'studyRemindersEnabled';
  static const String _kStudyReminderMinutes = 'studyReminderMinutes';
  static const String _kBreakRemindersEnabled = 'breakRemindersEnabled';
  static const String _kDailyWordEnabled = 'dailyWordEnabled';
  static const String _kDailyWordHour = 'dailyWordHour';
  static const String _kDailyWordMinute = 'dailyWordMinute';
  static const String _kNotificationSoundEnabled = 'notificationSoundEnabled';
  static const String _kNotificationVibrationEnabled =
      'notificationVibrationEnabled';
  static const String _kDailyWordHistory = 'dailyWordHistory';
  static const String _kInitialPermissionFlowCompleted =
      'initialPermissionFlowCompleted';

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
      displayName: map[_kDisplayName] ?? '',
      dailyTopicsGoal: _int(map[_kDailyTopicsGoal], 5).clamp(1, 99),
      studyRemindersEnabled: _bool(map[_kStudyRemindersEnabled], true),
      studyReminderMinutes: _validReminderMinutes(
        _int(map[_kStudyReminderMinutes], 10),
      ),
      breakRemindersEnabled: _bool(map[_kBreakRemindersEnabled], false),
      dailyWordEnabled: _bool(map[_kDailyWordEnabled], true),
      dailyWordHour: _int(map[_kDailyWordHour], 8).clamp(0, 23),
      dailyWordMinute: _int(map[_kDailyWordMinute], 0).clamp(0, 59),
      notificationSoundEnabled:
          _bool(map[_kNotificationSoundEnabled], true),
      notificationVibrationEnabled:
          _bool(map[_kNotificationVibrationEnabled], true),
      dailyWordHistory: _history(map[_kDailyWordHistory]),
      initialPermissionFlowCompleted:
          _bool(map[_kInitialPermissionFlowCompleted], false),
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
        _kDisplayName: s.displayName,
        _kDailyTopicsGoal: s.dailyTopicsGoal.toString(),
        _kStudyRemindersEnabled: s.studyRemindersEnabled ? '1' : '0',
        _kStudyReminderMinutes: _validReminderMinutes(
          s.studyReminderMinutes,
        ).toString(),
        _kBreakRemindersEnabled: s.breakRemindersEnabled ? '1' : '0',
        _kDailyWordEnabled: s.dailyWordEnabled ? '1' : '0',
        _kDailyWordHour: s.dailyWordHour.clamp(0, 23).toString(),
        _kDailyWordMinute: s.dailyWordMinute.clamp(0, 59).toString(),
        _kNotificationSoundEnabled: s.notificationSoundEnabled ? '1' : '0',
        _kNotificationVibrationEnabled:
            s.notificationVibrationEnabled ? '1' : '0',
        _kDailyWordHistory: s.dailyWordHistory.join('\\n'),
        _kInitialPermissionFlowCompleted:
            s.initialPermissionFlowCompleted ? '1' : '0',
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

  int _validReminderMinutes(int value) =>
      const <int>[5, 10, 15, 30].contains(value) ? value : 10;

  List<String> _history(String? value) => value == null || value.isEmpty
      ? const <String>[]
      : value
          .split('\\n')
          .where((String e) => e.trim().isNotEmpty)
          .toList(growable: false);

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
