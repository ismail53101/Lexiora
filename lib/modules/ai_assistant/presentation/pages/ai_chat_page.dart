import 'dart:async';

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
  /// Smart auto-scroll state. When false, streaming is allowed to continue
  /// without moving the user's viewport.
  bool _isAutoScrollEnabled = true;

  /// Distance from the newest message (offset 0 because the list is reversed)
  /// at which auto-scroll is considered to be at the bottom.
  static const double _bottomThreshold = 24;

  final ScrollController _scrollController = ScrollController();
  Timer? _streamScrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    // Scroll only when a new streaming chunk arrives. The callback is gated
    // by _isAutoScrollEnabled, so manual scrolling always has priority.
    ref.listenManual<String>(
      aiChatControllerProvider.select((AiChatState s) => s.streamingText),
      (_, String _) => _scheduleStreamingScroll(),
    );
  }

  @override
  void dispose() {
    _streamScrollTimer?.cancel();
    _streamScrollTimer = null;
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final double offset = _scrollController.position.pixels;

    // Because the ListView is reversed, offset 0 is the newest message.
    // Reaching the bottom re-enables smart auto-scroll.
    if (offset <= _bottomThreshold && !_isAutoScrollEnabled) {
      _isAutoScrollEnabled = true;
      if (mounted) setState(() {});
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      final double offset = notification.metrics.pixels;

      // The prompt's rule: when the user scrolls away from the newest
      // message, disable auto-scroll immediately.
      if (notification.direction == ScrollDirection.forward &&
          offset > _bottomThreshold) {
        if (_isAutoScrollEnabled) {
          _isAutoScrollEnabled = false;
          _streamScrollTimer?.cancel();
          _streamScrollTimer = null;
          if (mounted) setState(() {});
        }
      }

      // Also use the actual offset as a safety net. This covers reversed
      // ListView gesture semantics across Flutter versions/devices.
      if (offset > _bottomThreshold && _isAutoScrollEnabled) {
        _isAutoScrollEnabled = false;
        _streamScrollTimer?.cancel();
        _streamScrollTimer = null;
        if (mounted) setState(() {});
      } else if (offset <= _bottomThreshold && !_isAutoScrollEnabled) {
        _isAutoScrollEnabled = true;
        if (mounted) setState(() {});
      }
    } else if (notification is ScrollEndNotification) {
      final double offset = notification.metrics.pixels;
      if (offset <= _bottomThreshold && !_isAutoScrollEnabled) {
        _isAutoScrollEnabled = true;
        if (mounted) setState(() {});
      }
    }

    return false;
  }

  /// Smoothly follows the newest content only while smart auto-scroll is
  /// enabled. Never uses jumpTo(), so completion does not cause an abrupt
  /// jump.
  Future<void> _scrollToBottom() async {
    if (!_isAutoScrollEnabled || !_scrollController.hasClients) return;

    const double target = 0;
    final double current = _scrollController.position.pixels;
    if ((current - target).abs() <= 1) return;

    try {
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } on FlutterError {
      // The controller can lose its position while the conversation is
      // disposed/replaced. There is nothing to recover here.
    }
  }

  /// Coalesce very fast stream chunks into one smooth animation. This avoids
  /// starting dozens of overlapping animations when the provider emits
  /// multiple chunks within the same frame.
  void _scheduleStreamingScroll() {
    if (!_isAutoScrollEnabled || !_scrollController.hasClients) return;

    _streamScrollTimer?.cancel();
    _streamScrollTimer = Timer(const Duration(milliseconds: 24), () {
      _streamScrollTimer = null;
      if (!mounted || !_isAutoScrollEnabled) return;
      unawaited(_scrollToBottom());
    });
  }

  Future<void> _resumeAutoScroll() async {
    _isAutoScrollEnabled = true;
    if (mounted) setState(() {});
    await _scrollToBottom();
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

        return Stack(
          children: <Widget>[
            NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: ListView.builder(
                reverse: true,
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: count,
                itemBuilder: (BuildContext context, int i) {
                  if (streaming && i == 0) {
                    return const _StreamingBubble();
                  }
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
                        ? () => unawaited(_regenerate(context, ref))
                        : null,
                  );
                },
              ),
            ),
            if (streaming && !_isAutoScrollEnabled)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: 'ai-scroll-to-bottom',
                  tooltip: 'Scroll to bottom',
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

/// The in-flight assistant reply.
///
/// Network tokens are buffered and rendered in small batches. This keeps
/// markdown/layout work off the hot path and, importantly, never touches the
/// parent ScrollController while the user is scrolling.
class _StreamingBubble extends ConsumerStatefulWidget {
  const _StreamingBubble();

  @override
  ConsumerState<_StreamingBubble> createState() => _StreamingBubbleState();
}

class _StreamingBubbleState extends ConsumerState<_StreamingBubble> {
  static const Duration _tickerInterval = Duration(milliseconds: 32);
  static const int _normalBatchSize = 2;
  static const int _catchUpBatchSize = 8;
  static const int _catchUpThreshold = 32;

  String _sourceText = '';
  String _renderedText = '';
  final List<String> _textQueue = <String>[];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _enqueueSource(ref.read(aiChatControllerProvider).streamingText);
    _ticker = Timer.periodic(_tickerInterval, (_) => _consumeQueue());
  }

  void _enqueueSource(String source) {
    if (source == _sourceText) return;

    // streamingText is cumulative. Queue only the new suffix.
    if (!source.startsWith(_sourceText)) {
      _sourceText = source;
      _renderedText = '';
      _textQueue
        ..clear()
        ..addAll(source.split(''));
      return;
    }

    final String suffix = source.substring(_sourceText.length);
    if (suffix.isNotEmpty) {
      _textQueue.addAll(suffix.split(''));
    }
    _sourceText = source;
  }

  void _consumeQueue() {
    if (!mounted || _textQueue.isEmpty) return;

    final int takeCount = _textQueue.length >= _catchUpThreshold
        ? _catchUpBatchSize
        : _normalBatchSize;
    final int actualCount =
        takeCount < _textQueue.length ? takeCount : _textQueue.length;

    final StringBuffer next = StringBuffer();
    for (int i = 0; i < actualCount; i++) {
      next.write(_textQueue[i]);
    }
    _textQueue.removeRange(0, actualCount);

    setState(() => _renderedText += next.toString());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    _textQueue.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(
      aiChatControllerProvider.select((AiChatState s) => s.streamingText),
      (_, String next) => _enqueueSource(next),
    );

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

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
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: scheme.primary,
                ),
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
            child: _renderedText.isEmpty
                ? const TypingIndicator()
                : AiMarkdown(
                    data: _renderedText,
                    color: scheme.onSurface,
                  ),
          ),
        ],
      ),
    );
  }
}
