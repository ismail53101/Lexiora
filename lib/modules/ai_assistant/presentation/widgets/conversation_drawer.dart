import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';

/// The ChatGPT-style side drawer: search, new chat, student projects, and
/// chronological recent conversations with rename/delete actions.
class ConversationDrawer extends ConsumerStatefulWidget {
  const ConversationDrawer({super.key});

  @override
  ConsumerState<ConversationDrawer> createState() => _ConversationDrawerState();
}

class _ConversationDrawerState extends ConsumerState<ConversationDrawer> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? currentId = ref.watch(currentConversationIdProvider);
    final List<AiConversationSummary> conversations =
        ref.watch(aiConversationsProvider).maybeWhen(
              data: (List<AiConversationSummary> c) => c,
              orElse: () => const <AiConversationSummary>[],
            );
    final List<AiConversationSummary> recents =
        List<AiConversationSummary>.of(conversations)
          ..sort((AiConversationSummary a, AiConversationSummary b) =>
              b.conversation.updatedAt.compareTo(a.conversation.updatedAt));

    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: <Widget>[
                  Text('Chats', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: 'New chat',
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      ref.read(aiChatControllerProvider.notifier).newChat();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _search,
                onChanged: (String v) =>
                    ref.read(aiSearchQueryProvider.notifier).set(v),
                decoration: InputDecoration(
                  hintText: 'Search chats',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: <Widget>[
                  _SectionHeader(
                    title: 'Projects',
                    action: IconButton(
                      tooltip: 'Add subject project',
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _openProjects(context),
                    ),
                  ),
                  FutureBuilder<List<SubjectUsage>>(
                    future: sl<StudyHubRepository>().allSubjectsWithUsage(
                      includeArchived: false,
                    ),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<SubjectUsage>> snapshot) {
                      final List<SubjectUsage> projects =
                          snapshot.data ?? const <SubjectUsage>[];
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          projects.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: LinearProgressIndicator(minHeight: 2),
                        );
                      }
                      if (projects.isEmpty) {
                        return _EmptySidebarRow(
                          icon: Icons.create_new_folder_outlined,
                          label: 'Add a subject project',
                          onTap: () => _openProjects(context),
                        );
                      }
                      return Column(
                        children: <Widget>[
                          for (final SubjectUsage project in projects)
                            _ProjectRow(
                              project: project,
                              onTap: () => _openProjects(context),
                            ),
                        ],
                      );
                    },
                  ),
                  _SectionHeader(title: 'Recents'),
                  if (recents.isEmpty)
                    const _EmptySidebarRow(
                      icon: Icons.chat_bubble_outline,
                      label: 'No chats yet',
                    )
                  else
                    for (final AiConversationSummary summary in recents)
                      _ConversationRow(
                        summary: summary,
                        active: summary.conversation.id == currentId,
                        onTap: () {
                          ref
                              .read(aiChatControllerProvider.notifier)
                              .openConversation(summary.conversation.id);
                          Navigator.of(context).pop();
                        },
                        onRename: () =>
                            _rename(context, summary.conversation),
                        onDelete: () => _delete(
                          context,
                          summary.conversation.id,
                          summary.conversation.id == currentId,
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProjects(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(AppRoutes.studyHubSubjects);
  }

  Future<void> _rename(BuildContext context, AiConversation c) async {
    final TextEditingController controller =
        TextEditingController(text: c.title);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Rename chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (String v) => Navigator.of(context).pop(v),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(aiRepositoryProvider).renameConversation(c.id, name);
    }
  }

  Future<void> _delete(BuildContext context, String id, bool active) async {
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Delete chat?'),
            content: const Text('This conversation will be permanently removed.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await ref.read(aiRepositoryProvider).deleteConversation(id);
    if (active) ref.read(aiChatControllerProvider.notifier).newChat();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project, required this.onTap});

  final SubjectUsage project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = project.hasColor
        ? project.subject!.colorValue
        : theme.colorScheme.primary;
    return ListTile(
      dense: true,
      leading: Icon(Icons.folder_outlined, color: color),
      title: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${project.sessionCount} learning session${
            project.sessionCount == 1 ? '' : 's'}',
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

class _EmptySidebarRow extends StatelessWidget {
  const _EmptySidebarRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.summary,
    required this.active,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final AiConversationSummary summary;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      selected: active,
      selectedTileColor:
          theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
      leading: const Icon(Icons.chat_bubble_outline),
      title: Text(
        summary.conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: summary.lastMessage == null
          ? null
          : Text(
              summary.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (String value) {
          if (value == 'rename') onRename();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (BuildContext context) =>
            const <PopupMenuEntry<String>>[
          PopupMenuItem<String>(value: 'rename', child: Text('Rename')),
          PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}
