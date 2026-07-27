import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/study_hub/domain/entities/session_filter.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_template.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/session_tile.dart';

/// Advanced Search & Filter for study sessions — instant, indexed, composable.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _field = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(sessionFilterProvider.notifier).reset());
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  SessionFilterNotifier get _notifier =>
      ref.read(sessionFilterProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final SessionFilter filter = ref.watch(sessionFilterProvider);
    final AsyncValue<List<StudyTask>> results =
        ref.watch(searchResultsProvider);
    final List<String> subjects = ref.watch(subjectSuggestionsProvider).maybeWhen(
          data: (List<String> s) => s,
          orElse: () => const <String>[],
        );
    final List<String> topics = ref.watch(topicSuggestionsProvider).maybeWhen(
          data: (List<String> s) => s,
          orElse: () => const <String>[],
        );
    final List<StudyTemplate> templates =
        ref.watch(studyTemplatesProvider).maybeWhen(
              data: (List<StudyTemplate> t) => t,
              orElse: () => const <StudyTemplate>[],
            );
    final String q = filter.query.trim().toLowerCase();
    final List<StudyTemplate> matchingTemplates = q.isEmpty
        ? const <StudyTemplate>[]
        : templates
            .where((StudyTemplate t) => t.name.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filter')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _field,
              textInputAction: TextInputAction.search,
              onChanged: _notifier.setQuery,
              decoration: InputDecoration(
                hintText: 'Search subject, topic, notes, template…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _field.clear();
                          _notifier.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                _menuChip<SessionStatusFilter>(
                  label: 'Status',
                  value: filter.status,
                  isDefault: filter.status == SessionStatusFilter.all,
                  options: SessionStatusFilter.values,
                  labelOf: (SessionStatusFilter v) => v.label,
                  onSelected: (SessionStatusFilter v) =>
                      _notifier.set(filter.copyWith(status: v)),
                ),
                _menuChip<PriorityFilter>(
                  label: 'Priority',
                  value: filter.priority,
                  isDefault: filter.priority == PriorityFilter.any,
                  options: PriorityFilter.values,
                  labelOf: (PriorityFilter v) => v.label,
                  onSelected: (PriorityFilter v) =>
                      _notifier.set(filter.copyWith(priority: v)),
                ),
                _menuChip<DateScope>(
                  label: 'Date',
                  value: filter.dateScope,
                  isDefault: filter.dateScope == DateScope.all,
                  options: DateScope.values,
                  labelOf: (DateScope v) => v.label,
                  onSelected: _onDateScope,
                ),
                _stringChip(
                  label: 'Subject',
                  value: filter.subject,
                  options: subjects,
                  onSelected: (String? v) =>
                      _notifier.set(filter.copyWith(subject: v, clearSubject: v == null)),
                ),
                _stringChip(
                  label: 'Topic',
                  value: filter.topic,
                  options: topics,
                  onSelected: (String? v) =>
                      _notifier.set(filter.copyWith(topic: v, clearTopic: v == null)),
                ),
                if (filter.hasActiveFilters || filter.query.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ActionChip(
                      avatar: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear'),
                      onPressed: () {
                        _field.clear();
                        _notifier.reset();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => const Center(child: Text('Search failed')),
              data: (List<StudyTask> list) {
                if (list.isEmpty && matchingTemplates.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message: 'Try another search or adjust your filters.',
                  );
                }
                return ListView(
                  children: <Widget>[
                    if (matchingTemplates.isNotEmpty) ...<Widget>[
                      const _Header('Templates'),
                      for (final StudyTemplate t in matchingTemplates)
                        ListTile(
                          leading: const Icon(Icons.event_repeat),
                          title: Text(t.name),
                          subtitle: Text('${t.itemCount} items'),
                        ),
                      const Divider(),
                    ],
                    if (list.isNotEmpty) const _Header('Sessions'),
                    for (final StudyTask t in list)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(t.day,
                                style: Theme.of(context).textTheme.labelSmall),
                            SessionTile(task: t),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDateScope(DateScope v) async {
    final SessionFilter filter = ref.read(sessionFilterProvider);
    if (v == DateScope.custom) {
      final DateTimeRange? range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(DateTime.now().year - 2),
        lastDate: DateTime(DateTime.now().year + 2),
      );
      if (range == null) return;
      _notifier.set(filter.copyWith(
          dateScope: DateScope.custom,
          customStart: range.start,
          customEnd: range.end));
    } else {
      _notifier.set(filter.copyWith(dateScope: v));
    }
  }

  Widget _menuChip<T>({
    required String label,
    required T value,
    required bool isDefault,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<T>(
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<T>>[
          for (final T o in options)
            PopupMenuItem<T>(value: o, child: Text(labelOf(o))),
        ],
        child: Chip(
          label: Text(isDefault ? label : '$label: ${labelOf(value)}'),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: isDefault
              ? null
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  Widget _stringChip({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        onSelected: (String v) => onSelected(v == '' ? null : v),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: '', child: Text('Any')),
          for (final String o in options)
            PopupMenuItem<String>(value: o, child: Text(o)),
        ],
        child: Chip(
          label: Text(value == null ? label : '$label: $value'),
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
          backgroundColor: value == null
              ? null
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}
