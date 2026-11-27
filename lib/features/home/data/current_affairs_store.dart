import 'dart:convert';
import 'dart:io';

import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';
import 'package:lexiora/features/home/domain/entities/latest_update.dart';
import 'package:path_provider/path_provider.dart';

/// On-device storage for Current Affairs.
///
/// * A rolling cache keeps the newest [maxPerBucket] stories of every section
///   (National / International x Latest / Opinions). When newer stories arrive
///   the oldest ones fall out, so the screen opens instantly and also works
///   offline.
/// * Favourites are kept until the user removes them.
class CurrentAffairsStore {
  const CurrentAffairsStore();

  static const int maxPerBucket = 30;
  static const String _cacheFile = 'current_affairs_cache_v1.json';
  static const String _favoritesFile = 'current_affairs_favorites_v1.json';

  // ---- identity ----------------------------------------------------------

  /// Stable identity so the same article is never stored twice.
  static String identityOf(LatestUpdate story) {
    final String url = (story.articleUrl ?? '').trim();
    if (url.isNotEmpty) {
      final Uri? uri = Uri.tryParse(url);
      if (uri != null && uri.host.isNotEmpty) {
        final String path = uri.path.endsWith('/') && uri.path.length > 1
            ? uri.path.substring(0, uri.path.length - 1)
            : uri.path;
        return '${uri.host.toLowerCase()}$path';
      }
      return url.toLowerCase();
    }
    if (story.id.trim().isNotEmpty) return story.id.trim();
    return story.headline.trim().toLowerCase();
  }

  static String _section(LatestUpdate story) =>
      story.category.toLowerCase().contains('inter')
          ? 'International'
          : 'National';

  static String _bucketKey(LatestUpdate story) =>
      '${_section(story)}|${story.isOpinion ? 'Opinions' : 'Latest'}';

  static int _time(LatestUpdate story) =>
      story.publishedAt?.millisecondsSinceEpoch ?? 0;

  // ---- json --------------------------------------------------------------

  static Map<String, dynamic> storyToJson(LatestUpdate story) =>
      <String, dynamic>{
        'id': story.id,
        'title': story.headline,
        'source': story.source,
        'category': story.category,
        'feedType': story.feedType,
        'excerpt': story.excerpt,
        'imageUrl': story.imageUrl,
        'articleUrl': story.articleUrl,
        'publishedAt': story.publishedAt?.toUtc().toIso8601String(),
        'aiSummaryAvailable': story.aiSummaryAvailable,
      };

  static List<LatestUpdate> _storiesFromJson(Object? value) {
    if (value is! List) return <LatestUpdate>[];
    // Reuse the feed parser so cached stories look exactly like live ones
    // (including a freshly computed "x min ago" label).
    return CurrentAffairsFeed.fromJson(<String, dynamic>{'national': value})
        .national
        .toList();
  }

