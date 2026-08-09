import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_topic.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

typedef _TopicRow = ({String id, String name, int count, int bookmarks});
typedef _SubjStats = ({
  int total,
  int bookmarks,
  int wrong,
  double accuracy,
  bool hasAccuracy,
  List<_TopicRow> topics,
});

/// Per-subject study overview: questions, bookmarks, topic breakdown, and —
/// only when real data exists — wrong answers and accuracy. Nothing here
/// depends on timed quizzes, so the page is useful from day one.
class SubjectStatsPage extends ConsumerStatefulWidget {
  const SubjectStatsPage(
      {super.key, required this.subjectId, required this.subjectName});

  final String subjectId;
  final String subjectName;

  @override
  ConsumerState<SubjectStatsPage> createState() => _SubjectStatsPageState();
}

class _SubjectStatsPageState extends ConsumerState<SubjectStatsPage> {
  late Future<_SubjStats> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SubjStats> _load() async {
    final repo = ref.read(quizRepositoryProvider);
    final int total =
        await repo.countQuestions(QuizFilter(subjectId: widget.subjectId));
    final int bookmarks = await repo.countQuestions(
        QuizFilter(subjectId: widget.subjectId, onlyBookmarked: true));
    final int wrong = await repo.countQuestions(
        QuizFilter(subjectId: widget.subjectId, onlyWrong: true));

    double accuracy = 0;
    bool hasAccuracy = false;
    for (final SubjectAccuracy a in await repo.subjectAccuracies()) {
      if (a.subject.toLowerCase() == widget.subjectName.toLowerCase() &&
          a.total > 0) {
        accuracy = a.accuracy;
        hasAccuracy = true;
        break;
      }
    }

    final List<QuizTopicSummary> topics =
        await ref.read(quizTopicsProvider(widget.subjectId).future);
    final List<_TopicRow> rows = <_TopicRow>[];
    for (final QuizTopicSummary t in topics) {
      final int b = await repo.countQuestions(QuizFilter(
          subjectId: widget.subjectId,
          topicId: t.topic.id,
          onlyBookmarked: true));
      rows.add((
        id: t.topic.id,
        name: t.topic.name,
        count: t.questionCount,
        bookmarks: b,
      ));
    }
    rows.sort((_TopicRow a, _TopicRow b) => b.count.compareTo(a.count));

    return (
      total: total,
      bookmarks: bookmarks,
      wrong: wrong,
      accuracy: accuracy,
      hasAccuracy: hasAccuracy,
      topics: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.subjectName} · Statistics')),
      body: FutureBuilder<_SubjStats>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_SubjStats> snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final _SubjStats s = snap.data!;
          final List<(IconData, String, String)> tiles =
              <(IconData, String, String)>[
            (Icons.help_outline, '${s.total}', 'Questions'),
            (Icons.star_border, '${s.bookmarks}', 'Bookmarked'),
            (Icons.category_outlined, '${s.topics.length}', 'Topics'),
            if (s.wrong > 0)
              (Icons.error_outline, '${s.wrong}', 'Wrong'),
            if (s.hasAccuracy)
              (Icons.percent, '${s.accuracy.toStringAsFixed(0)}%', 'Accuracy'),
          ];
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: <Widget>[
              QuizSectionCard(
                icon: Icons.insights,
                title: 'Overview',
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    const double gap = 12;
                    final double w = (c.maxWidth - gap) / 2;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: <Widget>[
                        for (final (IconData, String, String) t in tiles)
                          SizedBox(width: w, child: _Tile(t.$1, t.$2, t.$3)),
                      ],
                    );
                  },
                ),
              ),
              if (s.topics.isNotEmpty)
                QuizSectionCard(
                  icon: Icons.folder_outlined,
                  title: 'By topic',
                  child: Column(
                    children: <Widget>[
                      for (final _TopicRow t in s.topics)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.chevron_right),
                          title: Text(t.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(t.bookmarks > 0
                              ? '${t.count} questions · '
                                  '${t.bookmarks} bookmarked'
                              : '${t.count} questions'),
                          onTap: () => context.push(
                              '${AppRoutes.quizMcqBrowse(widget.subjectId)}'
                              '?topic=${Uri.encodeComponent(t.id)}'
                              '&title=${Uri.encodeComponent(t.name)}'),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
