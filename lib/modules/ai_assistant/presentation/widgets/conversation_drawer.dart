import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_project.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';

/// The ChatGPT-style side drawer: search, new chat, a **Projects** section
/// (named folders grouping conversations, with inline 3-dot actions and a
/// "New project" row) followed by a **Recents** section listing every chat,
/// newest first. Everything scrolls together; the search filters both lists.
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
    final ColorScheme scheme = theme.colorScheme;
    final String? currentId = ref.watch(currentConversationIdProvider);
    final String searchQuery = ref.watch(aiSearchQueryProvider);
    final List<AiConversationSummary> conversations =
        ref.watch(aiConversationsProvider).maybeWhen(
              data: (List<AiConversationSummary> c) => c,
              orElse: () => const <AiConversationSummary>[],
            );
    final List<AiProjectSummary> projects =
        ref.watch(aiProjectsProvider).maybeWhen(
              data: (List<AiProjectSummary> p) => p,
              orElse: () => const <AiProjectSummary>[],
            );
    final Map<String, AiProjectSummary> projectsById =
        <String, AiProjectSummary>{
      for (final AiProjectSummary p in projects) p.project.id: p,
    };

    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Header: title + new chat ──────────────────────────────────
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

            // ── Search: filters projects AND conversations ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _search,
                onChanged: (String v) =>
                    ref.read(aiSearchQueryProvider.notifier).set(v),
                decoration: InputDecoration(
                  hintText: 'Search chats, projects…',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const Divider(height: 1),

            // ── Projects + Recents: one smooth-scrolling surface ──────────
            Expanded(
              child: (projects.isEmpty && conversations.isEmpty)
                  ? Center(
                      child: Text(
                        searchQuery.trim().isEmpty
                            ? 'No chats yet'
                            : 'No matches for “${searchQuery.trim()}”',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: <Widget>[
                        _ProjectsSection(
                          projects: projects,
                          onCreateProject: _createProject,
                          onRenameProject: _renameProject,
                          onDeleteProject: _deleteProject,
                          onOpenProject: _openProject,
                          onNewChatInProject: _newChatInProject,
                        ),
                        _RecentsSection(
                          conversations: conversations,
                          projects: projects,
                          projectsById: projectsById,
                          currentConversationId: currentId,
                          onOpenConversation: _openConversation,
                          onRenameConversation: _renameConversation,
                          onDeleteConversation: _deleteConversation,
                          onPickProject: _pickProject,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _openConversation(AiConversationSummary s) {
    ref.read(aiChatControllerProvider.notifier).openConversation(s.conversation.id);
    Navigator.of(context).pop();
  }

  void _newChatInProject(String projectId) {
    ref.read(aiChatControllerProvider.notifier).newChatInProject(projectId);
    Navigator.of(context).pop();
  }

  /// Opens a project: expands it to show the conversations filed inside,
  /// ChatGPT-style, without leaving the drawer.
  Future<void> _openProject(AiProjectSummary summary) async {
    await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => _ProjectConversationsPage(
              summary: summary,
              onOpenConversation: _openConversation,
              onRenameConversation: _renameConversation,
              onDeleteConversation: _deleteConversation,
            ),
          ),
        );
  }

  /// Opens the project picker for a conversation, then moves it.
  Future<void> _pickProject(AiConversation c) async {
    final List<AiProjectSummary> projects =
        ref.read(aiProjectsProvider).maybeWhen(
              data: (List<AiProjectSummary> p) => p,
              orElse: () => const <AiProjectSummary>[],
            );
    if (projects.isEmpty) {
      final bool create = await _confirmDelete(
        title: 'No projects yet',
        message: 'Create a project to group this chat with related ones?',
        confirmLabel: 'Create project',
      );
      if (create) {
        await _createProject();
        final List<AiProjectSummary> now =
            ref.read(aiProjectsProvider).maybeWhen(
                  data: (List<AiProjectSummary> p) => p,
                  orElse: () => const <AiProjectSummary>[],
                );
        if (now.isNotEmpty && c.projectId == null) {
          await ref
              .read(aiRepositoryProvider)
              .setConversationProject(c.id, now.first.project.id);
        }
      }
      return;
    }
    final String? chosen = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text('Move to project'),
        children: <Widget>[
          if (c.projectId != null)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(''),
              child: const ListTile(
                leading: Icon(Icons.folder_off_outlined),
                title: Text('Remove from project'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          for (final AiProjectSummary p in projects)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(p.project.id),
              child: ListTile(
                leading: Icon(Icons.folder_rounded,
                    color: p.project.id == c.projectId
                        ? Theme.of(context).colorScheme.primary
                        : null),
                title: Text(p.project.name),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
    if (chosen == null) return; // cancelled
    await ref
        .read(aiRepositoryProvider)
        .setConversationProject(c.id, chosen.isEmpty ? null : chosen);
  }

  // ── Project dialogs ───────────────────────────────────────────────────────

  Future<void> _createProject() async {
    final String? name = await _promptText(
      title: 'New project',
      label: 'Project name',
      confirmLabel: 'Create',
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(aiRepositoryProvider).createProject(name);
  }

  Future<void> _renameProject(AiProjectSummary summary) async {
    final String? name = await _promptText(
      title: 'Rename project',
      label: 'Project name',
      initial: summary.project.name,
      confirmLabel: 'Save',
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(aiRepositoryProvider).renameProject(summary.project.id, name);
  }

  Future<void> _deleteProject(AiProjectSummary summary) async {
    final bool ok = await _confirmDelete(
      title: 'Delete “${summary.project.name}”?',
      message:
          'The project will be removed. Its ${summary.conversationCount} conversation(s) are kept and return to Recents.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    await ref.read(aiRepositoryProvider).deleteProject(summary.project.id);
  }

  // ── Conversation dialogs ──────────────────────────────────────────────────

  Future<void> _renameConversation(AiConversationSummary summary) async {
    final String? name = await _promptText(
      title: 'Rename chat',
      label: 'Title',
      initial: summary.conversation.title,
      confirmLabel: 'Save',
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(aiRepositoryProvider)
        .renameConversation(summary.conversation.id, name);
  }

  Future<void> _deleteConversation(AiConversationSummary summary) async {
    final bool active =
        summary.conversation.id == ref.read(currentConversationIdProvider);
    final bool ok = await _confirmDelete(
      title: 'Delete chat?',
      message: 'This conversation will be permanently removed.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    await ref.read(aiRepositoryProvider).deleteConversation(summary.conversation.id);
    if (active) ref.read(aiChatControllerProvider.notifier).newChat();
  }

  // ── Shared dialogs ────────────────────────────────────────────────────────

  Future<String?> _promptText({
    required String title,
    required String label,
    String? initial,
    required String confirmLabel,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: initial);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (String v) => Navigator.of(context).pop(v),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(confirmLabel)),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel)),
              ],
            ),
          ) ??
          false;
}

// ── Projects section ─────────────────────────────────────────────────────────

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({
    required this.projects,
    required this.onCreateProject,
    required this.onRenameProject,
    required this.onDeleteProject,
    required this.onOpenProject,
    required this.onNewChatInProject,
  });

  final List<AiProjectSummary> projects;
  final Future<void> Function() onCreateProject;
  final Future<void> Function(AiProjectSummary) onRenameProject;
  final Future<void> Function(AiProjectSummary) onDeleteProject;
  final Future<void> Function(AiProjectSummary) onOpenProject;
  final void Function(String projectId) onNewChatInProject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
          child: Row(
            children: <Widget>[
              Icon(Icons.folder_outlined,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Projects',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                tooltip: 'New project',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 20),
                onPressed: onCreateProject,
              ),
            ],
          ),
        ),
        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              'Group related chats together',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
        else
          ...projects.map((AiProjectSummary s) => _ProjectTile(
                summary: s,
                onOpen: onOpenProject,
                onRename: onRenameProject,
                onDelete: onDeleteProject,
                onNewChat: onNewChatInProject,
              )),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Divider(height: 1),
        ),
      ],
    );
  }
}

// ── Project tile ─────────────────────────────────────────────────────────────

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.summary,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    required this.onNewChat,
  });

  final AiProjectSummary summary;
  final Future<void> Function(AiProjectSummary) onOpen;
  final Future<void> Function(AiProjectSummary) onRename;
  final Future<void> Function(AiProjectSummary) onDelete;
  final void Function(String projectId) onNewChat;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String subtitle = summary.conversationCount == 1
        ? '1 conversation'
        : '${summary.conversationCount} conversations';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(Icons.folder_rounded, size: 19, color: scheme.primary),
      ),
      title: Text(summary.project.name,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant)),
      onTap: () => onOpen(summary),
      trailing: _DotMenuButton(
        tooltip: 'Project options',
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
              value: 'new_chat', child: Text('New chat in project')),
          const PopupMenuItem<String>(value: 'rename', child: Text('Rename')),
          const PopupMenuItem<String>(
              value: 'delete', child: Text('Delete project')),
        ],
        onSelected: (String v) {
          switch (v) {
            case 'new_chat':
              onNewChat(summary.project.id);
            case 'rename':
              onRename(summary);
            case 'delete':
              onDelete(summary);
          }
        },
      ),
    );
  }
}

