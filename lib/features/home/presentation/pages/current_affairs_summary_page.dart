import 'package:flutter/material.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_summary.dart';
import 'package:lexiora/features/home/domain/entities/latest_update.dart';
import 'package:url_launcher/url_launcher.dart';

class CurrentAffairsSummaryPage extends StatelessWidget {
  const CurrentAffairsSummaryPage({
    super.key,
    required this.story,
    required this.summary,
  });

  final LatestUpdate story;
  final CurrentAffairsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Summary')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Text(
            story.headline,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${story.source} • ${story.relativeTime}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          _Section(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Summary',
            child: Text(
              summary.summary,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.push_pin_rounded,
            title: 'Key Points',
            child: Column(
              children: summary.keyPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 7, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(point, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4))),
                  ],
                ),
              )).toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.school_rounded,
            title: 'Exam Relevance',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.examRelevance.map((item) => Chip(
                label: Text(item),
                visualDensity: VisualDensity.compact,
              )).toList(growable: false),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => _openSource(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Read Full Article'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSource(BuildContext context) async {
    final raw = story.articleUrl?.trim() ?? '';
    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: scheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}
