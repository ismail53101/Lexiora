import 'package:flutter/material.dart';

/// Brand palette for Sapiora. The app's Material 3 [ColorScheme] is built
/// from these exact values (see [AppTheme]) rather than purely algorithmic
/// seed generation, so the app matches its intended premium look precisely
/// in both themes. The reader surfaces are fixed, purpose-built colors that
/// read well for long-form study in each reading mode.
abstract final class AppColors {
  /// Primary brand seed — a deep, premium indigo-violet. Used as the seed
  /// for any tones not explicitly overridden below.
  static const Color brandSeed = Color(0xFF5B4BE6);

  // ── Dark theme ─────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B0B10);
  static const Color darkCard = Color(0xFF17171F);
  static const Color darkPrimary = Color(0xFF7C5CFF);
  static const Color darkAccent = Color(0xFFA78BFA);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A0AB);

  // ── Light theme ────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF6D4CFF);
  static const Color lightAccent = Color(0xFF8B6CFF);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);

  /// Reader page backdrops for each [ReaderColorMode].
  static const Color readerDayBackground = Color(0xFFF4F2EC); // warm paper
  static const Color readerNightBackground = Color(0xFF0E0F12); // near-black
  static const Color readerSepiaBackground = Color(0xFFEDE0C8); // sepia
}
