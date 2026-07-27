import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_models.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_subject.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

/// 📊 Weekly Statistics — the last 7 days at a glance.
class WeeklyStatsCard extends ConsumerWidget {
  const WeeklyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StudyStats s =
        ref.watch(studyStatsProvider(StudyRange.weekly)).maybeWhen(
              data: (StudyStats v) => v,
              orElse: () => StudyStats.empty(StudyRange.weekly.days),
            );

    final List<StudySubject> subjects = ref.watch(subjectsProvider(false)).maybeWhen(
          data: (List<StudySubject> v) => v,
          orElse: () => const <StudySubject>[],
        );

    return SectionCard(
      icon: Icons.bar_chart,
      title: 'Weekly Statistics',
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
                  label: 'Completed sessions'),
              StudyStatTile(
                  icon: Icons.pending_actions,
                  value: '${s.pendingSessions}',
                  label: 'Pending sessions'),
              StudyStatTile(
                  icon: Icons.menu_book_outlined,
                  value: '${s.subjectsStudied}',
                  label: 'Subjects studied'),
              StudyStatTile(
                  icon: Icons.topic_outlined,
                  value: '${s.topicsCompleted}',
                  label: 'Topics completed'),
              StudyStatTile(
                  icon: Icons.free_breakfast_outlined,
                  value: formatDuration(s.breakMinutes),
                  label: 'Break time'),
              StudyStatTile(
                  icon: Icons.flag,
                  value: '${s.goalsAchieved}',
                  label: 'Goals completed'),
              StudyStatTile(
                  icon: Icons.trending_up,
                  value: formatDuration(s.avgDailyMinutes),
                  label: 'Avg daily'),
            ],
          ),
          if (subjects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
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
}

/// 📈 Progress Tracker — weekly / monthly toggle of the core metrics.
class ProgressTrackerCard extends ConsumerStatefulWidget {
  const ProgressTrackerCard({super.key});

  @override
  ConsumerState<ProgressTrackerCard> createState() =>
      _ProgressTrackerCardState();
}

class _ProgressTrackerCardState extends ConsumerState<ProgressTrackerCard> {
  StudyRange _range = StudyRange.weekly;

  @override
  Widget build(BuildContext context) {
    final StudyStats s = ref.watch(studyStatsProvider(_range)).maybeWhen(
          data: (StudyStats v) => v,
          orElse: () => StudyStats.empty(_range.days),
        );

    return SectionCard(
      icon: Icons.insights,
      title: 'Progress Tracker',
      trailing: SegmentedButton<StudyRange>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const <ButtonSegment<StudyRange>>[
          ButtonSegment<StudyRange>(value: StudyRange.weekly, label: Text('Weekly')),
          ButtonSegment<StudyRange>(value: StudyRange.monthly, label: Text('Monthly')),
        ],
        selected: <StudyRange>{_range},
        onSelectionChanged: (Set<StudyRange> v) =>
            setState(() => _range = v.first),
      ),
      child: StudyStatGrid(
        tiles: <Widget>[
          StudyStatTile(
              icon: Icons.schedule,
              value: formatDuration(s.studyMinutes),
              label: '${_range.label} study time'),
          StudyStatTile(
              icon: Icons.task_alt,
              value: '${s.completedSessions}',
              label: 'Completed sessions'),
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
              label: 'Goals achieved'),
          StudyStatTile(
              icon: Icons.free_breakfast_outlined,
              value: formatDuration(s.breakMinutes),
              label: 'Break time'),
        ],
      ),
    );
  }
}
