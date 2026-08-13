import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/features/home/data/latest_update_mock_data.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';
import 'package:lexiora/features/home/domain/entities/latest_update.dart';
import 'package:lexiora/features/home/presentation/providers/current_affairs_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class CurrentAffairsPage extends ConsumerWidget {
  const CurrentAffairsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CurrentAffairsFeed?> feedAsync =
        ref.watch(currentAffairsProvider);
    final CurrentAffairsFeed? liveFeed = feedAsync.maybeWhen(
      data: (CurrentAffairsFeed? feed) => feed,
      orElse: () => null,
    );
    final List<LatestUpdate> national = liveFeed?.national ??
        mockLatestUpdates
            .where((LatestUpdate story) => story.category == 'National')
            .toList(growable: false);
    final List<LatestUpdate> international = liveFeed?.international ??
        mockLatestUpdates
            .where((LatestUpdate story) => story.category == 'International')
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Affairs'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(currentAffairsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: <Widget>[
            _Section(
              title: 'National',
              subtitle: 'Pakistan current affairs',
              stories: national,
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'International',
              subtitle: 'World current affairs',
              stories: international,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.stories,
  });

  final String title;
  final String subtitle;
  final List<LatestUpdate> stories;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        if (stories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No recent stories available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...stories.map((LatestUpdate story) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StoryTile(story: story),
              )),
      ],
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.story});

  final LatestUpdate story;

  Future<void> _openArticle(BuildContext context) async {
    final String? articleUrl = story.articleUrl;
    if (articleUrl == null || articleUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This story has no article link.')),
      );
      return;
    }
    final Uri? uri = Uri.tryParse(articleUrl);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This article link is unavailable.')),
      );
      return;
    }
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the article.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openArticle(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      story.headline,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${story.source} · ${story.relativeTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.open_in_new_rounded, color: scheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
