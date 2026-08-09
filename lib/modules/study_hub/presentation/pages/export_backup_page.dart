import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/data/services/study_backup_service.dart';
import 'package:lexiora/modules/study_hub/data/services/study_export_service.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

enum _Scope { today, week, month, all, custom }

extension on _Scope {
  String get label => switch (this) {
        _Scope.today => 'Today',
        _Scope.week => 'This week',
        _Scope.month => 'This month',
        _Scope.all => 'All history',
        _Scope.custom => 'Custom range',
      };
}

class ExportBackupPage extends ConsumerStatefulWidget {
  const ExportBackupPage({super.key});

  @override
  ConsumerState<ExportBackupPage> createState() => _ExportBackupPageState();
}

class _ExportBackupPageState extends ConsumerState<ExportBackupPage> {
  _Scope _scope = _Scope.today;
  DateTimeRange? _custom;
  bool _busy = false;

  (String, String) _range() {
    final DateTime now = DateTime.now();
    switch (_scope) {
      case _Scope.today:
        return (todayKey(), todayKey());
      case _Scope.week:
        final DateTime s = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return (dayKey(s), dayKey(s.add(const Duration(days: 6))));
      case _Scope.month:
        return (dayKey(DateTime(now.year, now.month)),
            dayKey(DateTime(now.year, now.month + 1, 0)));
      case _Scope.all:
        return ('0000-01-01', '9999-12-31');
      case _Scope.custom:
        if (_custom == null) return (todayKey(), todayKey());
        return (dayKey(_custom!.start), dayKey(_custom!.end));
    }
  }

  String get _title => switch (_scope) {
        _Scope.today => 'Study plan ${todayKey()}',
        _Scope.week => 'Weekly study plan',
        _Scope.month => 'Monthly study plan',
        _Scope.all => 'Study history',
        _Scope.custom => 'Study plan',
      };

  Future<void> _export(ExportFormat format) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final (String, String) r = _range();
      final List<StudyTask> tasks = await ref
          .read(studyHubRepositoryProvider)
          .watchTasksInRange(r.$1, r.$2)
          .first;
      await ref
          .read(studyExportServiceProvider)
          .exportAndShare(title: _title, tasks: tasks, format: format);
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickCustom() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (range != null) {
      setState(() {
        _custom = range;
        _scope = _Scope.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Export & Backup')),
      body: ListView(
        children: <Widget>[
          SectionCard(
            icon: Icons.ios_share,
            title: 'Export Center',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Scope', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final _Scope s in _Scope.values)
                      ChoiceChip(
                        label: Text(s == _Scope.custom && _custom != null
                            ? '${dayKey(_custom!.start)} → ${dayKey(_custom!.end)}'
                            : s.label),
                        selected: _scope == s,
                        onSelected: (_) => s == _Scope.custom
                            ? _pickCustom()
                            : setState(() => _scope = s),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Format', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: <Widget>[
                    for (final ExportFormat f in ExportFormat.values)
                      FilledButton.tonalIcon(
                        onPressed: _busy ? null : () => _export(f),
                        icon: Icon(switch (f) {
                          ExportFormat.csv => Icons.grid_on,
                          ExportFormat.pdf => Icons.picture_as_pdf_outlined,
                          ExportFormat.xlsx => Icons.table_chart_outlined,
                        }),
                        label: Text(f.label),
                      ),
                  ],
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.backup_outlined,
            title: 'Backup & Restore',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'A backup includes your sessions, breaks, goals, templates and '
                  'subject colours. Cloud Sync is coming; backups are local for now.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _busy ? null : _backup,
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Create & share backup'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _restore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore backup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _backup() async {
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(studyBackupServiceProvider)
          .backupAndShare(ref.read(studyHubRepositoryProvider));
      messenger.showSnackBar(const SnackBar(content: Text('Backup created')));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final StudyBackupService service = ref.read(studyBackupServiceProvider);
    final List<BackupFile> backups = await service.listBackups();
    if (!mounted) return;
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No local backups found. Create one first.')));
      return;
    }
    final BackupFile? chosen = await showModalBottomSheet<BackupFile>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => ListView(
        shrinkWrap: true,
        children: <Widget>[
          const ListTile(title: Text('Choose a backup to restore')),
          for (final BackupFile b in backups)
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(b.name),
              subtitle: Text('${b.savedAt}'.split('.').first),
              onTap: () => Navigator.of(context).pop(b),
            ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Restore backup?'),
            content: const Text(
                'This replaces your current Study Planner data with the backup. '
                'This cannot be undone.'),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Restore')),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await service.restore(ref.read(studyHubRepositoryProvider), chosen.path);
      messenger.showSnackBar(const SnackBar(content: Text('Backup restored')));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
