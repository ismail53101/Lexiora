import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/features/home/data/current_affairs_repository.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';

final currentAffairsRepositoryProvider = Provider<CurrentAffairsRepository>(
  (ref) => sl<CurrentAffairsRepository>(),
);

final currentAffairsProvider = FutureProvider<CurrentAffairsFeed?>((ref) async {
  try {
    return await ref.read(currentAffairsRepositoryProvider).fetchLatest();
  } on Object {
    // The Home card remains useful with its local mock content when the
    // optional endpoint is unavailable or not configured for this build.
    return null;
  }
});
