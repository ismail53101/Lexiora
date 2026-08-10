import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/session_editor.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

/// A pleasant, stable fallback palette so every subject reads as colourful
/// even before the user manually assigns a colour on the Manage Subjects
/// page. The same subject always maps to the same colour (hash-based).
const List<Color> kSubjectFallbackPalette = <Color>[
  Color(0xFF22C55E), // green
  Color(0xFF38BDF8), // sky blue
  Color(0xFFF97316), // orange
  Color(0xFFA855F7), // purple
  Color(0xFFF43F5E), // rose
  Color(0xFFEAB308), // amber
  Color(0xFF14B8A6), // teal
  Color(0xFF6366F1), // indigo
];

/// Resolves a stable, always-colourful colour for [subject]: the user's
/// explicit colour if set, otherwise a deterministic fallback so the
/// planner looks colourful out of the box.
Color resolveSubjectColor(String subject, Map<String, int> colors) {
  final Color? explicit = subjectColorOf(subject, colors);
  if (explicit != null) return explicit;
  final int hash = subject.trim().toLowerCase().codeUnits
      .fold<int>(0, (int acc, int c) => acc * 31 + c);
  return kSubjectFallbackPalette[hash.abs() % kSubjectFallbackPalette.length];
}

/// A pill-style Daily / Weekly / Monthly segmented control matching the
/// planner mockups — a rounded track with a solid purple selected pill.
class PlannerSegmentedControl extends StatelessWidget {
  const PlannerSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: i == selectedIndex
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A date-range header with chevron navigation, e.g. `<  Wed, 14 May  >`.
class PlannerNavHeader extends StatelessWidget {
  const PlannerNavHeader({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

/// A Mon..Sun strip for the week containing [selected]; tapping a day calls
/// [onSelect]. Matches the mockup's rounded selected-day pill.
class PlannerWeekStrip extends ConsumerWidget {
  const PlannerWeekStrip({
    super.key,
    required this.weekStart,
    required this.selected,
    required this.onSelect,
  });

  final DateTime weekStart;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  static const List<String> _dow = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String todayK = todayKey();
    final String selectedK = dayKey(selected);
    final DateTime weekEnd = weekStart.add(const Duration(days: 6));
    final List<StudyTask> weekTasks = ref
        .watch(studyRangeTasksProvider('${dayKey(weekStart)}|${dayKey(weekEnd)}'))
        .maybeWhen(
            data: (List<StudyTask> t) => t, orElse: () => const <StudyTask>[]);
    final Map<String, int> subjectColors = ref
        .watch(subjectColorsProvider)
        .maybeWhen(
            data: (Map<String, int> m) => m, orElse: () => const <String, int>{});
    // Per-day distinct subject colours (up to 3) for the mockup's dot strip.
    final Map<String, List<Color>> dayColors = <String, List<Color>>{};
    for (final StudyTask t in weekTasks) {
      if (t.isBreak) continue;
      final List<Color> list = dayColors.putIfAbsent(t.day, () => <Color>[]);
      final Color c = resolveSubjectColor(t.displaySubject, subjectColors);
      if (!list.contains(c) && list.length < 3) list.add(c);
    }
    return Row(
      children: <Widget>[
        for (int i = 0; i < 7; i++)
          Expanded(
            child: Builder(builder: (BuildContext context) {
              final DateTime d = weekStart.add(Duration(days: i));
              final String k = dayKey(d);
              final bool isSelected = k == selectedK;
              final bool isToday = k == todayK;
              return GestureDetector(
                onTap: () => onSelect(d),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: <Widget>[
                      Text(_dow[i],
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isToday
                                  ? theme.colorScheme.primary.withValues(alpha: 0.14)
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(10),
                          border: isToday && !isSelected
                              ? Border.all(color: theme.colorScheme.primary, width: 1.2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${d.day}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : (isToday ? theme.colorScheme.primary : null),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 6,
                        child: _dayDots(dayColors[k], isSelected, theme),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  /// The mockup's small subject-colour dots under each day of the strip
  /// (up to 3 per day); they turn white when that day's pill is selected.
  Widget _dayDots(List<Color>? colors, bool isSelected, ThemeData theme) {
    if (colors == null || colors.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final Color c in colors)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? theme.colorScheme.onPrimary : c,
            ),
          ),
      ],
    );
  }
}

/// The round checkmark control: a coloured ring (the subject's colour) that
/// fills solid green with a check once the task is completed. Tapping it
/// toggles completion.
class TaskStatusCircle extends ConsumerWidget {
  const TaskStatusCircle({super.key, required this.task, required this.ringColor, this.size = 26});

  final StudyTask task;
  final Color ringColor;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool done = task.completed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref
          .read(studyHubRepositoryProvider)
          .setTaskCompleted(task.id, completed: !done),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? const Color(0xFF22C55E) : Colors.transparent,
          border: Border.all(color: done ? const Color(0xFF22C55E) : ringColor, width: 2.2),
        ),
        alignment: Alignment.center,
        child: done
            ? Icon(Icons.check, size: size * 0.62, color: Colors.white)
            : null,
      ),
    );
  }
}

/// A single planner row: optional time label, a coloured timeline dot
/// (with connecting lines above/below when [showConnector]), title +
/// subtitle, and a trailing status circle / break icon. Swipe left to
/// delete, tap the text to edit.
class PlannerTaskRow extends ConsumerWidget {
  const PlannerTaskRow({
    super.key,
    required this.task,
    this.showConnectorTop = false,
    this.showConnectorBottom = false,
    this.showTime = true,
    this.dense = false,
  });

  final StudyTask task;
  final bool showConnectorTop;
  final bool showConnectorBottom;
  final bool showTime;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Map<String, int> colors = ref.watch(subjectColorsProvider).maybeWhen(
        data: (Map<String, int> m) => m, orElse: () => const <String, int>{});
    final Color subjectColor =
        resolveSubjectColor(task.displaySubject, colors);
    final String time = _timeRange(task);

    return Dismissible(
      key: ValueKey<String>(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(task.isBreak ? 'Delete break?' : 'Delete session?'),
          content: Text('"${task.isBreak ? task.title : task.displaySubject}" will be removed.'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      ).then((bool? v) => v ?? false),
      onDismissed: (_) =>
          ref.read(studyHubRepositoryProvider).deleteTask(task.id),
      child: GestureDetector(
        onTap: () => task.isBreak
            ? showBreakEditor(context, day: task.day, existing: task)
            : showSessionEditor(context, day: task.day, existing: task),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dense ? 4 : 6),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (showTime)
                  SizedBox(
                    width: 64,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        time.isEmpty ? '' : time.split(' – ').first,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                SizedBox(
                  width: 18,
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            color: showConnectorTop
                                ? subjectColor.withValues(alpha: 0.45)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.isBreak ? theme.colorScheme.tertiary : subjectColor,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            color: showConnectorBottom
                                ? subjectColor.withValues(alpha: 0.45)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: task.isBreak
                        ? _breakContent(theme)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      task.displaySubject,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        decoration: task.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: task.completed
                                            ? theme.colorScheme.onSurfaceVariant
                                            : null,
                                      ),
                                    ),
                                    if (time.isNotEmpty)
                                      Text(
                                        time,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                            color: subjectColor,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    if ((task.topic ?? '').isNotEmpty)
                                      Text(
                                        task.topic!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TaskStatusCircle(task: task, ringColor: subjectColor),
                            ],
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

  Widget _breakContent(ThemeData theme) {
    final String time = _timeRange(task);
    return Row(
      children: <Widget>[
        Icon(Icons.work_outline, size: 18, color: theme.colorScheme.tertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            time.isEmpty ? task.title : '${task.title} · $time',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  String _timeRange(StudyTask t) {
    if (t.startMinute == null && t.endMinute == null) return '';
    if (t.endMinute == null) return formatMinuteOfDay(t.startMinute);
    if (t.startMinute == null) return formatMinuteOfDay(t.endMinute);
    return '${formatMinuteOfDay(t.startMinute)} – ${formatMinuteOfDay(t.endMinute)}';
  }
}

/// Opens a small "what do you want to add" sheet, then the right editor.
Future<void> showAddTaskSheet(BuildContext context, {required String day}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.add_task),
              title: const Text('Add study session'),
              onTap: () {
                Navigator.pop(context);
                showSessionEditor(context, day: day);
              },
            ),
            ListTile(
              leading: const Icon(Icons.free_breakfast_outlined),
              title: const Text('Add break'),
              onTap: () {
                Navigator.pop(context);
                showBreakEditor(context, day: day);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// The big rounded "+ Add Task" pill button used at the bottom of every tab.
class AddTaskButton extends StatelessWidget {
  const AddTaskButton({super.key, required this.day});
  final String day;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => showAddTaskSheet(context, day: day),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

/// A compact metric card used in the Monthly tab's 2×2 stats grid.
class PlannerStatCard extends StatelessWidget {
  const PlannerStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(value,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One slice of the [PlannerDonut].
class DonutSegment {
  const DonutSegment({required this.value, required this.color});
  final double value;
  final Color color;
}

/// A multi-segment ring chart (completed / pending / overdue) with a big
/// centered percentage label — the "Monthly Progress" donut in the mockup.
class PlannerDonut extends StatelessWidget {
  const PlannerDonut({
    super.key,
    required this.segments,
    required this.centerValue,
    this.centerLabel,
    this.size = 116,
    this.strokeWidth = 14,
  });

  final List<DonutSegment> segments;
  final String centerValue;
  final String? centerLabel;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              segments: segments,
              strokeWidth: strokeWidth,
              trackColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(centerValue,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              if (centerLabel != null)
                Text(centerLabel!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.strokeWidth,
    required this.trackColor,
  });

  final List<DonutSegment> segments;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset center = rect.center;
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final double total = segments.fold<double>(0, (double a, DonutSegment s) => a + s.value);
    if (total <= 0) return;

    double start = -math.pi / 2;
    for (final DonutSegment seg in segments) {
      if (seg.value <= 0) continue;
      final double sweep = (seg.value / total) * 2 * math.pi;
      final Paint p = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * 0.96, // tiny gap between segments
        false,
        p,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.trackColor != trackColor;
}

/// A legend row for the Monthly Progress card: coloured dot, label, count(%).
class PlannerLegendRow extends StatelessWidget {
  const PlannerLegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.count,
    required this.percent,
  });

  final Color color;
  final String label;
  final int count;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text('$count ($percent%)',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
