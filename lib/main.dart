import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/app.dart';
import 'package:lexiora/app/di/injector_config.dart';
import 'package:lexiora/app/router/app_router.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:pdfrx/pdfrx.dart';

/// Sapiora entry point.
///
/// Runs inside a guarded zone with a friendly [ErrorWidget.builder] so a build
/// failure is never an unexplained blank/grey screen, and all framework and
/// uncaught errors are logged. Initializes the pdfrx engine, composes all
/// modules via dependency injection, builds the router, and runs the app.
Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      ErrorWidget.builder = (FlutterErrorDetails details) {
        AppLogger.e(
          'Widget build error',
          error: details.exception,
          stackTrace: details.stack,
        );
        return _FatalErrorBox(details: details);
      };
      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.e(
          'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };

      // Required because we open PdfDocuments via the engine API (reading page
      // counts at import time) before any pdfrx widget is built.
      await pdfrxFlutterInitialize();
      await configureDependencies();
      final GoRouter router = createAppRouter();

      runApp(ProviderScope(child: SapioraApp(router: router)));
    },
    (Object error, StackTrace stack) {
      AppLogger.e('Uncaught zone error', error: error, stackTrace: stack);
    },
  );
}

/// Self-contained fallback rendered by [ErrorWidget.builder]. It shows the real
/// exception and stack trace (scrollable + selectable) so failures can be
/// captured and diagnosed on-device, and assumes no inherited widgets are
/// present. This is a diagnostic surface, not a normal user-facing screen.
class _FatalErrorBox extends StatelessWidget {
  const _FatalErrorBox({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final String message = details.exceptionAsString();
    final String stack = details.stack?.toString() ?? '(no stack trace)';
    final String shownStack =
        stack.length > 6000 ? '${stack.substring(0, 6000)}\n…(truncated)' : stack;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF121316),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sapiora — rendering error',
                  style: TextStyle(
                    color: Color(0xFFFF6E6E),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please screenshot this screen (scroll for the full trace) so '
                  'the exact cause can be fixed.',
                  style: TextStyle(color: Color(0xFFB0B3BA), fontSize: 13),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  shownStack,
                  style: const TextStyle(
                    color: Color(0xFF9AA0A6),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
