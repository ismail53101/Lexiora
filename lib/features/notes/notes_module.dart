import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/core/module/feature_module.dart';
import 'package:lexiora/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:lexiora/features/notes/domain/repositories/notes_repository.dart';
import 'package:lexiora/features/notes/presentation/pages/all_notes_page.dart';

/// Wires the Notes feature. Individual notes are created/edited from inside
/// the reader; this module additionally owns the standalone "all notes
/// across every document" screen (the Notes tab).
class NotesModule extends FeatureModule {
  @override
  String get id => 'notes';

  @override
  String get name => 'Notes';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<NotesRepository>(
      () => NotesRepositoryImpl(getIt<AppDatabase>()),
    );
  }

  @override
  List<RouteBase> routes(GetIt getIt) => <RouteBase>[
        GoRoute(
          path: AppRoutes.notesHome,
          builder: (_, _) => const AllNotesPage(),
        ),
      ];
}
