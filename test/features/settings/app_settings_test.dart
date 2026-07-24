import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/features/settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('has sensible offline-first defaults', () {
      const AppSettings s = AppSettings();
      expect(s.themeMode, ThemeMode.system);
      expect(s.fontScale, 1.0);
      expect(s.readingScrollAxis, ReaderScrollAxis.vertical);
      expect(s.readerColorMode, ReaderColorMode.day);
      expect(s.highlightColors, isNotEmpty);
    });

    test('copyWith updates only the targeted fields', () {
      const AppSettings s = AppSettings();
      final AppSettings updated =
          s.copyWith(themeMode: ThemeMode.dark, fontScale: 1.2);
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.fontScale, 1.2);
      // Untouched fields are preserved.
      expect(updated.readerColorMode, s.readerColorMode);
      expect(updated.readingScrollAxis, s.readingScrollAxis);
    });
  });
}
