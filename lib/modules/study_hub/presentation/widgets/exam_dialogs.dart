import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/study_hub/domain/exams/exam_models.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// `yyyy-MM-dd` for a date.
String examDayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "12 Mar 2026".
String formatExamDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Colour for how close an exam is.
Color examUrgencyColor(ColorScheme cs, ExamUrgency u) => switch (u) {
      ExamUrgency.passed => cs.outline,
      ExamUrgency.today || ExamUrgency.critical => cs.error,
      ExamUrgency.soon => const Color(0xFFEF6C00),
      ExamUrgency.near => cs.primary,
      ExamUrgency.far => cs.secondary,
    };

/// Create (exam == null) or edit an exam.
Future<void> showExamEditor(BuildContext context, {StudyExam? exam, String? subject}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext c) => _ExamEditor(exam: exam, subject: subject),
    );

class _ExamEditor extends ConsumerStatefulWidget {
  const _ExamEditor({this.exam, this.subject});
  final StudyExam? exam;
  final String? subject;

  @override
  ConsumerState<_ExamEditor> createState() => _ExamEditorState();
}

class _ExamEditorState extends ConsumerState<_ExamEditor> {
  late final TextEditingController _subject =
      TextEditingController(text: widget.exam?.subject ?? widget.subject ?? '');
  late final TextEditingController _title =
      TextEditingController(text: widget.exam?.title ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.exam?.notes ?? '');
  late DateTime? _date = widget.exam?.date;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 14)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'EXAM DATE',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_subject.text.trim().isEmpty) {
      setState(() => _error = 'Enter a subject.');
      return;
    }
    if (_date == null) {
      setState(() => _error = 'Choose the exam date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(examRepositoryProvider).saveExam(
            id: widget.exam?.id,
            subject: _subject.text,
            title: _title.text,
            day: examDayKey(_date!),
            notes: _notes.text,
          );
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> subjects =
        ref.watch(subjectSuggestionsProvider).asData?.value ?? const <String>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.exam == null ? 'Add exam' : 'Edit exam',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: _subject,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
            ),
            if (subjects.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final String s in subjects.take(8))
                    ActionChip(label: Text(s), onPressed: () => setState(() => _subject.text = s)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Exam name (optional)',
                hintText: 'e.g. Midterm, Paper 1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(_date == null ? 'Choose exam date' : formatExamDate(_date!)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(widget.exam == null ? 'Add exam' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The checklist of one subject's syllabus: tick topics, add, paste, import.
Future<void> showSyllabusSheet(BuildContext context, String subject) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext c) => _SyllabusSheet(subject: subject),
    );

class _SyllabusSheet extends ConsumerStatefulWidget {
  const _SyllabusSheet({required this.subject});
  final String subject;

  @override
  ConsumerState<_SyllabusSheet> createState() => _SyllabusSheetState();
}

class _SyllabusSheetState extends ConsumerState<_SyllabusSheet> {
  final TextEditingController _add = TextEditingController();

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _addOne() async {
    final String t = _add.text.trim();
    if (t.isEmpty) return;
    final int n = await ref.read(examRepositoryProvider).addTopics(widget.subject, <String>[t]);
    _add.clear();
    if (n == 0 && mounted) _toast('That topic is already on the list');
  }

  Future<void> _paste() async {
    final TextEditingController c = TextEditingController();
    final String? text = await showDialog<String>(
      context: context,
      builder: (BuildContext d) => AlertDialog(
        title: const Text('Paste topics'),
        content: TextField(
          controller: c,
          autofocus: true,
          minLines: 6,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'One topic per line.\nNumbers and bullets are removed.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('Add')),
        ],
      ),
    );
    c.dispose();
    if (text == null || !mounted) return;
    final List<String> topics = parseTopicLines(text);
    final int n = await ref.read(examRepositoryProvider).addTopics(widget.subject, topics);
    if (mounted) _toast(n == 0 ? 'Nothing new to add' : 'Added $n ${n == 1 ? 'topic' : 'topics'}');
  }

  Future<void> _import() async {
    final repo = ref.read(examRepositoryProvider);
    final List<String> found = await repo.topicsFromSessions(widget.subject);
    if (!mounted) return;
    if (found.isEmpty) {
      _toast('No new topics found in your planned sessions');
      return;
    }
    final int n = await repo.addTopics(widget.subject, found);
    if (mounted) _toast('Imported $n ${n == 1 ? 'topic' : 'topics'} from your sessions');
  }

  Future<void> _rename(SyllabusTopic t) async {
    final TextEditingController c = TextEditingController(text: t.title);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext d) => AlertDialog(
        title: const Text('Rename topic'),
        content: TextField(controller: c, autofocus: true),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('Save')),
        ],
      ),
    );
    c.dispose();
    if (name != null) await ref.read(examRepositoryProvider).renameTopic(t.id, name);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<SubjectSyllabus> all =
        ref.watch(syllabiProvider).asData?.value ?? const <SubjectSyllabus>[];
    final SubjectSyllabus? syl = all
        .where((SubjectSyllabus s) => s.subject.toLowerCase() == widget.subject.trim().toLowerCase())
        .firstOrNull;
    final List<SyllabusTopic> topics = syl?.topics ?? const <SyllabusTopic>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext c, ScrollController scroll) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('${widget.subject} syllabus',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        Text(
                          topics.isEmpty ? 'No topics yet' : '${syl!.done} of ${syl.total} done · ${syl.percent}%',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(tooltip: 'Paste a list', icon: const Icon(Icons.content_paste), onPressed: _paste),
                  IconButton(tooltip: 'Import from my sessions', icon: const Icon(Icons.download_outlined), onPressed: _import),
                ],
              ),
            ),
            if (topics.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  value: syl!.fraction,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: TextField(
                controller: _add,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addOne(),
                decoration: InputDecoration(
                  hintText: 'Add a topic',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _addOne),
                ),
              ),
            ),
            Expanded(
              child: topics.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Add the chapters or topics you need to cover. Tick them off as you finish, '
                          'and the countdown will tell you how many topics per day you need.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scroll,
                      itemCount: topics.length,
                      itemBuilder: (BuildContext c, int i) {
                        final SyllabusTopic t = topics[i];
                        return Dismissible(
                          key: ValueKey<String>(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: theme.colorScheme.errorContainer,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
                          ),
                          onDismissed: (_) => ref.read(examRepositoryProvider).deleteTopic(t.id),
                          child: CheckboxListTile(
                            value: t.done,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? v) => ref.read(examRepositoryProvider).setTopicDone(t.id, v ?? false),
                            title: GestureDetector(
                              onLongPress: () => _rename(t),
                              child: Text(
                                t.title,
                                style: TextStyle(
                                  decoration: t.done ? TextDecoration.lineThrough : null,
                                  color: t.done ? theme.colorScheme.onSurfaceVariant : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
