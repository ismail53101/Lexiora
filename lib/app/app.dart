import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/core/constants/app_constants.dart';
import 'package:lexiora/core/theme/app_theme.dart';
import 'package:lexiora/features/settings/domain/entities/app_settings.dart';
import 'package:lexiora/features/settings/presentation/providers/settings_providers.dart';

/// Root widget. Binds the reactive [settingsProvider] to the Material 3 theme
/// (light/dark) and the global text scale, and drives navigation from the
/// module-assembled [GoRouter].
class LexioraApp extends ConsumerWidget {
  const LexioraApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSettings> settings = ref.watch(settingsProvider);
    final ThemeMode themeMode = settings.maybeWhen(
      data: (AppSettings s) => s.themeMode,
      orElse: () => ThemeMode.system,
    );
    final double fontScale = settings.maybeWhen(
      data: (AppSettings s) => s.fontScale,
      orElse: () => 1.0,
    );

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
