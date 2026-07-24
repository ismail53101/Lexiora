import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/app.dart';
import 'package:lexiora/app/di/injector_config.dart';
import 'package:lexiora/app/router/app_router.dart';
import 'package:pdfrx/pdfrx.dart';

/// Lexiora entry point.
///
/// Initializes the pdfrx engine, wires up dependency injection (which composes
/// all modules), builds the router, and runs the app inside a Riverpod
/// [ProviderScope]. Everything is local/offline — there is no network setup.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required because we open PdfDocuments via the engine API (e.g. reading page
  // counts at import time) before any pdfrx widget is built.
  await pdfrxFlutterInitialize();

  await configureDependencies();
  final GoRouter router = createAppRouter();

  runApp(
    ProviderScope(
      child: LexioraApp(router: router),
    ),
  );
}
