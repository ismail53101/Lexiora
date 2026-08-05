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
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () =>
                ref.read(aiChatControllerProvider.notifier).newChat(),
          ),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[scheme.primary, scheme.tertiary],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(Icons.auto_stories_rounded,
                  color: scheme.onPrimary, size: 40),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[scheme.primary, scheme.tertiary],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.auto_stories_rounded,
                color: scheme.onPrimary, size: 18),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'AI Assistant',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: text.isEmpty
                      ? const TypingIndicator()
                      : AiMarkdown(data: text, color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
