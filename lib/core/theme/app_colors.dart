import 'package:flutter/material.dart';

/// Brand palette for Lexiora. The app's Material 3 [ColorScheme] is derived
/// from [brandSeed]; the reader surfaces are fixed, purpose-built colors that
/// read well for long-form study in each reading mode.
abstract final class AppColors {
  /// Primary brand seed — a deep, premium indigo-violet.
  static const Color brandSeed = Color(0xFF5B4BE6);

  /// Reader page backdrops for each [ReaderColorMode].
  static const Color readerDayBackground = Color(0xFFF4F2EC); // warm paper
  static const Color readerNightBackground = Color(0xFF0E0F12); // near-black
  static const Color readerSepiaBackground = Color(0xFFEDE0C8); // sepia
}
