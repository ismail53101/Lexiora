import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

/// 📊 Progress — the old "Weekly Statistics" and "Progress Tracker" cards
/// merged into one section with a Weekly/Monthly toggle. Both previously
/// showed largely the same metrics in two separate large cards; this keeps
/// every metric from both (study time, completed/pending sessions, subjects,
/// topics, goals, break time, avg daily) in a single compact grid that just
/// switches range instead of duplicating itself.
class ProgressCard extends ConsumerStatefulWidget {
  const ProgressCard({super.key});

  @override
  ConsumerState<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends ConsumerState<ProgressCard> {
  StudyRange _range = StudyRange.weekly;

  @override
  Widget build(BuildContext context) {
    final StudyStatistics time = ref.watch(studyStatisticsProvider).maybeWhen(
          data: (StudyStatistics value) => value,
          orElse: () => StudyStatistics.empty,
        );
    final StudyStats s = ref.watch(studyStatsProvider(_range)).maybeWhen(
          data: (StudyStats v) => v,
          orElse: () => StudyStats.empty(_range.days),
        );
    final List<StudySubject> subjects =
        ref.watch(subjectsProvider(false)).maybeWhen(
              data: (List<StudySubject> v) => v,
              orElse: () => const <StudySubject>[],
            );

    return SectionCard(
      icon: Icons.insights,
      title: 'Progress',
      trailing: SegmentedButton<StudyRange>(
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
        segments: const <ButtonSegment<StudyRange>>[
          ButtonSegment<StudyRange>(value: StudyRange.weekly, label: Text('Weekly')),
          ButtonSegment<StudyRange>(value: StudyRange.monthly, label: Text('Monthly')),
        ],
        selected: <StudyRange>{_range},
        onSelectionChanged: (Set<StudyRange> v) =>
            setState(() => _range = v.first),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StudyStatGrid(
            tiles: <Widget>[
              StudyStatTile(
                  icon: Icons.schedule,
                  value: formatDuration(s.studyMinutes),
                  label: 'Study time'),
              StudyStatTile(
                  icon: Icons.task_alt,
                  value: '${s.completedSessions}',
                  label: 'Completed'),
              StudyStatTile(
                  icon: Icons.menu_book_outlined,
                  value: '${s.subjectsStudied}',
                  label: 'Subjects studied'),
              StudyStatTile(
                  icon: Icons.topic_outlined,
                  value: '${s.topicsCompleted}',
                  label: 'Topics completed'),
              StudyStatTile(
                  icon: Icons.flag,
                  value: '${s.goalsAchieved}',
                  label: 'Goals completed'),
              StudyStatTile(
                  icon: Icons.free_breakfast_outlined,
                  value: formatDuration(s.breakMinutes),
                  label: 'Break time'),
              StudyStatTile(
                  icon: Icons.pending_actions,
                  value: '${s.pendingSessions}',
                  label: 'Pending'),
              StudyStatTile(
                  icon: Icons.trending_up,
                  value: formatDuration(s.avgDailyMinutes),
                  label: 'Avg daily'),
            ],
          ),
          const SizedBox(height: 12),
          Text('Study time by day',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 8),
          Text('Yesterday: ${formatDuration(time.yesterdayMinutes)}'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int i = 0; i < time.days.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(formatDuration(time.days[i]),
                            style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Container(
                          height: time.days[i] == 0
                              ? 6
                              : (12 + (time.days[i].clamp(0, 240) / 240) * 44),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_dayLabel(i),
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StudyStatGrid(
            tiles: <Widget>[
              StudyStatTile(
                  icon: Icons.date_range,
                  value: formatDuration(time.weeklyMinutes),
                  label: 'Last 7 days'),
              StudyStatTile(
                  icon: Icons.calendar_month,
                  value: formatDuration(time.monthlyMinutes),
                  label: 'This month'),
            ],
          ),
          if (subjects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final StudySubject sub in subjects.take(10))
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: CircleAvatar(backgroundColor: sub.colorValue),
                    label: Text(sub.name),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _dayLabel(int index) {
    final DateTime day = DateTime.now().subtract(Duration(days: 6 - index));
    const List<String> labels = <String>[
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return labels[day.weekday - 1];
  }
}
