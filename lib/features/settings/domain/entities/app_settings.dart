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
      ];
}
