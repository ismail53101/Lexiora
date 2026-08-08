import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/app_bottom_nav.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_markdown.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/chat_composer.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/conversation_drawer.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/message_bubble.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/typing_indicator.dart';

/// The AI Assistant chat screen — a ChatGPT-style interface with a conversation
/// drawer, streaming replies, and offline history.
class AiChatPage extends ConsumerWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool configured = ref.watch(aiConfiguredProvider);
    final String? currentId = ref.watch(currentConversationIdProvider);
    final String title = ref.watch(aiConversationsProvider).maybeWhen(
          data: (List<AiConversationSummary> list) {
            for (final AiConversationSummary s in list) {
              if (s.conversation.id == currentId) return s.conversation.title;
            }
            return 'AI Assistant';
          },
          orElse: () => 'AI Assistant',
        );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            Icon(Icons.auto_awesome_rounded,
                size: 18, color: Theme.of(context).colorScheme.tertiary),
          ],
        ),
        actions: <Widget>[
          _HeaderActions(currentId: currentId),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const ConversationDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: !configured
                ? _notConfigured(context)
                : (currentId == null
                    ? const _Welcome()
                    : _MessageList(conversationId: currentId)),
          ),
          ChatComposer(enabled: configured),
        ],
      ),
    );
  }

  Widget _notConfigured(BuildContext context) => const EmptyState(
        icon: Icons.key_off_outlined,
        title: 'AI Assistant not configured',
        message:
            'An API key is required. Build with:\n\nflutter run --dart-define=SAPIORA_AI_API_KEY=your_key\n\nYour key is never stored or logged.',
      );
}

/// ChatGPT-style header actions: a small dark pill holding an edit
/// ("new chat") icon and — once a conversation exists — an overflow menu
/// for renaming or deleting it. Replaces the old single "add_comment_outlined"
/// button.
class _HeaderActions extends ConsumerWidget {
  const _HeaderActions({required this.currentId});

  final String? currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: 'New chat',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_square, size: 20),
            onPressed: () =>
                ref.read(aiChatControllerProvider.notifier).newChat(),
          ),
          if (currentId != null)
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (String value) async {
                final String id = currentId!;
                if (value == 'rename') {
                  await _rename(context, ref, id);
                } else if (value == 'delete') {
                  await _delete(context, ref, id);
                }
              },
              itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Rename'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete chat'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, String id) async {
    final TextEditingController controller = TextEditingController();
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
      await ref.read(aiRepositoryProvider).renameConversation(id, name);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Delete chat?'),
            content:
                const Text('This conversation will be permanently removed.'),
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
    ref.read(aiChatControllerProvider.notifier).newChat();
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              // The app's real Sapiora logo, same footprint (88x88, 22
              // radius) as the placeholder book icon it replaces.
              child: Image.asset(
                'assets/branding/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hi, how can I assist you?',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Start a conversation — explanations, summaries, code, '
              'tables and math are all supported.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends ConsumerWidget {
  const _MessageList({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AiMessage>> async =
        ref.watch(aiMessagesProvider(conversationId));
    final bool streaming =
        ref.watch(aiChatControllerProvider.select((AiChatState s) => s.streaming));
    final int limit = ref.watch(aiMessageLimitProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _Welcome(),
      data: (List<AiMessage> messages) {
        if (messages.isEmpty && !streaming) return const _Welcome();
        final int off = streaming ? 1 : 0;
        final bool canLoadMore = messages.length >= limit;
        final int count = off + messages.length + (canLoadMore ? 1 : 0);

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: count,
          itemBuilder: (BuildContext context, int i) {
            if (streaming && i == 0) return const _StreamingBubble();
            if (canLoadMore && i == count - 1) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.read(aiMessageLimitProvider.notifier).more(),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Load earlier messages'),
                  ),
                ),
              );
            }
            final int msgIndex = messages.length - 1 - (i - off);
            final AiMessage m = messages[msgIndex];
            final bool isLastAssistant = !streaming &&
                m.role == AiRole.assistant &&
                msgIndex == messages.length - 1;
            return MessageBubble(
              message: m,
              onDelete: () =>
                  ref.read(aiRepositoryProvider).deleteMessage(m.id),
              onRegenerate: isLastAssistant
                  ? () => ref.read(aiChatControllerProvider.notifier).regenerate()
                  : null,
            );
          },
        );
      },
    );
  }
}

/// The in-flight assistant reply. Watches only the streaming text so it is the
/// only widget rebuilding per token.
class _StreamingBubble extends ConsumerWidget {
  const _StreamingBubble();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String text = ref.watch(
        aiChatControllerProvider.select((AiChatState s) => s.streamingText));
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    // Matches MessageBubble's assistant styling: no boxed bubble, full
    // width, small sparkle + label header — so the reply doesn't visually
    // "jump" into a different layout once streaming finishes.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.auto_awesome_rounded, size: 14, color: scheme.primary),
                const SizedBox(width: 5),
                Text(
                  'AI Assistant',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: text.isEmpty
                ? const TypingIndicator()
                : AiMarkdown(data: text, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
