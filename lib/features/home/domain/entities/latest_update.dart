/// A local news/update item for the Home dashboard.
///
/// The model intentionally contains no networking or UI concerns so a live
/// Current Affairs/RSS source can replace the mock list later.
class LatestUpdate {
  const LatestUpdate({
    required this.headline,
    required this.source,
    required this.category,
    required this.relativeTime,
    this.excerpt = '',
    this.imageUrl,
    this.articleUrl,
    this.publishedAt,
  });

  final String headline;
  final String source;
  final String category;
  final String relativeTime;
  final String excerpt;
  final String? imageUrl;
  final String? articleUrl;
  final DateTime? publishedAt;
}
