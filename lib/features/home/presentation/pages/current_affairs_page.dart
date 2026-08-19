import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/features/home/data/latest_update_mock_data.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';
import 'package:lexiora/features/home/domain/entities/latest_update.dart';
import 'package:lexiora/features/home/presentation/providers/current_affairs_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class CurrentAffairsPage extends ConsumerStatefulWidget {
  const CurrentAffairsPage({super.key});

  @override
  ConsumerState<CurrentAffairsPage> createState() => _CurrentAffairsPageState();
}

class _CurrentAffairsPageState extends ConsumerState<CurrentAffairsPage> {
  int _selectedSection = 0;
  int _selectedFeedType = 0;

  Future<void> _refresh() async {
    ref.invalidate(currentAffairsProvider);
    await ref.read(currentAffairsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AsyncValue<CurrentAffairsFeed?> feedAsync = ref.watch(currentAffairsProvider);
    final CurrentAffairsFeed? liveFeed = feedAsync.maybeWhen(
      data: (CurrentAffairsFeed? feed) => feed,
      orElse: () => null,
    );
    final List<LatestUpdate> national = liveFeed?.national ?? _fallback('National');
    final List<LatestUpdate> international = liveFeed?.international ?? _fallback('International');
    final List<LatestUpdate> sectionStories = _selectedSection == 0 ? national : international;
    final String sectionLabel = _selectedSection == 0 ? 'National' : 'International';
    final bool isNational = _selectedSection == 0;
    final String feedLabel = isNational && _selectedFeedType == 1 ? 'Opinions' : 'Latest';
    final List<LatestUpdate> stories = isNational
        ? sectionStories
            .where((LatestUpdate story) => _matchesFeedType(story, _selectedFeedType))
            .toList(growable: false)
        : sectionStories;
    final bool isRefreshing = feedAsync.isLoading && liveFeed == null;

    final Color pageBackground = theme.brightness == Brightness.light
        ? Color.lerp(scheme.surface, scheme.primaryContainer, 0.16)!
        : scheme.surface;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Image.asset('assets/branding/app_icon.png'),
            ),
            const SizedBox(width: 10),
            const Text('Current Affairs'),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _LivePill(color: scheme.tertiary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: scheme.primary,
        backgroundColor: scheme.surfaceContainerHigh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _IntroBlock(
                  selectedSection: _selectedSection,
                  onSectionChanged: (int index) => setState(() => _selectedSection = index),
                ),
              ),
            ),
            if (isNational)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _FeedTypeSwitcher(
                    selectedFeedType: _selectedFeedType,
                    onFeedTypeChanged: (int index) => setState(() => _selectedFeedType = index),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: _SectionHeading(
                  sectionLabel: sectionLabel,
                  feedLabel: feedLabel,
                  storyCount: stories.length,
                  isLive: liveFeed != null,
                ),
              ),
            ),
            if (isRefreshing)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (stories.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                  child: _EmptyStoriesCard(sectionLabel: sectionLabel),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _FeaturedStoryCard(story: stories.first),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
                sliver: SliverList.builder(
                  itemCount: stories.length > 1 ? stories.length - 1 : 0,
                  itemBuilder: (BuildContext context, int index) {
                    final LatestUpdate story = stories[index + 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EditorialStoryCard(story: story),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _matchesFeedType(LatestUpdate story, int selectedFeedType) {
    if (selectedFeedType == 0) {
      return story.feedType.toLowerCase() != 'opinions';
    }
    return story.feedType.toLowerCase() == 'opinions';
  }

  List<LatestUpdate> _fallback(String category) {
    return mockLatestUpdates
        .where((LatestUpdate story) => story.category.toLowerCase() == category.toLowerCase())
        .toList(growable: false);
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              'LIVE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroBlock extends StatelessWidget {
  const _IntroBlock({required this.selectedSection, required this.onSectionChanged});

  final int selectedSection;
  final ValueChanged<int> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'The daily brief',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Stay sharp on the stories shaping Pakistan and the world.',
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: <Widget>[
                _Segment(
                  label: 'National',
                  detail: 'Pakistan',
                  selected: selectedSection == 0,
                  onTap: () => onSectionChanged(0),
                ),
                _Segment(
                  label: 'International',
                  detail: 'World',
                  selected: selectedSection == 1,
                  onTap: () => onSectionChanged(1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedTypeSwitcher extends StatelessWidget {
  const _FeedTypeSwitcher({required this.selectedFeedType, required this.onFeedTypeChanged});

  final int selectedFeedType;
  final ValueChanged<int> onFeedTypeChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.58)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: <Widget>[
            _FeedTypeSegment(
              label: 'Latest',
              icon: Icons.bolt_rounded,
              selected: selectedFeedType == 0,
              onTap: () => onFeedTypeChanged(0),
            ),
            _FeedTypeSegment(
              label: 'Opinions',
              icon: Icons.forum_outlined,
              selected: selectedFeedType == 1,
              onTap: () => onFeedTypeChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTypeSegment extends StatelessWidget {
  const _FeedTypeSegment({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color foreground = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Expanded(
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.detail, required this.selected, required this.onTap});

  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Expanded(
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  detail.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground.withValues(alpha: selected ? 0.78 : 0.72),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.sectionLabel, required this.feedLabel, required this.storyCount, required this.isLive});

  final String sectionLabel;
  final String feedLabel;
  final int storyCount;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$sectionLabel · $feedLabel headlines',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                '$storyCount $feedLabel reports',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Icon(isLive ? Icons.wifi_tethering_rounded : Icons.cloud_off_rounded, size: 16, color: isLive ? scheme.tertiary : scheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          isLive ? 'Live feed' : 'Saved fallback',
          style: theme.textTheme.labelMedium?.copyWith(
            color: isLive ? scheme.tertiary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FeaturedStoryCard extends StatelessWidget {
  const _FeaturedStoryCard({required this.story});

  final LatestUpdate story;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openArticle(context, story),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _StoryImage(story: story, height: 170, radius: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 15, 7, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _CategoryTag(label: story.category),
                        const Spacer(),
                        Text(
                          '${story.source} · ${story.relativeTime}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      story.headline,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (story.excerpt.trim().isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        story.excerpt.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 13),
                    Row(
                      children: <Widget>[
                        Text(
                          'Read full report',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(Icons.arrow_forward_rounded, size: 17, color: scheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialStoryCard extends StatelessWidget {
  const _EditorialStoryCard({required this.story});

  final LatestUpdate story;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openArticle(context, story),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              _StoryImage(story: story, height: 76, width: 88, radius: 13),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      story.headline,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            story.source,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(' · ${story.relativeTime}', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.arrow_outward_rounded, size: 18, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryImage extends StatelessWidget {
  const _StoryImage({required this.story, required this.height, required this.radius, this.width});

  final LatestUpdate story;
  final double height;
  final double radius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Widget fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[scheme.primaryContainer, scheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.public_rounded, color: scheme.onPrimaryContainer, size: height * 0.30),
      ),
    );
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: story.imageUrl == null
            ? fallback
            : Image.network(
                story.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.45,
          ),
        ),
      ),
    );
  }
}

class _EmptyStoriesCard extends StatelessWidget {
  const _EmptyStoriesCard({required this.sectionLabel});

  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.newspaper_outlined, color: scheme.primary, size: 30),
          const SizedBox(height: 10),
          Text(
            'No $sectionLabel stories available yet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to refresh the live feed.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

Future<void> _openArticle(BuildContext context, LatestUpdate story) async {
  final String? articleUrl = story.articleUrl?.trim();
  if (articleUrl == null || articleUrl.isEmpty) {
    await _showArticleUnavailable(context, story);
    return;
  }

  final Uri? uri = Uri.tryParse(articleUrl);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
    await _showArticleUnavailable(context, story);
    return;
  }

  try {
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      await _showArticleUnavailable(context, story);
    }
  } on Object {
    if (context.mounted) {
      await _showArticleUnavailable(context, story);
    }
  }
}

Future<void> _showArticleUnavailable(
  BuildContext context,
  LatestUpdate story,
) async {
  if (!context.mounted) return;
  final ThemeData theme = Theme.of(context);
  final ColorScheme scheme = theme.colorScheme;
  final String url = story.articleUrl?.trim() ?? '';

  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: Icon(Icons.public_off_rounded, color: scheme.tertiary),
        title: const Text('Source temporarily unavailable'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'This ${story.source} article could not be opened. The original news source may be unavailable on your network or may be blocking access from this device.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Original source',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                story.source,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (url.isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(
                  url,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          if (url.isNotEmpty)
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openArticle(context, story);
              },
              child: const Text('Try again'),
            ),
        ],
      );
    },
  );
}
