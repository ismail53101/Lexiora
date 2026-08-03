import 'package:flutter/material.dart';
import 'package:lexiora/core/theme/app_colors.dart';

/// Central Material 3 theme factory for Lexiora.
///
/// Light and dark schemes are both generated from a single [AppColors.brandSeed]
/// so the brand stays consistent. Text scaling is applied separately (via
/// `MediaQuery.textScaler` in the app shell) so the user's font-size setting
/// affects every widget uniformly, not just [TextTheme] entries.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme generated = ColorScheme.fromSeed(
      seedColor: AppColors.brandSeed,
      brightness: brightness,
    );

    // Layer the brief's exact premium palette onto the algorithmically
    // generated scheme — every other tone (error, outline, elevation
    // levels, ...) still comes from Material 3's own accessible generation,
    // only the specific values the design calls out are pinned.
    final ColorScheme scheme = generated.copyWith(
      surface: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      onSurface: isDark ? AppColors.darkText : AppColors.lightText,
      onSurfaceVariant:
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      surfaceContainerHighest: isDark ? AppColors.darkCard : AppColors.lightCard,
      surfaceContainerHigh: isDark ? AppColors.darkCard : AppColors.lightCard,
      surfaceContainer: isDark ? AppColors.darkCard : AppColors.lightCard,
      primary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      onPrimary: Colors.white,
      tertiary: isDark ? AppColors.darkAccent : AppColors.lightAccent,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
