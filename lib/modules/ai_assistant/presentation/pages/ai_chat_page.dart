import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_failure.dart';
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

    // Surface transient errors (e.g. not configured, network) as a SnackBar.
    ref.listen<AiFailure?>(
        aiChatControllerProvider.select((AiChatState s) => s.error),
        (AiFailure? prev, AiFailure? next) {
      if (next == null) return;
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text(next.message),
        action: next.kind == AiFailureKind.notConfigured
            ? null
            : SnackBarAction(
                label: 'Retry',
                onPressed: () =>
                    ref.read(aiChatControllerProvider.notifier).regenerate()),
      ));
      ref.read(aiChatControllerProvider.notifier).clearError();
    });

   return Scaffold(
  resizeToAvoidBottomInset: true,
  appBar: AppBar(
    title: Text(title, overflow: TextOverflow.ellipsis),
    actions: <Widget>[
      IconButton(
        tooltip: 'New chat',
        icon: const Icon(Icons.add_comment_outlined),
        onPressed: () =>
            ref.read(aiChatControllerProvider.notifier).newChat(),
      ),
    ],
  ),
  drawer: const ConversationDrawer(),
  body: !configured
      ? _notConfigured(context)
      : (currentId == null
          ? const _Welcome()
          : _MessageList(conversationId: currentId)),
  bottomNavigationBar: AnimatedPadding(
    duration: const Duration(milliseconds: 150),
    curve: Curves.easeOut,
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: SafeArea(
      top: false,
      child: ChatComposer(
        enabled: configured,
      ),
    ),
  ),
);

  Widget _notConfigured(BuildContext context) => const EmptyState(
        icon: Icons.key_off_outlined,
        title: 'AI Assistant not configured',
        message:
            'An API key is required. Build with:\n\nflutter run --dart-define=SAPIORA_AI_API_KEY=your_key\n\nYour key is never stored or logged.',
      );
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) => const EmptyState(
        icon: Icons.smart_toy_outlined,
        title: 'Ask me anything',
        message:
            'Start a conversation — explanations, summaries, code, tables and math are all supported.',
      );
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: text.isEmpty
            ? const TypingIndicator()
            : AiMarkdown(data: text, color: theme.colorScheme.onSurface),
      ),
    );
  }
}
