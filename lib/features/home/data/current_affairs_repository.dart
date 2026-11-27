import 'package:lexiora/features/home/data/current_affairs_api_client.dart';
import 'package:lexiora/features/home/data/current_affairs_store.dart';
import 'package:lexiora/features/home/data/direct_news_rss_client.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_summary.dart';
import 'package:lexiora/features/home/domain/entities/latest_update.dart';

abstract class CurrentAffairsRepository {
  Future<CurrentAffairsFeed> fetchLatest();
  Future<CurrentAffairsSummary> fetchSummary(String storyId);

  /// The stories saved on this device (works offline), or null when none.
  Future<CurrentAffairsFeed?> loadCached() async => null;
}

class CurrentAffairsRepositoryImpl implements CurrentAffairsRepository {
  CurrentAffairsRepositoryImpl(
    this._client, {
    CurrentAffairsStore store = const CurrentAffairsStore(),
    DirectNewsRssClient direct = const DirectNewsRssClient(),
  })  : _store = store,
        _direct = direct;

  final CurrentAffairsApiClient _client;
  final CurrentAffairsStore _store;
  final DirectNewsRssClient _direct;

  @override
  Future<CurrentAffairsFeed?> loadCached() => _store.load();

  /// Pulls the worker feed and the direct RSS feeds in parallel, merges both
  /// into the on-device cache (newest 30 per section) and returns the result.
  /// If everything fails (offline) the cached stories are returned instead.
  @override
  Future<CurrentAffairsFeed> fetchLatest() async {
    CurrentAffairsFeed? remote;
    Object? remoteError;
    final List<LatestUpdate> direct = <LatestUpdate>[];

    await Future.wait(<Future<void>>[
      () async {
        try {
          remote = await _client.fetchLatest();
        } on Object catch (error) {
          remoteError = error;
        }
      }(),
      () async {
        try {
          direct.addAll(await _direct.fetchAll());
        } on Object {
          // Direct feeds are a bonus source; ignore failures.
        }
      }(),
    ]);

    final List<LatestUpdate> incoming = <LatestUpdate>[...direct];
    final CurrentAffairsFeed? worker = remote;
    if (worker != null) {
      incoming
        ..addAll(worker.national)
        ..addAll(worker.international)
        ..addAll(worker.opinions);
    }

    if (incoming.isEmpty) {
      final CurrentAffairsFeed? cached = await _store.load();
      if (cached != null) return cached;
      throw remoteError ?? const CurrentAffairsUnavailableException();
    }

    final CurrentAffairsFeed? merged = await _store.merge(incoming);
    if (merged != null) return merged;
    throw remoteError ?? const CurrentAffairsUnavailableException();
  }

  @override
  Future<CurrentAffairsSummary> fetchSummary(String storyId) async {
    return CurrentAffairsSummary.fromJson(await _client.fetchSummary(storyId));
  }
}
