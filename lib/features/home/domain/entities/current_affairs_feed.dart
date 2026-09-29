import 'package:lexiora/features/home/domain/entities/latest_update.dart';

class CurrentAffairsFeed {
  const CurrentAffairsFeed({
    required this.national,
    required this.international,
    required this.fetchedAt,
  });

  final List<LatestUpdate> national;
  final List<LatestUpdate> international;
  final DateTime? fetchedAt;

  List<LatestUpdate> get all => <LatestUpdate>[...national, ...international];

  LatestUpdate? get featured => all.isEmpty ? null : all.first;

  factory CurrentAffairsFeed.fromJson(Map<String, dynamic> json) {
    return CurrentAffairsFeed(
      national: _stories(json['national']),
      international: _stories(json['international']),
      fetchedAt: DateTime.tryParse(json['fetchedAt']?.toString() ?? ''),
    );
  }

  static List<LatestUpdate> _stories(Object? value) {
    if (value is! List) return const <LatestUpdate>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(_storyFromJson)
        .toList(growable: false);
  }

  static LatestUpdate _storyFromJson(Map<String, dynamic> json) {
    final DateTime? publishedAt =
        DateTime.tryParse(json['publishedAt']?.toString() ?? '')?.toLocal();
    return LatestUpdate(
      headline: json['title']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Current Affairs',
      category: json['category']?.toString() ?? 'International',
      relativeTime: _relativeTime(publishedAt),
      feedType: json['feedType']?.toString().trim().isNotEmpty == true
          ? json['feedType'].toString()
          : 'Latest News',
      excerpt: json['excerpt']?.toString() ?? '',
      imageUrl: _nullable(json['imageUrl']),
      articleUrl: _nullable(json['articleUrl']),
      publishedAt: publishedAt,
    );
  }

  static String? _nullable(Object? value) {
    final String result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }

  static String _relativeTime(DateTime? date) {
    if (date == null) return 'Recently';
    final Duration age = DateTime.now().difference(date);
    if (age.inMinutes < 1) return 'Now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    if (age.inDays == 1) return 'Yesterday';
    return '${age.inDays}d ago';
  }
}
