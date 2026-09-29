import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_project.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';

/// The ChatGPT-style side drawer, matching the reference layout:
///
///   Chats header (+ new chat) → search bar → **Projects** (expandable,
///   conversational — each project contains a "New chat" action and its
///   conversations) → **Recents** (real conversations only, newest first).
///
/// The search field is a *mode*: while text is entered it shows only results
/// (projects and chats in separate groups) and no Recent item is created —
/// clearing it restores the normal Projects + Recents view.
class ConversationDrawer extends ConsumerStatefulWidget {
  const ConversationDrawer({super.key});

  @override
  ConsumerState<ConversationDrawer> createState() => _ConversationDrawerState();
}

class _ConversationDrawerState extends ConsumerState<ConversationDrawer> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// Expanded project ids. null = default expansion (projects with an
  /// expanded memory start from a sensible default: first project open).
  final Set<String> _expanded = <String>{};

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final String? currentId = ref.watch(currentConversationIdProvider);
    final String query = ref.watch(aiSearchQueryProvider).trim();
    final bool searching = query.isNotEmpty;
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
    // Only conversations that actually contain messages are real history —
    // an empty shell (created but never chatted in) stays invisible in
    // Recents and inside projects until the first message lands.
    final List<AiConversationSummary> realConversations = conversations
        .where((AiConversationSummary s) => s.messageCount > 0)
        .toList(growable: false);
    final Map<String, List<AiConversationSummary>> byProject =
        <String, List<AiConversationSummary>>{};
    for (final AiConversationSummary s in realConversations) {
      final String? pid = s.conversation.projectId;
      if (pid != null) {
        (byProject[pid] ??= <AiConversationSummary>[]).add(s);
      }
    }

    // Auto-expand the project that contains the active conversation so the
    // user always sees where they are when they open the drawer.
    if (currentId != null) {
      for (final MapEntry<String, List<AiConversationSummary>> e
          in byProject.entries) {
        if (e.value.any((AiConversationSummary s) =>
            s.conversation.id == currentId)) {
          _expanded.add(e.key);
        }
      }
    }

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

            // ── Search field ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _search,
                focusNode: _searchFocus,
                onChanged: (String v) =>
                    ref.read(aiSearchQueryProvider.notifier).set(v),
                decoration: InputDecoration(
                  hintText: 'Search chats, projects…',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searching
                      ? IconButton(
                          tooltip: 'Clear search',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const Divider(height: 1),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: searching
                  ? _SearchResults(
                      query: query,
                      projects: projects,
                      conversations: realConversations,
                      currentConversationId: currentId,
                      onOpenConversation: _openConversation,
                      onRenameProject: _renameProject,
                      onDeleteProject: _deleteProject,
                      onRenameConversation: _renameConversation,
                      onDeleteConversation: _deleteConversation,
                      onOpenProject: _openProjectFromSearch,
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: <Widget>[
                        _ProjectsSection(
                          projects: projects,
                          conversationsByProject: byProject,
                          currentConversationId: currentId,
                          expanded: _expanded,
                          onToggleProject: _toggleProject,
                          onNewChatInProject: _newChatInProject,
                          onCreateProject: _createProject,
                          onRenameProject: _renameProject,
                          onDeleteProject: _deleteProject,
                          onOpenConversation: _openConversation,
                          onRenameConversation: _renameConversation,
                          onDeleteConversation: _deleteConversation,
                        ),
                        _RecentsSection(
                          conversations: realConversations
                              .where((AiConversationSummary s) =>
                                  s.conversation.projectId == null)
                              .toList(growable: false),
                          currentConversationId: currentId,
                          onOpenConversation: _openConversation,
                          onRenameConversation: _renameConversation,
                          onDeleteConversation: _deleteConversation,
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

  void _toggleProject(String id) => setState(() {
        if (!_expanded.remove(id)) _expanded.add(id);
      });

  void _openConversation(AiConversationSummary s) {
    // Search text must never leak into the drawer state once a chat is opened.
    _clearSearch();
    ref
        .read(aiChatControllerProvider.notifier)
        .openConversation(s.conversation.id);
    Navigator.of(context).pop();
  }

  void _newChatInProject(String projectId) {
    _clearSearch();
    ref.read(aiChatControllerProvider.notifier).newChatInProject(projectId);
    Navigator.of(context).pop();
  }

  void _clearSearch() {
    _search.clear();
    _searchFocus.unfocus();
    ref.read(aiSearchQueryProvider.notifier).set('');
  }

  /// A project result in search opens the project workspace: back to the
  /// normal Projects + Recents view with that project expanded, so the user
  /// sees its conversations and the inline "New chat" action.
  void _openProjectFromSearch(AiProjectSummary summary) {
    _clearSearch();
    setState(() => _expanded.add(summary.project.id));
  }

  // ── Project dialogs ───────────────────────────────────────────────────────

  Future<void> _createProject() async {
    final String? name = await _promptText(
      title: 'New project',
      label: 'Project name',
      confirmLabel: 'Create',
    );
    if (name == null || name.trim().isEmpty) return;
    final AiProject p = await ref.read(aiRepositoryProvider).createProject(name);
    if (mounted) setState(() => _expanded.add(p.id));
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
          'The project will be removed. Its conversation(s) are kept and return to Recents.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    if (mounted) setState(() => _expanded.remove(summary.project.id));
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
    await ref
        .read(aiRepositoryProvider)
        .deleteConversation(summary.conversation.id);
    if (active && mounted) ref.read(aiChatControllerProvider.notifier).newChat();
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
    required this.conversationsByProject,
    required this.currentConversationId,
    required this.expanded,
    required this.onToggleProject,
    required this.onNewChatInProject,
    required this.onCreateProject,
    required this.onRenameProject,
    required this.onDeleteProject,
    required this.onOpenConversation,
    required this.onRenameConversation,
    required this.onDeleteConversation,
  });

  final List<AiProjectSummary> projects;
  final Map<String, List<AiConversationSummary>> conversationsByProject;
  final String? currentConversationId;
  final Set<String> expanded;
  final void Function(String) onToggleProject;
  final void Function(String) onNewChatInProject;
  final Future<void> Function() onCreateProject;
  final Future<void> Function(AiProjectSummary) onRenameProject;
  final Future<void> Function(AiProjectSummary) onDeleteProject;
  final void Function(AiConversationSummary) onOpenConversation;
  final Future<void> Function(AiConversationSummary) onRenameConversation;
  final Future<void> Function(AiConversationSummary) onDeleteConversation;

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
                conversations: conversationsByProject[s.project.id] ??
                    const <AiConversationSummary>[],
                currentConversationId: currentConversationId,
                expanded: expanded.contains(s.project.id),
                onToggle: onToggleProject,
                onNewChat: onNewChatInProject,
                onRename: onRenameProject,
                onDelete: onDeleteProject,
                onOpenConversation: onOpenConversation,
                onRenameConversation: onRenameConversation,
                onDeleteConversation: onDeleteConversation,
              )),

        // ── "+ New project" row (reference layout) ─────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onCreateProject,
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 12, right: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.add, size: 20, color: scheme.onSurfaceVariant),
              ),
              title: Text('New project',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Divider(height: 1),
        ),
      ],
    );
  }
}

