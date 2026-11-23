import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/pronunciation_service.dart';
import 'package:lexiora/modules/flashcards/data/fc_export_service.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_stats_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';

final Provider<FcRepository> fcRepositoryProvider =
    Provider<FcRepository>((Ref ref) => sl<FcRepository>());

final Provider<FcExportService> fcExportServiceProvider =
    Provider<FcExportService>((Ref ref) => const FcExportService());

final Provider<PronunciationService> fcPronunciationProvider =
    Provider<PronunciationService>((Ref ref) => TtsPronunciationService());

/// Emits whenever flashcards data changes (used to reload paginated lists).
final StreamProvider<int> fcRevisionProvider = StreamProvider<int>(
    (Ref ref) => ref.watch(fcRepositoryProvider).watchRevision());

final StreamProvider<FcDashboard> fcDashboardProvider = StreamProvider<FcDashboard>(
    (Ref ref) => ref.watch(fcRepositoryProvider).watchDashboard());

/// Active (non-archived) decks with live counts.
final StreamProvider<List<FcDeckSummary>> fcDecksProvider =
    StreamProvider<List<FcDeckSummary>>(
        (Ref ref) => ref.watch(fcRepositoryProvider).watchDecks());

final StreamProvider<List<FcDeckSummary>> fcAllDecksProvider =
    StreamProvider<List<FcDeckSummary>>((Ref ref) =>
        ref.watch(fcRepositoryProvider).watchDecks(includeArchived: true));

final fcDeckProvider = StreamProvider.family<FcDeckSummary?, String>(
    (Ref ref, String id) => ref.watch(fcRepositoryProvider).watchDeck(id));

final StreamProvider<FcStats> fcStatsProvider = StreamProvider<FcStats>(
    (Ref ref) => ref.watch(fcRepositoryProvider).watchStats());

final StreamProvider<List<FcActivity>> fcActivityProvider =
    StreamProvider<List<FcActivity>>(
        (Ref ref) => ref.watch(fcRepositoryProvider).watchRecentActivity());

/// Lower-cased subject name → colour from the Study Planner.
final StreamProvider<Map<String, int>> fcSubjectColorsProvider =
    StreamProvider<Map<String, int>>(
        (Ref ref) => ref.watch(fcRepositoryProvider).watchSubjectColors());

final FutureProvider<List<String>> fcSubjectSuggestionsProvider =
    FutureProvider.autoDispose<List<String>>(
        (Ref ref) => ref.watch(fcRepositoryProvider).subjectSuggestions());

final FutureProvider<List<String>> fcTagSuggestionsProvider =
    FutureProvider.autoDispose<List<String>>(
        (Ref ref) => ref.watch(fcRepositoryProvider).tagSuggestions());
