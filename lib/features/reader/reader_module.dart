import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/core/reader_engine/pdf_engine.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/reader/data/pdfrx_engine.dart';
import 'package:lexiora/features/reader/presentation/pages/reader_page.dart';

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
          builder: (_, GoRouterState state) =>
              ReaderPage(documentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoutes.driveReader,
          name: AppRoutes.driveReaderName,
          builder: (_, GoRouterState state) {
            final LibraryDocument document = state.extra! as LibraryDocument;
            return ReaderPage(
              documentId: document.id,
              temporaryDocument: document,
            );
          },
        ),
      ];
}