// ── Recents section ──────────────────────────────────────────────────────────

class _RecentsSection extends StatelessWidget {
  const _RecentsSection({
    required this.conversations,
    required this.projects,
    required this.projectsById,
    required this.currentConversationId,
    required this.onOpenConversation,
    required this.onRenameConversation,
    required this.onDeleteConversation,
    required this.onPickProject,
  });

  final List<AiConversationSummary> conversations;
  final List<AiProjectSummary> projects;
  final Map<String, AiProjectSummary> projectsById;
  final String? currentConversationId;
  final void Function(AiConversationSummary) onOpenConversation;
  final Future<void> Function(AiConversationSummary) onRenameConversation;
  final Future<void> Function(AiConversationSummary) onDeleteConversation;
  final Future<void> Function(AiConversation) onPickProject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: <Widget>[
              Icon(Icons.schedule_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Recents',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (conversations.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              'No conversations yet',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
        else
          ...conversations.map((AiConversationSummary s) => _ConversationTile(
                summary: s,
                active: s.conversation.id == currentConversationId,
                projectSummary: projectsById[s.conversation.projectId],
                hasProjects: projects.isNotEmpty,
                onOpen: onOpenConversation,
                onRename: onRenameConversation,
                onDelete: onDeleteConversation,
                onPickProject: onPickProject,
              )),
      ],
    );
  }
}

