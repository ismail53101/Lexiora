import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/exam_dialogs.dart';

/// Nearest upcoming exams with days left and syllabus pace, for the planner's
/// daily view. Shows a small "add your exams" prompt when there are none.
class ExamCountdownCard extends ConsumerWidget {
  const ExamCountdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ExamCountdown>? all = ref.watch(examCountdownsProvider).asData?.value;
    if (all == null) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final List<ExamCountdown> next = all
        .where((ExamCountdown c) => c.isUpcoming && c.daysLeft <= 120)
        .take(2)
        .toList();

    if (all.isEmpty) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: Icon(Icons.event_available_outlined, color: cs.primary),
          title: const Text('Add your exam dates'),
          subtitle: const Text('Get a countdown and a syllabus tracker'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.studyHubExams),
        ),
      );
    }
    if (next.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(AppRoutes.studyHubExams),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.event_note_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Exam countdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                  IconButton(
                    tooltip: 'Add exam',
                    icon: const Icon(Icons.add),
                    onPressed: () => showExamEditor(context),
                  ),
                ],
              ),
              for (final ExamCountdown c in next)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 8),
                  child: _Row(c: c),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.c});
  final ExamCountdown c;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = examUrgencyColor(theme.colorScheme, c.urgency);
    final SubjectSyllabus? s = c.syllabus;
    return Row(
      children: <Widget>[
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: <Widget>[
              Text('${c.daysLeft}', style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w900, height: 1)),
              Text(c.daysLeft == 1 ? 'day' : 'days', style: theme.textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${c.exam.subject} · ${c.exam.title}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                s == null || s.total == 0
                    ? c.label
                    : '${s.done}/${s.total} topics${c.paceText == null ? '' : ' · ${c.paceText}'}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (s != null && s.total > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(value: s.fraction, minHeight: 5, borderRadius: BorderRadius.circular(5)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
