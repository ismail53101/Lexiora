import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/exam_dialogs.dart';

/// Exam dates with a countdown, and a syllabus checklist per subject.
class StudyExamsPage extends ConsumerWidget {
  const StudyExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ExamCountdown>> async = ref.watch(examCountdownsProvider);
    final List<SubjectSyllabus> syllabi =
        ref.watch(syllabiProvider).asData?.value ?? const <SubjectSyllabus>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Exams & syllabus')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showExamEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add exam'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Couldn’t load exams: $e')),
        data: (List<ExamCountdown> list) {
          final List<ExamCountdown> upcoming = list.where((ExamCountdown c) => c.isUpcoming).toList();
          final List<ExamCountdown> past = list.where((ExamCountdown c) => !c.isUpcoming).toList();
          final Set<String> examSubjects = <String>{
            for (final ExamCountdown c in list) c.exam.subject.trim().toLowerCase(),
          };
          final List<SubjectSyllabus> otherSyllabi = syllabi
              .where((SubjectSyllabus s) => !examSubjects.contains(s.subject.trim().toLowerCase()))
              .toList();

          if (list.isEmpty && syllabi.isEmpty) {
            return _Empty(onAdd: () => showExamEditor(context));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: <Widget>[
              if (upcoming.isNotEmpty) const _Header('Upcoming'),
              for (final ExamCountdown c in upcoming) _ExamCard(countdown: c),
              if (otherSyllabi.isNotEmpty) ...<Widget>[
                const _Header('Other syllabi'),
                for (final SubjectSyllabus s in otherSyllabi)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: ListTile(
                      title: Text(s.subject),
                      subtitle: Text('${s.done}/${s.total} topics · ${s.percent}%'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showSyllabusSheet(context, s.subject),
                    ),
                  ),
              ],
              if (past.isNotEmpty) ...<Widget>[
                const _Header('Past exams'),
                for (final ExamCountdown c in past) _ExamCard(countdown: c),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.event_available_outlined, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Count down to your exams',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Add an exam date and list the topics you need to cover. The planner shows '
              'how many days are left and how many topics per day you need.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add exam')),
          ],
        ),
      ),
    );
  }
}

class _ExamCard extends ConsumerWidget {
  const _ExamCard({required this.countdown});
  final ExamCountdown countdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final StudyExam exam = countdown.exam;
    final Color color = examUrgencyColor(cs, countdown.urgency);
    final SubjectSyllabus? syl = countdown.syllabus;
    final DateTime? date = exam.date;
    final String big = countdown.isUpcoming ? '${countdown.daysLeft}' : '—';

    return Opacity(
      opacity: countdown.isUpcoming ? 1 : 0.6,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showSyllabusSheet(context, exam.subject),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(big, style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w900, height: 1)),
                          if (countdown.isUpcoming)
                            Text(countdown.daysLeft == 1 ? 'day' : 'days', style: theme.textTheme.labelSmall?.copyWith(color: color)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(exam.subject, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          Text(exam.title, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 2),
                          Text(
                            '${date == null ? exam.day : formatExamDate(date)} · ${countdown.label}',
                            style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String v) async {
                        if (v == 'edit') {
                          await showExamEditor(context, exam: exam);
                        } else if (v == 'delete') {
                          await ref.read(examRepositoryProvider).deleteExam(exam.id);
                        }
                      },
                      itemBuilder: (BuildContext c) => const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                        PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (syl == null)
                  OutlinedButton.icon(
                    onPressed: () => showSyllabusSheet(context, exam.subject),
                    icon: const Icon(Icons.checklist, size: 18),
                    label: const Text('Add syllabus topics'),
                  )
                else ...<Widget>[
                  LinearProgressIndicator(value: syl.fraction, minHeight: 8, borderRadius: BorderRadius.circular(8)),
                  const SizedBox(height: 6),
                  Text(
                    '${syl.done}/${syl.total} topics · ${syl.percent}%'
                    '${countdown.paceText == null ? '' : ' · ${countdown.paceText}'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