// ── Conversation tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.summary,
    required this.active,
    required this.projectSummary,
    required this.hasProjects,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    required this.onPickProject,
  });

  final AiConversationSummary summary;
  final bool active;
  final AiProjectSummary? projectSummary;
  final bool hasProjects;
  final void Function(AiConversationSummary) onOpen;
  final Future<void> Function(AiConversationSummary) onRename;
  final Future<void> Function(AiConversationSummary) onDelete;
  final Future<void> Function(AiConversation) onPickProject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool hasProject = projectSummary != null;

    return ListTile(
      dense: true,
      selected: active,
      selectedTileColor: scheme.secondaryContainer.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: hasProject
          ? Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.folder_rounded,
                  size: 15, color: scheme.primary),
            )
          : const Icon(Icons.chat_bubble_outline_rounded, size: 20),
      title: Text(summary.conversation.title,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: summary.lastMessage == null
          ? null
          : Text(summary.lastMessage!,
              maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => onOpen(summary),
      trailing: _DotMenuButton(
        tooltip: 'Chat options',
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'rename', child: Text('Rename')),
          PopupMenuItem<String>(
              value: 'move',
              child: Text(projectSummary == null
                  ? 'Move to project'
                  : 'Move to another project')),
          const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (String v) {
          switch (v) {
            case 'rename':
              onRename(summary);
            case 'move':
              onPickProject(summary.conversation);
            case 'delete':
              onDelete(summary);
          }
        },
      ),
    );
  }
}

// ── Project detail page ──────────────────────────────────────────────────────

/// A lightweight page listing the conversations inside one project, with
/// "New chat in project" and per-chat rename/delete. Reached by tapping a
/// project in the drawer.
class _ProjectConversationsPage extends ConsumerWidget {
  const _ProjectConversationsPage({
    required this.summary,
    required this.onOpenConversation,
    required this.onRenameConversation,
    required this.onDeleteConversation,
  });

  final AiProjectSummary summary;
  final void Function(AiConversationSummary) onOpenConversation;
  final Future<void> Function(AiConversationSummary) onRenameConversation;
  final Future<void> Function(AiConversationSummary) onDeleteConversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String? currentId = ref.watch(currentConversationIdProvider);
    final List<AiConversationSummary> conversations =
        ref.watch(aiConversationsProvider).maybeWhen(
              data: (List<AiConversationSummary> c) => c,
              orElse: () => const <AiConversationSummary>[],
            );
    final List<AiConversationSummary> inside = conversations
        .where((AiConversationSummary s) =>
            s.conversation.projectId == summary.project.id)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.folder_rounded, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(summary.project.name,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: inside.isEmpty
          ? Center(
              child: Text(
                'No conversations in this project yet',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: inside.length,
              itemBuilder: (BuildContext context, int i) {
                final AiConversationSummary s = inside[i];
                return ListTile(
                  dense: true,
                  selected: s.conversation.id == currentId,
                  selectedTileColor:
                      scheme.secondaryContainer.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.only(left: 16, right: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  leading: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 20),
                  title: Text(s.conversation.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: s.lastMessage == null
                      ? null
                      : Text(s.lastMessage!,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.of(context).pop(); // close the project page
                    onOpenConversation(s);
                  },
                  trailing: _DotMenuButton(
                    tooltip: 'Chat options',
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                          value: 'rename', child: Text('Rename')),
                      const PopupMenuItem<String>(
                          value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (String v) {
                      switch (v) {
                        case 'rename':
                          onRenameConversation(s);
                        case 'delete':
                          onDeleteConversation(s);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ── 3-dot menu button ────────────────────────────────────────────────────────

class _DotMenuButton extends StatelessWidget {
  const _DotMenuButton({
    required this.itemBuilder,
    required this.onSelected,
    required this.tooltip,
  });

  final List<PopupMenuEntry<String>> Function(BuildContext) itemBuilder;
  final void Function(String) onSelected;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      icon: const Icon(Icons.more_vert_rounded, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onSelected: onSelected,
      itemBuilder: itemBuilder,
    );
  }
}
