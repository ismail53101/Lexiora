import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/features/home/data/current_affairs_repository.dart';
import 'package:lexiora/features/home/data/current_affairs_store.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';
import 'package:lexiora/features/home/domain/entities/latest_update.dart';

final currentAffairsRepositoryProvider = Provider<CurrentAffairsRepository>(
  (ref) => sl<CurrentAffairsRepository>(),
);

/// Stale-while-revalidate feed:
///  1. emits the stories saved on the device immediately (no loading spinner,
///     works offline), then
///  2. fetches fresh stories, merges them into the saved ones and emits again.
/// If the refresh fails the saved stories simply stay on screen.
final currentAffairsProvider = StreamProvider<CurrentAffairsFeed?>((ref) async* {
  final CurrentAffairsRepository repository =
      ref.read(currentAffairsRepositoryProvider);

  CurrentAffairsFeed? shown;
  try {
    shown = await repository.loadCached();
  } on Object {
    shown = null;
  }
  if (shown != null) yield shown;

  try {
    yield await repository.fetchLatest();
  } on Object {
    // Offline or endpoint down: keep what is already shown. With nothing saved
    // the Home card falls back to its local sample content.
    if (shown == null) yield null;
  }
});

final currentAffairsStoreProvider = Provider<CurrentAffairsStore>(
  (ref) => const CurrentAffairsStore(),
);

/// Articles the user bookmarked to study later. Stored on the device.
class FavoriteStoriesNotifier extends AsyncNotifier<List<LatestUpdate>> {
  @override
  Future<List<LatestUpdate>> build() {
    return ref.read(currentAffairsStoreProvider).loadFavorites();
  }

  Future<void> toggle(LatestUpdate story) async {
    final List<LatestUpdate> next =
        await ref.read(currentAffairsStoreProvider).toggleFavorite(story);
    state = AsyncData<List<LatestUpdate>>(next);
  }
}

final favoriteStoriesProvider =
    AsyncNotifierProvider<FavoriteStoriesNotifier, List<LatestUpdate>>(
  FavoriteStoriesNotifier.new,
);
