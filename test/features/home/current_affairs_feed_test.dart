import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';
import 'package:lexiora/features/home/domain/entities/latest_update.dart';

void main() {
  test('maps separate current affairs categories and story metadata', () {
    final CurrentAffairsFeed feed = CurrentAffairsFeed.fromJson(
      <String, dynamic>{
        'fetchedAt': '2026-08-13T10:00:00.000Z',
        'national': <Map<String, dynamic>>[
          <String, dynamic>{
            'title': 'Pakistan headline',
            'source': 'The News',
            'category': 'National',
            'publishedAt': '2026-08-13T09:30:00.000Z',
            'excerpt': 'Short excerpt',
            'imageUrl': 'https://example.com/image.jpg',
            'articleUrl': 'https://example.com/story',
          },
        ],
        'international': <Map<String, dynamic>>[
          <String, dynamic>{
            'title': 'World headline',
            'source': 'BBC World',
            'category': 'International',
            'publishedAt': '2026-08-13T09:00:00.000Z',
            'articleUrl': 'https://example.com/world',
          },
        ],
      },
    );

    expect(feed.national, hasLength(1));
    expect(feed.international, hasLength(1));
    expect(feed.national.single.headline, 'Pakistan headline');
    expect(feed.national.single.imageUrl, 'https://example.com/image.jpg');
    expect(feed.international.single.source, 'BBC World');
    expect(feed.featured, same(feed.national.single));
  });

  test('classifies only normalized Opinions stories as opinion content', () {
    const LatestUpdate opinion = LatestUpdate(
      headline: 'Editorial view',
      source: 'Dawn',
      category: 'National',
      relativeTime: '1h ago',
      feedType: ' Opinions ',
    );
    const LatestUpdate latest = LatestUpdate(
      headline: 'Breaking update',
      source: 'Dawn',
      category: 'National',
      relativeTime: '1h ago',
      feedType: 'Latest News',
    );

    expect(opinion.isOpinion, isTrue);
    expect(latest.isOpinion, isFalse);
  });
}