  Future<File> _file(String name) async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  Future<Object?> _readJson(String name) async {
    try {
      final File file = await _file(name);
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString());
    } on Object {
      return null;
    }
  }

  Future<void> _writeJson(String name, Object value) async {
    try {
      final File file = await _file(name);
      final File temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(value), flush: true);
      await temp.rename(file.path);
    } on Object {
      // Cache is best effort: a failed write must never break the screen.
    }
  }

  // ---- cache -------------------------------------------------------------

  Future<Map<String, List<LatestUpdate>>> _readBuckets() async {
    final Object? raw = await _readJson(_cacheFile);
    final Map<String, List<LatestUpdate>> buckets =
        <String, List<LatestUpdate>>{};
    if (raw is Map<String, dynamic>) {
      final Object? stored = raw['buckets'];
      if (stored is Map<String, dynamic>) {
        stored.forEach((String key, Object? value) {
          buckets[key] = _storiesFromJson(value);
        });
      }
    }
    return buckets;
  }

  CurrentAffairsFeed? _feedFrom(Map<String, List<LatestUpdate>> buckets) {
    List<LatestUpdate> merged(String a, String b) {
      final List<LatestUpdate> list = <LatestUpdate>[
        ...?buckets[a],
        ...?buckets[b],
      ]..sort((LatestUpdate x, LatestUpdate y) => _time(y).compareTo(_time(x)));
      return list;
    }

    final List<LatestUpdate> national =
        merged('National|Latest', 'National|Opinions');
    final List<LatestUpdate> international =
        merged('International|Latest', 'International|Opinions');
    if (national.isEmpty && international.isEmpty) return null;
    return CurrentAffairsFeed(
      national: national,
      international: international,
      opinions: <LatestUpdate>[
        ...national.where((LatestUpdate s) => s.isOpinion),
        ...international.where((LatestUpdate s) => s.isOpinion),
      ],
      fetchedAt: DateTime.now(),
    );
  }

  /// The last saved stories, or null when nothing has been saved yet.
  Future<CurrentAffairsFeed?> load() async => _feedFrom(await _readBuckets());

  /// Adds [incoming] stories to the cache (newest first, de-duplicated, capped
  /// at [maxPerBucket] per section) and returns the resulting feed.
  Future<CurrentAffairsFeed?> merge(Iterable<LatestUpdate> incoming) async {
    final Map<String, List<LatestUpdate>> buckets = await _readBuckets();
    for (final LatestUpdate story in incoming) {
      if (story.headline.trim().isEmpty) continue;
      final List<LatestUpdate> list =
          buckets.putIfAbsent(_bucketKey(story), () => <LatestUpdate>[]);
      final String id = identityOf(story);

      // A refresh can return the same article without an image (for example
      // when an RSS/GNews source temporarily omits its media field). Never
      // let that overwrite an image that was already cached for the article.
      final int existingIndex =
          list.indexWhere((LatestUpdate e) => identityOf(e) == id);
      if (existingIndex >= 0) {
        final LatestUpdate existing = list[existingIndex];
        if (story.imageUrl == null && existing.imageUrl != null) {
          final LatestUpdate preserved = LatestUpdate(
            id: story.id.isNotEmpty ? story.id : existing.id,
            headline: story.headline,
            source: story.source,
            category: story.category,
            relativeTime: story.relativeTime,
            feedType: story.feedType,
            excerpt: story.excerpt,
            imageUrl: existing.imageUrl,
            articleUrl: story.articleUrl ?? existing.articleUrl,
            publishedAt: story.publishedAt ?? existing.publishedAt,
            aiSummaryAvailable:
                story.aiSummaryAvailable || existing.aiSummaryAvailable,
          );
          list.removeAt(existingIndex);
          list.add(preserved);
          continue;
        }
        list.removeAt(existingIndex);
      }
      list.add(story);
    }
    for (final List<LatestUpdate> list in buckets.values) {
      list.sort((LatestUpdate x, LatestUpdate y) => _time(y).compareTo(_time(x)));
      if (list.length > maxPerBucket) {
        list.removeRange(maxPerBucket, list.length);
      }
    }
    await _writeJson(_cacheFile, <String, dynamic>{
      'buckets': buckets.map(
        (String key, List<LatestUpdate> value) => MapEntry<String, dynamic>(
          key,
          value.map(storyToJson).toList(),
        ),
      ),
    });
    return _feedFrom(await _readBuckets());
  }

  // ---- favourites --------------------------------------------------------

  Future<List<LatestUpdate>> loadFavorites() async {
    final List<LatestUpdate> favorites =
        _storiesFromJson(await _readJson(_favoritesFile));
    if (favorites.isEmpty) return favorites;

    // Backfill an image from the article cache if an older favorite was saved
    // while its live feed temporarily had no image URL.
    final Map<String, List<LatestUpdate>> buckets = await _readBuckets();
    final Map<String, LatestUpdate> cachedById = <String, LatestUpdate>{
      for (final List<LatestUpdate> list in buckets.values)
        for (final LatestUpdate cached in list) identityOf(cached): cached,
    };

    return favorites.map((LatestUpdate favorite) {
      if (favorite.imageUrl != null) return favorite;
      final LatestUpdate? cached = cachedById[identityOf(favorite)];
      if (cached?.imageUrl == null) return favorite;
      return LatestUpdate(
        id: favorite.id,
        headline: favorite.headline,
        source: favorite.source,
        category: favorite.category,
        relativeTime: favorite.relativeTime,
        feedType: favorite.feedType,
        excerpt: favorite.excerpt,
        imageUrl: cached!.imageUrl,
        articleUrl: favorite.articleUrl ?? cached.articleUrl,
        publishedAt: favorite.publishedAt ?? cached.publishedAt,
        aiSummaryAvailable:
            favorite.aiSummaryAvailable || cached.aiSummaryAvailable,
      );
    }).toList(growable: false);
  }

  /// Saves or removes [story] and returns the updated favourites list.
  Future<List<LatestUpdate>> toggleFavorite(LatestUpdate story) async {
    final List<LatestUpdate> favorites = await loadFavorites();
    final String id = identityOf(story);
    final int before = favorites.length;
    favorites.removeWhere((LatestUpdate e) => identityOf(e) == id);
    if (favorites.length == before) {
      LatestUpdate toSave = story;

      // If the live item has no image, prefer the cached copy so a newly
      // saved favorite still has the same thumbnail as the news list.
      if (toSave.imageUrl == null) {
        final Map<String, List<LatestUpdate>> buckets = await _readBuckets();
        for (final List<LatestUpdate> list in buckets.values) {
          for (final LatestUpdate cached in list) {
            if (identityOf(cached) == id && cached.imageUrl != null) {
              toSave = LatestUpdate(
                id: toSave.id.isNotEmpty ? toSave.id : cached.id,
                headline: toSave.headline,
                source: toSave.source,
                category: toSave.category,
                relativeTime: toSave.relativeTime,
                feedType: toSave.feedType,
                excerpt: toSave.excerpt,
                imageUrl: cached.imageUrl,
                articleUrl: toSave.articleUrl ?? cached.articleUrl,
                publishedAt: toSave.publishedAt ?? cached.publishedAt,
                aiSummaryAvailable:
                    toSave.aiSummaryAvailable || cached.aiSummaryAvailable,
              );
              break;
            }
          }
        }
      }
      favorites.insert(0, toSave);
    }
    await _writeJson(
      _favoritesFile,
      favorites.map(storyToJson).toList(),
    );
    return favorites;
  }
}
