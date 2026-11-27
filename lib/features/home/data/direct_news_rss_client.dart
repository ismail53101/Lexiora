import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:lexiora/features/home/domain/entities/latest_update.dart';

/// Reads a few public news/opinion RSS feeds straight from the phone.
///
/// The Cloudflare worker is the main source, but news sites often block
/// datacentre addresses (which is why Dawn opinions could stay empty). A phone
/// on a normal connection is rarely blocked, so these feeds are fetched as a
/// second source and merged into the same local cache.
class DirectNewsRssClient {
  const DirectNewsRssClient();

  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36';

  static const List<_Feed> _feeds = <_Feed>[
    _Feed('Dawn', 'National', 'Opinions', 'https://www.dawn.com/feeds/opinion'),
    _Feed('Express Tribune', 'National', 'Opinions',
        'https://tribune.com.pk/feed/opinion'),
    _Feed('Dawn', 'National', 'Latest News',
        'https://www.dawn.com/feeds/latest-news'),
    _Feed('The Guardian', 'International', 'Opinions',
        'https://www.theguardian.com/commentisfree/rss'),
    _Feed('The New York Times', 'International', 'Opinions',
        'https://rss.nytimes.com/services/xml/rss/nyt/Opinion.xml'),
  ];

  Future<List<LatestUpdate>> fetchAll() async {
    final List<List<LatestUpdate>> results =
        await Future.wait(_feeds.map(_fetch));
    return results.expand((List<LatestUpdate> list) => list).toList();
  }

  Future<List<LatestUpdate>> _fetch(_Feed feed) async {
    try {
      final http.Response response = await http.get(
        Uri.parse(feed.url),
        headers: const <String, String>{
          'User-Agent': _userAgent,
          'Accept': 'application/rss+xml, application/xml, text/xml, */*',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return const <LatestUpdate>[];
      final String xml = utf8.decode(response.bodyBytes, allowMalformed: true);
      return _parse(xml, feed);
    } on Object {
      return const <LatestUpdate>[];
    }
  }

  List<LatestUpdate> _parse(String xml, _Feed feed) {
    final RegExp itemPattern =
        RegExp(r'<item\b[\s\S]*?</item>', caseSensitive: false);
    final List<LatestUpdate> stories = <LatestUpdate>[];
    for (final RegExpMatch match in itemPattern.allMatches(xml)) {
      if (stories.length >= 15) break;
      final String item = match.group(0)!;
      final String title = _text(_tag(item, 'title'));
      String link = _text(_tag(item, 'link'));
      if (link.isEmpty) link = _text(_tag(item, 'guid'));
      if (title.isEmpty || !link.startsWith('http')) continue;

      final DateTime? published = _parseDate(_text(_tag(item, 'pubDate')));
      final String description = _text(
        _tag(item, 'description') ?? _tag(item, 'content:encoded'),
      );
      final String author = _text(_tag(item, 'dc:creator'));
      String excerpt = description;
      if (excerpt.length > 220) excerpt = '${excerpt.substring(0, 217)}...';
      if (excerpt.isEmpty && author.isNotEmpty) excerpt = 'By $author';

      stories.add(LatestUpdate(
        id: 'rss-${sha1.convert(utf8.encode(link)).toString().substring(0, 16)}',
        headline: title,
        source: feed.source,
        category: feed.category,
        relativeTime: _relative(published),
        feedType: feed.feedType,
        excerpt: excerpt,
        imageUrl: _image(item),
        articleUrl: link,
        publishedAt: published?.toLocal(),
      ));
    }
    return stories;
  }

  // ---- tiny RSS helpers ----------------------------------------------------

  String? _tag(String xml, String name) {
    final RegExpMatch? m = RegExp(
      '<$name(?:\\s[^>]*)?>([\\s\\S]*?)</$name>',
      caseSensitive: false,
    ).firstMatch(xml);
    return m?.group(1);
  }

  String _text(String? raw) {
    if (raw == null) return '';
    String value = raw.trim();
    final RegExpMatch? cdata =
        RegExp(r'^<!\[CDATA\[([\s\S]*?)\]\]>$').firstMatch(value);
    if (cdata != null) value = cdata.group(1)!;
    value = value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&#8217;', '\u2019')
        .replaceAll('&#8216;', '\u2018')
        .replaceAll('&#8220;', '\u201C')
        .replaceAll('&#8221;', '\u201D')
        .replaceAll('&#8211;', '\u2013')
        .replaceAll('&#8212;', '\u2014');
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _image(String item) {
    final List<RegExp> patterns = <RegExp>[
      RegExp(r'''<media:(?:content|thumbnail)\b[^>]*\burl=["']([^"']+)["']''',
          caseSensitive: false),
      RegExp(r'''<enclosure\b[^>]*\burl=["']([^"']+)["']''',
          caseSensitive: false),
      RegExp(r'''<img\b[^>]*\bsrc=["']([^"']+)["']''', caseSensitive: false),
    ];
    for (final RegExp pattern in patterns) {
      final String? url = pattern.firstMatch(item)?.group(1);
      if (url != null && url.startsWith('http')) {
        return url.replaceAll('&amp;', '&');
      }
    }
    return null;
  }

  static const Map<String, int> _months = <String, int>{
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Parses RFC 822 dates such as "Thu, 26 Nov 2026 09:00:00 +0500" (also with
  /// a two digit year) as well as ISO 8601.
  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final DateTime? iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    final RegExpMatch? m = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3})[A-Za-z]*\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4})?',
    ).firstMatch(raw);
    if (m == null) return null;
    final int? month = _months[m.group(2)!.toLowerCase()];
    if (month == null) return null;
    int year = int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    final DateTime utc = DateTime.utc(
      year,
      month,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.tryParse(m.group(6) ?? '0') ?? 0,
    );
    final String? zone = m.group(7);
    if (zone == null) return utc;
    final int sign = zone.startsWith('-') ? -1 : 1;
    final Duration offset = Duration(
      hours: int.parse(zone.substring(1, 3)),
      minutes: int.parse(zone.substring(3, 5)),
    );
    return sign > 0 ? utc.subtract(offset) : utc.add(offset);
  }

  String _relative(DateTime? date) {
    if (date == null) return 'Recently';
    final Duration age = DateTime.now().difference(date);
    if (age.inMinutes < 1) return 'Now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    if (age.inDays == 1) return 'Yesterday';
    return '${age.inDays}d ago';
  }
}

class _Feed {
  const _Feed(this.source, this.category, this.feedType, this.url);

  final String source;
  final String category;
  final String feedType;
  final String url;
}
