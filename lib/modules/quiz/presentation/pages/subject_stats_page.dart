import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_models.dart';
import 'package:lexiora/modules/quiz/presentation/providers/quiz_providers.dart';
import 'package:lexiora/modules/quiz/presentation/widgets/quiz_common.dart';

typedef _SubjStats = ({int total, int bookmarks, int wrong, double accuracy});

/// Per-subject statistics (questions, bookmarks, wrong answers, accuracy).
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
    for (final SubjectAccuracy a in await repo.subjectAccuracies()) {
      if (a.subject.toLowerCase() == widget.subjectName.toLowerCase()) {
        accuracy = a.accuracy;
        break;
      }
    }
    return (total: total, bookmarks: bookmarks, wrong: wrong, accuracy: accuracy);
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
            (Icons.error_outline, '${s.wrong}', 'Wrong'),
            (Icons.percent, '${s.accuracy.toStringAsFixed(0)}%', 'Accuracy'),
          ];
          return ListView(
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
