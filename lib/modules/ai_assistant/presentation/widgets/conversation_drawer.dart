import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';

/// The ChatGPT-style side drawer: search, new chat, and the conversation list
/// with rename/delete.
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
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: conversations.isEmpty
                  ? Center(
                      child: Text('No chats yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    )
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (BuildContext context, int i) {
                        final AiConversationSummary s = conversations[i];
                        final bool active = s.conversation.id == currentId;
                        return ListTile(
                          selected: active,
                          selectedTileColor: theme
                              .colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(s.conversation.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: s.lastMessage == null
                              ? null
                              : Text(s.lastMessage!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                          onTap: () {
                            ref
                                .read(aiChatControllerProvider.notifier)
                                .openConversation(s.conversation.id);
                            Navigator.of(context).pop();
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (String v) {
                              if (v == 'rename') {
                                _rename(context, s.conversation);
                              } else if (v == 'delete') {
                                _delete(context, s.conversation.id, active);
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                  value: 'rename', child: Text('Rename')),
                              PopupMenuItem<String>(
                                  value: 'delete', child: Text('Delete')),
                            ],
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
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save')),
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
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await ref.read(aiRepositoryProvider).deleteConversation(id);
    if (active) ref.read(aiChatControllerProvider.notifier).newChat();
  }
}
