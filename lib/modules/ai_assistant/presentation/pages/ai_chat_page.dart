import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/app_bottom_nav.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_project.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_limit_gate.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_markdown.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_usage_limit_dialog.dart';
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
    final String? pendingProjectId = ref.watch(currentProjectIdProvider);
    final String title = ref.watch(aiConversationsProvider).maybeWhen(
          data: (List<AiConversationSummary> list) {
            for (final AiConversationSummary s in list) {
              if (s.conversation.id == currentId) return s.conversation.title;
            }
            return 'AI Assistant';
          },
          orElse: () => 'AI Assistant',
        );
    // A chat started from inside a project shows the project name until the
    // first message creates the conversation.
    final String effectiveTitle = currentId == null && pendingProjectId != null
        ? (ref.watch(aiProjectsProvider).maybeWhen(
              data: (List<AiProjectSummary> list) {
                for (final AiProjectSummary p in list) {
                  if (p.project.id == pendingProjectId) return p.project.name;
                }
                return 'AI Assistant';
              },
              orElse: () => 'AI Assistant',
            ))
        : title;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
                child: Text(effectiveTitle, overflow: TextOverflow.ellipsis)),
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
          AiLimitGate(conversationId: currentId),
          Expanded(
            child: !configured
                ? _notConfigured(context)
                : (currentId == null
                    ? _Welcome(projectId: pendingProjectId)
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
            'An API key is required. Build with:\n\nflutter run --dart-define=DARSNEXA_AI_API_KEY=your_key\n\nYour key is never stored or logged.',
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

class _Welcome extends ConsumerWidget {
  const _Welcome({this.projectId});

  /// When a chat was started from inside a project, the welcome state shows
  /// the project name — reinforcing that the first message lands in it.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AiProject? project = projectId == null
        ? null
        : ref.watch(aiProjectsProvider).maybeWhen(
              data: (List<AiProjectSummary> list) {
                for (final AiProjectSummary p in list) {
                  if (p.project.id == projectId) return p.project;
                }
                return null;
              },
              orElse: () => null,
            );
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
              child: Image.asset(
                'assets/branding/ai_assistant_nav.webp',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              project == null ? 'Hi, how can I assist you?' : project.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (project != null) ...<Widget>[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.folder_rounded,
                      size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Project chat — messages are filed here',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
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

class _MessageList extends ConsumerStatefulWidget {
  const _MessageList({required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<_MessageList> {
  static const double _autoScrollThreshold = 48;

  final ScrollController _scrollController = ScrollController();
  bool _userScrolledUp = false;
  bool _programmaticScrollInProgress = false;
  bool _userScrollInProgress = false;

  void _setUserScrolledUp(bool value) {
    if (_userScrolledUp == value) return;
    _userScrolledUp = value;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  double _distanceFromLatest() {
    if (!_scrollController.hasClients) return 0;
    final ScrollPosition position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels).clamp(0.0, double.infinity);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _programmaticScrollInProgress) return;
    if (_userScrollInProgress &&
        _distanceFromLatest() > _autoScrollThreshold) {
      _setUserScrolledUp(true);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_programmaticScrollInProgress) return false;
    final double distance = _distanceFromLatest();

    if (notification is ScrollStartNotification) {
      _userScrollInProgress = notification.dragDetails != null;
      if (_userScrollInProgress && distance > _autoScrollThreshold) {
        _setUserScrolledUp(true);
      }
    } else if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      _userScrollInProgress = true;
      if (distance > _autoScrollThreshold) _setUserScrolledUp(true);
    } else if (notification is ScrollUpdateNotification &&
        (_userScrollInProgress || notification.dragDetails != null)) {
      _userScrollInProgress = true;
      if (distance > _autoScrollThreshold) _setUserScrolledUp(true);
    } else if (notification is ScrollEndNotification &&
        _userScrollInProgress) {
      _userScrollInProgress = false;
      if (distance <= _autoScrollThreshold) {
        _setUserScrolledUp(false);
      } else {
        _setUserScrolledUp(true);
      }
    }
    return false;
  }

  /// Keep the newest streamed text visible unless the user is reading history.
  void _followLatestAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _userScrolledUp ||
          _userScrollInProgress ||
          _programmaticScrollInProgress ||
          !_scrollController.hasClients) {
        return;
      }
      final ScrollPosition position = _scrollController.position;
      if ((position.maxScrollExtent - position.pixels).abs() < 1) return;
      _scrollController.jumpTo(position.maxScrollExtent);
    });
  }

  Future<void> _resumeAutoScroll() async {
    if (!_scrollController.hasClients) return;
    _setUserScrolledUp(false);
    await _scrollToLatest();
  }

  Future<void> _scrollToLatest() async {
    if (_userScrolledUp ||
        !_scrollController.hasClients ||
        _programmaticScrollInProgress) return;
    _programmaticScrollInProgress = true;
    try {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } finally {
      _programmaticScrollInProgress = false;
    }
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final AiSendResult result =
        await ref.read(aiChatControllerProvider.notifier).regenerate();
    if (result == AiSendResult.limitReached && context.mounted) {
      await showAiUsageLimitDialog(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AiMessage>> async =
        ref.watch(aiMessagesProvider(widget.conversationId));
    final AiChatState chatState = ref.watch(aiChatControllerProvider);
    final bool streaming = chatState.streaming;
    final String streamingText = chatState.streamingText;
    final int limit = ref.watch(aiMessageLimitProvider);

    if (streaming) _followLatestAfterLayout();

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _Welcome(),
      data: (List<AiMessage> messages) {
        if (messages.isEmpty && !streaming) return const _Welcome();
        final bool canLoadMore = messages.length >= limit;
        final int count = messages.length + (canLoadMore ? 1 : 0) + (streaming ? 1 : 0);

        return Stack(
          children: <Widget>[
            NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: ListView.builder(
                // Normal chronological layout: each assistant answer starts at
                // its own top and grows downward, like ChatGPT.
                reverse: false,
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: count,
                itemBuilder: (BuildContext context, int i) {
                  if (canLoadMore && i == 0) {
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

                  final int messageIndex = i - (canLoadMore ? 1 : 0);
                  if (streaming && messageIndex == messages.length) {
                    return _StreamingBubble(
                      onTextRendered: _followLatestAfterLayout,
                    );
                  }

                  final AiMessage message = messages[messageIndex];
                  final bool isLastAssistant = !streaming &&
                      message.role == AiRole.assistant &&
                      messageIndex == messages.length - 1;
                  return MessageBubble(
                    message: message,
                    onDelete: () =>
                        ref.read(aiRepositoryProvider).deleteMessage(message.id),
                    onRegenerate: isLastAssistant
                        ? () => unawaited(_regenerate(context, ref))
                        : null,
                  );
                },
              ),
            ),
            if (streaming && _userScrolledUp)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: 'ai-scroll-to-bottom',
                  tooltip: 'Scroll to latest answer',
                  onPressed: _resumeAutoScroll,
                  child: const Icon(Icons.arrow_downward_rounded),
                ),
              ),
          ],
        );
      },
    );
  }
}
/// The in-flight assistant reply. The provider's real stream deltas are
/// rendered directly, without a second artificial character-by-character timer.
class _StreamingBubble extends ConsumerStatefulWidget {
  const _StreamingBubble({required this.onTextRendered});

  final VoidCallback onTextRendered;

  @override
  ConsumerState<_StreamingBubble> createState() => _StreamingBubbleState();
}

class _StreamingBubbleState extends ConsumerState<_StreamingBubble> {
  @override
  void didUpdateWidget(covariant _StreamingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onTextRendered != widget.onTextRendered) {
      widget.onTextRendered();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String text = ref.watch(
      aiChatControllerProvider.select((AiChatState s) => s.streamingText),
    );
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onTextRendered();
    });

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