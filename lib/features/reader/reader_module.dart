import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/reader_engine/pdf_engine.dart';
import 'package:lexiora/core/services/ad_return_navigation_scope.dart';
import 'package:lexiora/core/services/pdf_import_service.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/reader/data/pdfrx_engine.dart';
import 'package:lexiora/features/reader/presentation/pages/reader_page.dart';
import 'package:lexiora/features/reader/presentation/pages/word_editor_page.dart';
import 'package:lexiora/core/services/pdf_discovery_service.dart';

/// Wires the Reader feature: registers the [PdfEngine] binding (pdfrx) and the
/// `/reader/:id` route. Swapping the engine is a one-line change here.
class ReaderModule extends FeatureModule {
  @override
  String get id => 'reader';

  @override
  String get name => 'Reader';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<PdfEngine>(() => const PdfrxEngine());
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.readerPattern,
          name: AppRoutes.readerName,
          builder: (_, GoRouterState state) {
            final bool externalLaunch = state.extra == true;
            final Widget reader = ReaderPage(
              documentId: state.pathParameters['id']!,
              externalLaunch: externalLaunch,
            );
            if (externalLaunch) {
              return PopScope<Object?>(
                canPop: false,
                onPopInvokedWithResult: (bool didPop, Object? result) {
                  if (!didPop) {
                    unawaited(PdfImportService.finishExternalPdf());
                  }
                },
                child: reader,
              );
            }
            return AdReturnNavigationScope(
              manager: getIt<RewardedAdManager>(),
              child: reader,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.wordEditor,
          builder: (_, state) => WordEditorPage(file: state.extra! as DeviceFile, externalLaunch: true),
        ),
        GoRoute(
          path: AppRoutes.wordEditorPattern,
          builder: (_, state) => WordEditorPage(documentId: state.pathParameters['id']!, externalLaunch: state.extra == true),
        ),
        GoRoute(
          path: AppRoutes.driveReader,
          name: AppRoutes.driveReaderName,
          builder: (_, GoRouterState state) {
            final LibraryDocument document = state.extra! as LibraryDocument;
            return AdReturnNavigationScope(
              manager: getIt<RewardedAdManager>(),
              child: ReaderPage(
                documentId: document.id,
                temporaryDocument: document,
              ),
            );
          },
        ),
      ];
}