// ── Project colors ─────────────────────────────────────────────────────────

/// The vivid folder palette from the reference design: blue, purple, amber,
/// green, … Each project keeps a stable color derived from its id, so colors
/// never shuffle as projects are renamed, reordered, or recreated.
const List<Color> _kProjectFolderColors = <Color>[
  Color(0xFF42A5F5), // blue
  Color(0xFFAB7DF6), // purple
  Color(0xFFFBBF24), // amber
  Color(0xFF34D399), // green
  Color(0xFFF472B6), // pink
  Color(0xFF38BDF8), // sky
  Color(0xFFFB923C), // orange
  Color(0xFFA3E635), // lime
];

Color _projectFolderColor(String projectId) {
  // Simple, stable hash → palette index. Deterministic across sessions.
  int hash = 0;
  for (final int code in projectId.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return _kProjectFolderColors[hash % _kProjectFolderColors.length];
}

// ── Project tile (expandable, conversational) ────────────────────────────────

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.summary,
    required this.conversations,
    required this.currentConversationId,
    required this.expanded,
    required this.onToggle,
    required this.onNewChat,
    required this.onRename,
    required this.onDelete,
    required this.onOpenConversation,
    required this.onRenameConversation,
    required this.onDeleteConversation,
  });

  final AiProjectSummary summary;
  final List<AiConversationSummary> conversations;
  final String? currentConversationId;
  final bool expanded;
  final void Function(String) onToggle;
  final void Function(String) onNewChat;
  final Future<void> Function(AiProjectSummary) onRename;
  final Future<void> Function(AiProjectSummary) onDelete;
  final void Function(AiConversationSummary) onOpenConversation;
  final Future<void> Function(AiConversationSummary) onRenameConversation;
  final Future<void> Function(AiConversationSummary) onDeleteConversation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int count = conversations.length;

    return Column(
      children: <Widget>[
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 16, right: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(
            expanded ? Icons.folder_open_rounded : Icons.folder_rounded,
            size: 26,
            color: _projectFolderColor(summary.project.id),
          ),
          title: Text(summary.project.name,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            count == 1 ? '1 conversation' : '$count conversations',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          onTap: () => onToggle(summary.project.id),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedRotation(
                turns: expanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.chevron_right_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
              ),
              _DotMenuButton(
                tooltip: 'Project options',
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                      value: 'new_chat', child: Text('New chat in project')),
                  const PopupMenuItem<String>(
                      value: 'rename', child: Text('Rename')),
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
            ],
          ),
        ),
        // ── Conversational workspace: inline chat actions + conversations ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOutCubic,
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            children: <Widget>[
              // Start a new conversation directly inside the project.
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 12, right: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, size: 17, color: scheme.primary),
                  ),
                  title: Text('New chat',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: scheme.primary)),
                  onTap: () => onNewChat(summary.project.id),
                ),
              ),
              // Existing conversations that live in this project. Opening one
              // goes to the real AI chat — identical to any other conversation.
              for (final AiConversationSummary s in conversations)
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: _ConversationTile(
                    summary: s,
                    active: s.conversation.id == currentConversationId,
                    showProjectBadge: false,
                    onOpen: onOpenConversation,
                    onRename: onRenameConversation,
                    onDelete: onDeleteConversation,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Recents section ──────────────────────────────────────────────────────────

class _RecentsSection extends StatelessWidget {
  const _RecentsSection({
    required this.conversations,
    required this.currentConversationId,
    required this.onOpenConversation,
    required this.onRenameConversation,
    required this.onDeleteConversation,
  });

  /// Only real conversations outside every project — never search activity.
  final List<AiConversationSummary> conversations;
  final String? currentConversationId;
  final void Function(AiConversationSummary) onOpenConversation;
  final Future<void> Function(AiConversationSummary) onRenameConversation;
  final Future<void> Function(AiConversationSummary) onDeleteConversation;

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
          for (final AiConversationSummary s in conversations)
            _ConversationTile(
              summary: s,
              active: s.conversation.id == currentConversationId,
              showProjectBadge: true,
              leadingIcon: Icons.contact_support_outlined,
              onOpen: onOpenConversation,
              onRename: onRenameConversation,
              onDelete: onDeleteConversation,
            ),
      ],
    );
  }
}

