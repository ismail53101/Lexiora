import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/report/weekly_report.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:share_plus/share_plus.dart';

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _dayLetters = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// How much you studied this week, on what, and how it compared with your plan.
class WeeklyReportPage extends ConsumerStatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  ConsumerState<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends ConsumerState<WeeklyReportPage> {
  late DateTime _week = mondayOf(DateTime.now());

  DateTime get _thisMonday => mondayOf(DateTime.now());
  bool get _isCurrent => !_week.isBefore(_thisMonday);

  void _shift(int weeks) => setState(() => _week = DateTime(_week.year, _week.month, _week.day + 7 * weeks));

  String _label() {
    final DateTime end = DateTime(_week.year, _week.month, _week.day + 6);
    final String range = _week.month == end.month
        ? '${_week.day} – ${end.day} ${_months[end.month - 1]}'
        : '${_week.day} ${_months[_week.month - 1]} – ${end.day} ${_months[end.month - 1]}';
    if (_isCurrent) return 'This week · $range';
    if (_week == DateTime(_thisMonday.year, _thisMonday.month, _thisMonday.day - 7)) return 'Last week · $range';
    return range;
  }

  @override
  Widget build(BuildContext context) {
    final String weekKey = _key(_week);
    final AsyncValue<WeeklyReport> async = ref.watch(weeklyReportProvider(weekKey));
    final Map<String, int> colors = ref.watch(subjectColorsProvider).asData?.value ?? const <String, int>{};
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly report'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: async.asData == null
                ? null
                : () => SharePlus.instance.share(ShareParams(text: async.asData!.value.toShareText())),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Row(
              children: <Widget>[
                IconButton(tooltip: 'Previous week', icon: const Icon(Icons.chevron_left), onPressed: () => _shift(-1)),
                Expanded(
                  child: Text(_label(), textAlign: TextAlign.center, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                ),
                IconButton(tooltip: 'Next week', icon: const Icon(Icons.chevron_right), onPressed: _isCurrent ? null : () => _shift(1)),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(weeklyReportProvider(weekKey));
                await ref.read(weeklyReportProvider(weekKey).future);
              },
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace _) => ListView(children: <Widget>[Padding(padding: const EdgeInsets.all(32), child: Text('Couldn’t build the report: $e'))]),
                data: (WeeklyReport r) => r.isEmpty
                    ? ListView(children: const <Widget>[_Empty()])
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        children: <Widget>[
                          _Summary(r: r),
                          _Card(title: 'Each day', icon: Icons.bar_chart_rounded, child: _DaysChart(r: r)),
                          if (r.plannedSessions > 0) _PlanCard(r: r),
                          if (r.subjects.isNotEmpty) _SubjectsCard(r: r, colors: colors),
                          if (r.minutesByPart.isNotEmpty) _PartsCard(r: r),
                          if (r.insights.isNotEmpty) _InsightsCard(r: r),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
      child: Column(
        children: <Widget>[
          Icon(Icons.insights_outlined, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Nothing to report yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Plan some sessions and tick them off (or use the timer). Your week will show up here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.r});
  final WeeklyReport r;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int? dp = r.deltaPercent;
    final bool up = r.deltaMinutes >= 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[cs.primaryContainer, cs.tertiaryContainer]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('You studied', style: theme.textTheme.labelLarge?.copyWith(color: cs.onPrimaryContainer)),
          const SizedBox(height: 2),
          Text(formatMinutes(r.totalMinutes),
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onPrimaryContainer, height: 1.1)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              if (dp != null && r.lastWeekMinutes > 0)
                _Chip(
                  icon: up ? Icons.trending_up : Icons.trending_down,
                  text: '${up ? '+' : '-'}${formatMinutes(r.deltaMinutes)} ($dp%) vs last week',
                  color: up ? Colors.green.shade700 : cs.error,
                ),
              _Chip(icon: Icons.event_available, text: '${r.activeDays}/7 days', color: cs.primary),
              if (r.activeDays > 0) _Chip(icon: Icons.timer_outlined, text: 'avg ${formatMinutes(r.averagePerActiveDay)}/day', color: cs.secondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _DaysChart extends StatelessWidget {
  const _DaysChart({required this.r});
  final WeeklyReport r;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    int max = 1;
    for (final DayStat d in r.days) {
      if (d.minutes > max) max = d.minutes;
    }
    const double h = 110;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < r.days.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 16,
                    child: Text(r.days[i].minutes == 0 ? '' : (r.days[i].minutes >= 60 ? '${(r.days[i].minutes / 60).toStringAsFixed(1)}h' : '${r.days[i].minutes}m'),
                        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  SizedBox(
                    height: h,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: r.days[i].minutes / max),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOut,
                        builder: (BuildContext c, double f, Widget? _) => Container(
                          height: r.days[i].minutes == 0 ? 3 : (h - 4) * f + 3,
                          decoration: BoxDecoration(
                            color: r.days[i].isFuture
                                ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                                : (r.days[i].minutes == 0 ? cs.surfaceContainerHighest : cs.primary),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            border: r.days[i].isToday ? Border.all(color: cs.tertiary, width: 2) : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_dayLetters[i],
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: r.days[i].isToday ? FontWeight.w900 : FontWeight.w500,
                        color: r.days[i].isToday ? cs.tertiary : cs.onSurfaceVariant,
                      )),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.r});
  final WeeklyReport r;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int pct = r.completionPercent ?? 0;
    return _Card(
      title: 'Plan vs done',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LinearProgressIndicator(value: pct / 100, minHeight: 10, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 8),
          Text('${r.completedSessions} of ${r.plannedSessions} planned sessions done · $pct%',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (r.plannedMinutes > 0)
            Text('Planned ${formatMinutes(r.plannedMinutes)} · studied ${formatMinutes(r.totalMinutes)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SubjectsCard extends StatelessWidget {
  const _SubjectsCard({required this.r, required this.colors});
  final WeeklyReport r;
  final Map<String, int> colors;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int top = r.subjects.first.minutes == 0 ? 1 : r.subjects.first.minutes;
    return _Card(
      title: 'By subject',
      icon: Icons.menu_book_outlined,
      child: Column(
        children: <Widget>[
          for (final SubjectShare s in r.subjects)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: <Widget>[
                    Expanded(child: Text(s.subject, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                    Text('${formatMinutes(s.minutes)} · ${s.percent}%', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: s.minutes / top,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(6),
                    color: colors[s.subject.toLowerCase()] == null ? cs.primary : Color(colors[s.subject.toLowerCase()]!),
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PartsCard extends StatelessWidget {
  const _PartsCard({required this.r});
  final WeeklyReport r;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    int max = 1;
    for (final int v in r.minutesByPart.values) {
      if (v > max) max = v;
    }
    final DayPart? best = r.bestPart;
    return _Card(
      title: 'When you study',
      icon: Icons.wb_twilight_outlined,
      child: Column(
        children: <Widget>[
          for (final DayPart p in DayPart.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 88, child: Text(p.label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: p == best ? FontWeight.w900 : FontWeight.w500))),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (r.minutesByPart[p] ?? 0) / max,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(6),
                      color: p == best ? cs.tertiary : cs.primary.withValues(alpha: 0.6),
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                  SizedBox(width: 64, child: Text(formatMinutes(r.minutesByPart[p] ?? 0), textAlign: TextAlign.right, style: theme.textTheme.labelMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.r});
  final WeeklyReport r;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    IconData icon(InsightKind k) => switch (k) {
          InsightKind.trend => Icons.show_chart,
          InsightKind.focus => Icons.center_focus_strong_outlined,
          InsightKind.exam => Icons.event_busy_outlined,
          InsightKind.plan => Icons.fact_check_outlined,
          InsightKind.habit => Icons.local_fire_department_outlined,
          InsightKind.time => Icons.schedule,
        };
    return _Card(
      title: 'What stands out',
      icon: Icons.lightbulb_outline,
      child: Column(
        children: <Widget>[
          for (final ReportInsight i in r.insights)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(icon(i.kind), size: 20, color: i.positive == null ? cs.onSurfaceVariant : (i.positive! ? Colors.green.shade700 : cs.error)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(i.text, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
