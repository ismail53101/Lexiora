import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/features/home/data/current_affairs_repository.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';

final currentAffairsRepositoryProvider = Provider<CurrentAffairsRepository>(
  (ref) => sl<CurrentAffairsRepository>(),
);

CurrentAffairsFeed? _lastGoodFeed;

final currentAffairsProvider = FutureProvider<CurrentAffairsFeed?>((ref) async {
  try {
    final CurrentAffairsFeed feed =
        await ref.read(currentAffairsRepositoryProvider).fetchLatest();
    _lastGoodFeed = feed;
    return feed;
  } on Object {
    // A failed background refresh keeps the last good stories on screen.
    // With no previous result the Home card falls back to its local mock
    // content (endpoint unavailable or not configured for this build).
    return _lastGoodFeed;
  }
});
