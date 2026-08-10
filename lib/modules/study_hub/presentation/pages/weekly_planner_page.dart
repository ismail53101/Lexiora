import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/day_planner_section.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/planner_view_tabs.dart';

const List<String> _weekdays = <String>[
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Plan the whole week: seven days, each with unlimited sessions and breaks.
///
/// Each day collapses down to a single "Weekday, date · N tasks ⌄" row you
/// tap to expand — only today opens by default. A full week of sessions used
/// to mean scrolling through every day fully expanded at once; this keeps
/// the whole week visible at a glance while still being one tap away from
/// any day's full list.
class WeeklyPlannerPage extends ConsumerStatefulWidget {
  const WeeklyPlannerPage({super.key});

  @override
  ConsumerState<WeeklyPlannerPage> createState() => _WeeklyPlannerPageState();
}

class _WeeklyPlannerPageState extends ConsumerState<WeeklyPlannerPage> {
  late DateTime _weekStart = _mondayOf(DateTime.now());
  final Set<String> _expanded = <String>{todayKey()};

  static DateTime _mondayOf(DateTime d) {
    final DateTime day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _shift(int weeks) =>
      setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));

  @override
  Widget build(BuildContext context) {
    final DateTime end = _weekStart.add(const Duration(days: 6));
    final String today = todayKey();
    final String label =
        '${_months[_weekStart.month - 1]} ${_weekStart.day} – '
        '${_months[end.month - 1]} ${end.day}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Planner'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56 + 48),
          child: Column(
            children: <Widget>[
              const PlannerViewTabs(current: PlannerView.weekly),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: () => _shift(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 7,
        separatorBuilder: (_, _) => const Divider(height: 20),
        itemBuilder: (BuildContext context, int i) {
          final DateTime d = _weekStart.add(Duration(days: i));
          final String key = dayKey(d);
          final bool expanded = _expanded.contains(key);
          return _CollapsibleDay(
            day: key,
            title: _weekdays[i],
            subtitle: '${_months[d.month - 1]} ${d.day}',
            highlight: key == today,
            expanded: expanded,
            onToggle: () => setState(() {
              if (expanded) {
                _expanded.remove(key);
              } else {
                _expanded.add(key);
              }
            }),
          );
        },
      ),
    );
  }
}

/// A single day, collapsed to a compact "title · N tasks ⌄" header row by
/// default — tap anywhere on the header (or the chevron) to expand into the
/// full [DayPlannerSection] for that day.
class _CollapsibleDay extends ConsumerWidget {
  const _CollapsibleDay({
    required this.day,
    required this.title,
    required this.subtitle,
    required this.highlight,
    required this.expanded,
    required this.onToggle,
  });

  final String day;
  final String title;
  final String subtitle;
  final bool highlight;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final int count = ref.watch(studyDayTasksProvider(day)).maybeWhen(
          data: (List<StudyTask> t) => t.length,
          orElse: () => 0,
        );

    if (expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: highlight ? theme.colorScheme.primary : null),
                        children: <InlineSpan>[
                          TextSpan(text: title),
                          TextSpan(
                            text: '  $subtitle',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.expand_less,
                      size: 20, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          DayPlannerSection(day: day, title: '', subtitle: null),
        ],
      );
    }

    // Collapsed: one compact row, no session list rendered at all.
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highlight
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: highlight ? theme.colorScheme.primary : null),
                  children: <InlineSpan>[
                    TextSpan(text: title),
                    TextSpan(
                      text: '  $subtitle',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Text('$count task${count == 1 ? '' : 's'}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
