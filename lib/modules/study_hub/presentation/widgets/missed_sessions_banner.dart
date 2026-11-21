import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';

/// Shows unfinished sessions from previous days and lets the user choose
/// exactly where to reschedule them.
class MissedSessionsBanner extends ConsumerStatefulWidget {
  const MissedSessionsBanner({super.key, required this.day});
  final String day;

  @override
  ConsumerState<MissedSessionsBanner> createState() =>
      _MissedSessionsBannerState();
}

class _MissedSessionsBannerState extends ConsumerState<MissedSessionsBanner> {
  bool _dismissed = false;
  bool _busy = false;

  Future<void> _moveToChosenDay(List<StudyTask> missed) async {
    final DateTime today = DateTime.now();
    final DateTime? target = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Move missed sessions',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the day where you want these sessions to be planned.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.today_outlined),
                  title: const Text('Today'),
                  onTap: () => Navigator.of(sheetContext).pop(
                    DateTime(today.year, today.month, today.day),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Tomorrow'),
                  onTap: () => Navigator.of(sheetContext).pop(
                    DateTime(today.year, today.month, today.day + 1),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Choose another date'),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: sheetContext,
                      initialDate:
                          DateTime(today.year, today.month, today.day + 1),
                      firstDate:
                          DateTime(today.year, today.month, today.day),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && sheetContext.mounted) {
                      Navigator.of(sheetContext).pop(picked);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (target == null) return;

    setState(() => _busy = true);
    try {
      final String toDay = dayKey(target);
      final int n = await ref
          .read(studyHubRepositoryProvider)
          .moveSessionsToDay(tasks: missed, toDay: toDay);
      ref.invalidate(missedSessionsProvider);
      if (!mounted) return;

      final String label = toDay == dayKey(today)
          ? 'today'
          : toDay ==
                  dayKey(DateTime(today.year, today.month, today.day + 1))
              ? 'tomorrow'
              : '${target.day}/${target.month}/${target.year}';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Moved $n ${n == 1 ? 'session' : 'sessions'} to $label',
            ),
          ),
        );
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn’t move them: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || widget.day != dayKey(DateTime.now())) {
      return const SizedBox.shrink();
    }

    final List<StudyTask> missed =
        ref.watch(missedSessionsProvider).asData?.value ??
            const <StudyTask>[];
    if (missed.isEmpty) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final List<String> names = <String>{
      for (final StudyTask t in missed) t.displaySubject,
    }.toList();
    final String preview = names.length <= 2
        ? names.join(', ')
        : '${names.take(2).join(', ')} +${names.length - 2}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cs.errorContainer.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.history, color: cs.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${missed.length} ${missed.length == 1 ? 'session' : 'sessions'} missed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: Text(
                preview,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed:
                      _busy ? null : () => setState(() => _dismissed = true),
                  child: const Text('Not now'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _busy ? null : () => _moveToChosenDay(missed),
                  child: Text(_busy ? 'Moving…' : 'Move to…'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