// ── Conversation tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.summary,
    required this.active,
    required this.showProjectBadge,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    this.leadingIcon,
  });

  final AiConversationSummary summary;
  final bool active;
  final bool showProjectBadge;
  final void Function(AiConversationSummary) onOpen;
  final Future<void> Function(AiConversationSummary) onRename;
  final Future<void> Function(AiConversationSummary) onDelete;

  /// Optional leading-icon override (Recents uses the reference simple
  /// chat-bubble style); null keeps the default speech-bubble icon used by
  /// project chats and search results.
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      selected: active,
      selectedTileColor: scheme.secondaryContainer.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(leadingIcon ?? Icons.chat_bubble_outline_rounded, size: 20),
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
          const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (String v) {
          switch (v) {
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

// ── Search results mode ──────────────────────────────────────────────────────

/// Shown instead of Projects + Recents while a search query is active. Purely
/// a results view: nothing entered here is ever persisted as a Recent.
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.projects,
    required this.conversations,
    required this.currentConversationId,
    required this.onOpenConversation,
    required this.onOpenProject,
    required this.onRenameProject,
    required this.onDeleteProject,
    required this.onRenameConversation,
    required this.onDeleteConversation,
  });

  final String query;
  final List<AiProjectSummary> projects;
  final List<AiConversationSummary> conversations;
  final String? currentConversationId;
  final void Function(AiConversationSummary) onOpenConversation;
  final void Function(AiProjectSummary) onOpenProject;
  final Future<void> Function(AiProjectSummary) onRenameProject;
  final Future<void> Function(AiProjectSummary) onDeleteProject;
  final Future<void> Function(AiConversationSummary) onRenameConversation;
  final Future<void> Function(AiConversationSummary) onDeleteConversation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    if (projects.isEmpty && conversations.isEmpty) {
      return Center(
        child: Text(
          'No results for “$query”',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: <Widget>[
        if (projects.isNotEmpty) ...<Widget>[
          _SectionLabel(
              icon: Icons.folder_outlined,
              title: 'Projects',
              theme: theme,
              scheme: scheme),
          for (final AiProjectSummary p in projects)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 16, right: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              leading: Icon(
                Icons.folder_rounded,
                size: 26,
                color: _projectFolderColor(p.project.id),
              ),
              title: Text(p.project.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                p.conversationCount == 1
                    ? '1 conversation'
                    : '${p.conversationCount} conversations',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              // Project results open the project workspace (expanded inline
              // with its conversations + New chat action) — not a dead page.
              onTap: () => onOpenProject(p),
              trailing: _DotMenuButton(
                tooltip: 'Project options',
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                      value: 'rename', child: Text('Rename')),
                  const PopupMenuItem<String>(
                      value: 'delete', child: Text('Delete project')),
                ],
                onSelected: (String v) {
                  switch (v) {
                    case 'rename':
                      onRenameProject(p);
                    case 'delete':
                      onDeleteProject(p);
                  }
                },
              ),
            ),
        ],
        if (conversations.isNotEmpty) ...<Widget>[
          _SectionLabel(
              icon: Icons.schedule_rounded,
              title: 'Conversations',
              theme: theme,
              scheme: scheme),
          for (final AiConversationSummary s in conversations)
            _ConversationTile(
              summary: s,
              active: s.conversation.id == currentConversationId,
              showProjectBadge: false,
              onOpen: onOpenConversation,
              onRename: onRenameConversation,
              onDelete: onDeleteConversation,
            ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.theme,
    required this.scheme,
  });

  final IconData icon;
  final String title;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(title,
              style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700)),
        ],
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
