import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/features/library/domain/entities/category.dart';
import 'package:lexiora/features/library/domain/usecases/library_usecases.dart';
import 'package:lexiora/features/library/domain/repositories/library_repository.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/modules/admin/data/services/admin_content_service.dart';
import 'package:lexiora/modules/admin/data/services/admin_export_service.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_link.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_note.dart';

final Provider<AdminContentService> adminContentServiceProvider =
    Provider<AdminContentService>((Ref ref) => sl<AdminContentService>());

/// The id of the "Admin" library category, creating it on first use. PDFs
/// added via the Admin Panel are ordinary library documents filed under this
/// category — no separate PDF storage system needed.
final FutureProvider<String> adminCategoryIdProvider =
    FutureProvider<String>((Ref ref) async {
  final LibraryRepository repo = ref.watch(libraryRepositoryProvider);
  final List<Category> categories = await repo.watchCategories().first;
  final Category? existing = categories
      .cast<Category?>()
      .firstWhere((Category? c) => c?.name == 'Admin', orElse: () => null);
  if (existing != null) return existing.id;

  await ref.read(createCategoryProvider).call(
        (name: 'Admin', colorValue: 0xFF5B4BE6),
      );
  final List<Category> refreshed = await repo.watchCategories().first;
  return refreshed.firstWhere((Category c) => c.name == 'Admin').id;
});

final FutureProvider<List<AdminLink>> adminLinksProvider =
    FutureProvider<List<AdminLink>>(
        (Ref ref) => ref.watch(adminContentServiceProvider).loadLinks());

final FutureProvider<List<AdminNote>> adminNotesProvider =
    FutureProvider<List<AdminNote>>(
        (Ref ref) => ref.watch(adminContentServiceProvider).loadNotes());

final Provider<AdminExportService> adminExportServiceProvider =
    Provider<AdminExportService>(
  (Ref ref) => AdminExportService(
    ref.watch(adminContentServiceProvider),
    ref.watch(libraryRepositoryProvider),
  ),
);
