import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/features/annotations/domain/entities/highlight.dart';
import 'package:lexiora/features/annotations/domain/repositories/annotations_repository.dart';
import 'package:lexiora/features/annotations/domain/usecases/annotations_usecases.dart';

final Provider<AnnotationsRepository> annotationsRepositoryProvider =
    Provider<AnnotationsRepository>((Ref ref) => sl<AnnotationsRepository>());

/// All highlights for a document (used by the annotations list panel).
final highlightsForDocumentProvider =
    StreamProvider.family<List<Highlight>, String>(
  (Ref ref, String documentId) =>
      WatchHighlights(ref.watch(annotationsRepositoryProvider)).call(documentId),
);

/// Highlights for a single page (used to paint reader overlays).
final highlightsForPageProvider =
    StreamProvider.family<List<Highlight>, PageRef>(
  (Ref ref, PageRef page) =>
      WatchHighlightsForPage(ref.watch(annotationsRepositoryProvider)).call(page),
);

final Provider<AddHighlightFromSelection> addHighlightProvider =
    Provider<AddHighlightFromSelection>(
  (Ref ref) => AddHighlightFromSelection(ref.watch(annotationsRepositoryProvider)),
);

final Provider<ChangeHighlightColor> changeHighlightColorProvider =
    Provider<ChangeHighlightColor>(
  (Ref ref) => ChangeHighlightColor(ref.watch(annotationsRepositoryProvider)),
);

final Provider<ChangeHighlightStyle> changeHighlightStyleProvider =
    Provider<ChangeHighlightStyle>(
  (Ref ref) => ChangeHighlightStyle(ref.watch(annotationsRepositoryProvider)),
);

final Provider<DeleteHighlight> deleteHighlightProvider =
    Provider<DeleteHighlight>(
  (Ref ref) => DeleteHighlight(ref.watch(annotationsRepositoryProvider)),
);
