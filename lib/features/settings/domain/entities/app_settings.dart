import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:lexiora/core/constants/app_constants.dart';
import 'package:lexiora/core/constants/translation_languages.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';

/// Immutable snapshot of all user-configurable preferences.
///
/// Persisted as key-value rows in the local database so everything stays
/// offline with a single source of truth.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.fontScale = 1.0,
    this.readingScrollAxis = ReaderScrollAxis.vertical,
    this.readerColorMode = ReaderColorMode.day,
    this.highlightColors = AppConstants.defaultHighlightColors,
    this.defaultHighlightColor = AppConstants.primaryHighlightColor,
    this.keepScreenAwake = false,
    this.autoResume = true,
    this.translationLanguage = kDefaultTranslationLanguage,
    this.displayName = '',
    this.dailyTopicsGoal = 5,
    this.studyRemindersEnabled = true,
    this.studyReminderMinutes = 10,
    this.breakRemindersEnabled = false,
    this.dailyWordEnabled = true,
    this.dailyWordHour = 8,
    this.dailyWordMinute = 0,
    this.notificationSoundEnabled = true,
    this.notificationVibrationEnabled = true,
    this.dailyWordHistory = const <String>[],
  });

  final ThemeMode themeMode;

  /// Global text scale factor applied across the whole app (0.8–1.6).
  final double fontScale;

  final ReaderScrollAxis readingScrollAxis;
  final ReaderColorMode readerColorMode;

  /// The palette the user can choose highlight/underline colors from.
  final List<int> highlightColors;

  /// The color pre-selected when creating a new highlight.
  final int defaultHighlightColor;

  /// Keep the screen on while reading.
  final bool keepScreenAwake;

  /// Resume from the last read page when reopening a document.
  final bool autoResume;

  /// Target language code for the reader's offline Translate feature.
  final String translationLanguage;

  /// Shown on Home's greeting and the Profile page. Empty until the user
  /// sets it (the greeting simply omits the name in that case).
  final String displayName;

  /// The denominator in Home's "Today's Goal — x / y Topics" card.
  final int dailyTopicsGoal;

  final bool studyRemindersEnabled;
  final int studyReminderMinutes;
  final bool breakRemindersEnabled;
  final bool dailyWordEnabled;
  final int dailyWordHour;
  final int dailyWordMinute;
  final bool notificationSoundEnabled;
  final bool notificationVibrationEnabled;
  final List<String> dailyWordHistory;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? fontScale,
    ReaderScrollAxis? readingScrollAxis,
    ReaderColorMode? readerColorMode,
    List<int>? highlightColors,
    int? defaultHighlightColor,
    bool? keepScreenAwake,
    bool? autoResume,
    String? translationLanguage,
    String? displayName,
    int? dailyTopicsGoal,
    bool? studyRemindersEnabled,
    int? studyReminderMinutes,
    bool? breakRemindersEnabled,
    bool? dailyWordEnabled,
    int? dailyWordHour,
    int? dailyWordMinute,
    bool? notificationSoundEnabled,
    bool? notificationVibrationEnabled,
    List<String>? dailyWordHistory,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        fontScale: fontScale ?? this.fontScale,
        readingScrollAxis: readingScrollAxis ?? this.readingScrollAxis,
        readerColorMode: readerColorMode ?? this.readerColorMode,
        highlightColors: highlightColors ?? this.highlightColors,
        defaultHighlightColor:
            defaultHighlightColor ?? this.defaultHighlightColor,
        keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
        autoResume: autoResume ?? this.autoResume,
        translationLanguage: translationLanguage ?? this.translationLanguage,
        displayName: displayName ?? this.displayName,
        dailyTopicsGoal: dailyTopicsGoal ?? this.dailyTopicsGoal,
        studyRemindersEnabled:
            studyRemindersEnabled ?? this.studyRemindersEnabled,
        studyReminderMinutes:
            studyReminderMinutes ?? this.studyReminderMinutes,
        breakRemindersEnabled:
            breakRemindersEnabled ?? this.breakRemindersEnabled,
        dailyWordEnabled: dailyWordEnabled ?? this.dailyWordEnabled,
        dailyWordHour: dailyWordHour ?? this.dailyWordHour,
        dailyWordMinute: dailyWordMinute ?? this.dailyWordMinute,
        notificationSoundEnabled:
            notificationSoundEnabled ?? this.notificationSoundEnabled,
        notificationVibrationEnabled:
            notificationVibrationEnabled ?? this.notificationVibrationEnabled,
        dailyWordHistory: dailyWordHistory ?? this.dailyWordHistory,
      );

  @override
  List<Object?> get props => [
        themeMode,
        fontScale,
        readingScrollAxis,
        readerColorMode,
        highlightColors,
        defaultHighlightColor,
        keepScreenAwake,
        autoResume,
        translationLanguage,
        displayName,
        dailyTopicsGoal,
        studyRemindersEnabled,
        studyReminderMinutes,
        breakRemindersEnabled,
        dailyWordEnabled,
        dailyWordHour,
        dailyWordMinute,
        notificationSoundEnabled,
        notificationVibrationEnabled,
        dailyWordHistory,
      ];
}
