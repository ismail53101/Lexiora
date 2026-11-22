import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/recurrence/recurrence.dart';
import 'package:lexiora/modules/study_hub/domain/recurrence/repeat_series.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _shortDay(String key) {
  final DateTime? d = parseDayKeyOrNull(key);
  if (d == null) return key;
  return '${weekdayShort[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

/// Your weekly repeating sessions: extend them, or end them.
class RepeatingSessionsPage extends ConsumerWidget {
  const RepeatingSessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RepeatSeries>> async = ref.watch(repeatSeriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Repeating sessions')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Couldn’t load: $e')),
        data: (List<RepeatSeries> list) {
          if (list.isEmpty) return const _Empty();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              for (final RepeatSeries s in list) _SeriesCard(series: s),
            ],
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.repeat_rounded, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No repeating sessions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'When you add a session, switch on “Repeat weekly” to schedule it on '
              'the same days every week. You can extend or end it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesCard extends ConsumerStatefulWidget {
  const _SeriesCard({required this.series});
  final RepeatSeries series;

  @override
  ConsumerState<_SeriesCard> createState() => _SeriesCardState();
}

class _SeriesCardState extends ConsumerState<_SeriesCard> {
  bool _busy = false;

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _extend() async {
    setState(() => _busy = true);
    try {
      final RepeatSaveResult r = await ref.read(studyHubRepositoryProvider).extendSeries(
            seriesId: widget.series.id,
            weeks: 4,
            today: todayKey(),
          );
      if (!mounted) return;
      _toast(
        'Added ${r.created} ${r.created == 1 ? 'session' : 'sessions'}'
        '${r.skippedDays.isEmpty ? '' : '. Skipped ${r.skippedDays.length} (time already taken)'}',
      );
    } on Object catch (e) {
      if (mounted) _toast('Couldn’t extend: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    final RepeatSeries s = widget.series;
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext d) => AlertDialog(
            title: Text(s.isFinished ? 'Remove this series?' : 'End this series?'),
            content: Text(
              s.isFinished
                  ? 'It has no upcoming sessions. Past sessions stay in your history.'
                  : 'The ${s.upcoming} upcoming ${s.upcoming == 1 ? 'session' : 'sessions'} that are not done will be deleted. '
                      'Sessions already done, and past ones, stay.',
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(s.isFinished ? 'Remove' : 'End series')),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final int n = await ref.read(studyHubRepositoryProvider).endSeries(seriesId: s.id, fromDay: todayKey());
      if (mounted) _toast(n == 0 ? 'Series removed' : 'Removed $n upcoming ${n == 1 ? 'session' : 'sessions'}');
    } on Object catch (e) {
      if (mounted) _toast('Couldn’t end it: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final RepeatSeries s = widget.series;
    final String time = '${formatMinuteOfDay(s.startMinute)} – ${formatMinuteOfDay(s.endMinute)}';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.repeat_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.topic == null || s.topic!.isEmpty ? s.subject : '${s.subject} · ${s.topic}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${describeWeekdays(s.weekdays)} · $time'
              '${s.breakMinutes > 0 ? ' · ${s.breakMinutes} min break' : ''}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              s.isFinished
                  ? 'Finished · ended ${_shortDay(s.untilDay)}'
                  : '${s.upcoming} upcoming${s.nextDay == null ? '' : ' · next ${_shortDay(s.nextDay!)}'} · until ${_shortDay(s.untilDay)}',
              style: theme.textTheme.bodySmall?.copyWith(color: s.isFinished ? cs.outline : cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  onPressed: _busy ? null : _extend,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('4 more weeks'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _end,
                  icon: Icon(Icons.stop_circle_outlined, size: 18, color: cs.error),
                  label: Text(s.isFinished ? 'Remove' : 'End series', style: TextStyle(color: cs.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
