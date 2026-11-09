/// A local news/update item for the Home dashboard.
///
/// The model intentionally contains no networking or UI concerns so a live
/// Current Affairs/RSS source can replace the mock list later.
class LatestUpdate {
  const LatestUpdate({
    required this.id,
    required this.headline,
    required this.source,
    required this.category,
    required this.relativeTime,
    this.feedType = 'Latest News',
    this.excerpt = '',
    this.imageUrl,
    this.articleUrl,
    this.publishedAt,
    this.aiSummaryAvailable = false,
  });

  final String id;
  final String headline;
  final String source;
  final String category;
  final String relativeTime;
  final String feedType;
  final String excerpt;
  final String? imageUrl;
  final String? articleUrl;
  final DateTime? publishedAt;
  final bool aiSummaryAvailable;

  /// Whether this story belongs in the Opinions feed rather than Latest.
  ///
  /// The API may include inconsistent casing or whitespace in the feed type,
  /// so classification is normalized in one place before the UI filters it.
  bool get isOpinion => feedType.trim().toLowerCase() == 'opinions';
}
