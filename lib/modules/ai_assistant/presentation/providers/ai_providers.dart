import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_chat.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_failure.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';
import 'package:lexiora/modules/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:lexiora/modules/ai_assistant/domain/usecases/ai_usecases.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

final Provider<AiRepository> aiRepositoryProvider =
    Provider<AiRepository>((Ref ref) => sl<AiRepository>());

final Provider<bool> aiConfiguredProvider =
    Provider<bool>((Ref ref) => ref.watch(aiRepositoryProvider).isConfigured);

// ── Conversations ────────────────────────────────────────────────────────────

class AiSearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final NotifierProvider<AiSearchQuery, String> aiSearchQueryProvider =
    NotifierProvider<AiSearchQuery, String>(AiSearchQuery.new);

final StreamProvider<List<AiConversationSummary>> aiConversationsProvider =
    StreamProvider<List<AiConversationSummary>>((Ref ref) {
  final String query = ref.watch(aiSearchQueryProvider);
  return WatchConversations(ref.watch(aiRepositoryProvider)).call(query: query);
});

/// The active conversation id (null = a fresh, not-yet-created chat).
class CurrentConversationId extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final NotifierProvider<CurrentConversationId, String?>
    currentConversationIdProvider =
    NotifierProvider<CurrentConversationId, String?>(CurrentConversationId.new);

/// Lazy-loading window over a conversation's messages.
class AiMessageLimit extends Notifier<int> {
  @override
  int build() => AiConstants.messagePageSize;
  void more() => state = state + AiConstants.messagePageSize;
  void reset() => state = AiConstants.messagePageSize;
}

final NotifierProvider<AiMessageLimit, int> aiMessageLimitProvider =
    NotifierProvider<AiMessageLimit, int>(AiMessageLimit.new);

final aiMessagesProvider =
    StreamProvider.autoDispose.family<List<AiMessage>, String>(
        (Ref ref, String conversationId) {
  final int limit = ref.watch(aiMessageLimitProvider);
  return WatchMessages(ref.watch(aiRepositoryProvider))
      .call(conversationId, limit: limit);
});

// ── Chat controller (send / stream / stop / regenerate) ─────────────────────

class AiChatState {
  const AiChatState({
    this.streaming = false,
    this.streamingText = '',
    this.error,
  });

  final bool streaming;
  final String streamingText;
  final AiFailure? error;

  AiChatState copyWith({bool? streaming, String? streamingText, AiFailure? error}) =>
      AiChatState(
        streaming: streaming ?? this.streaming,
        streamingText: streamingText ?? this.streamingText,
        error: error,
      );
}

class AiChatController extends Notifier<AiChatState> {
  StreamSubscription<AiStreamEvent>? _sub;
  AiCancelToken? _cancel;

  @override
  AiChatState build() {
    ref.onDispose(() {
      _cancel?.cancel();
      _sub?.cancel();
    });
    return const AiChatState();
  }

  AiRepository get _repo => ref.read(aiRepositoryProvider);

  /// Switch to a conversation (or null for a new chat), resetting stream state.
  void openConversation(String? id) {
    _cancel?.cancel();
    _sub?.cancel();
    _sub = null;
    ref.read(currentConversationIdProvider.notifier).set(id);
    ref.read(aiMessageLimitProvider.notifier).reset();
    state = const AiChatState();
  }

  void newChat() => openConversation(null);

  Future<void> send(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty || state.streaming) return;
    if (!_repo.isConfigured) {
      state = state.copyWith(error: AiFailure.notConfigured);
      return;
    }
    String? convId = ref.read(currentConversationIdProvider);
    if (convId == null) {
      final AiConversation c = await CreateConversation(_repo).call();
      convId = c.id;
      ref.read(currentConversationIdProvider.notifier).set(convId);
      ref.read(aiMessageLimitProvider.notifier).reset();
    }
    _start(SendMessage(_repo).call(
        conversationId: convId, userText: trimmed, cancel: _freshToken()));
  }

  Future<void> regenerate() async {
    if (state.streaming) return;
    final String? convId = ref.read(currentConversationIdProvider);
    if (convId == null || !_repo.isConfigured) return;
    _start(RegenerateReply(_repo)
        .call(conversationId: convId, cancel: _freshToken()));
  }

  /// Stop generating — finalizes whatever partial text has arrived.
  void stop() => _cancel?.cancel();

  void clearError() => state = state.copyWith();

  AiCancelToken _freshToken() {
    _cancel = AiCancelToken();
    return _cancel!;
  }

  void _start(Stream<AiStreamEvent> stream) {
    _sub?.cancel();
    state = const AiChatState(streaming: true);
    _sub = stream.listen(
      (AiStreamEvent ev) {
        switch (ev) {
          case AiDelta():
            state = state.copyWith(
                streaming: true, streamingText: state.streamingText + ev.text);
          case AiDone():
            _finish();
          case AiError():
            state = AiChatState(error: ev.failure);
        }
      },
      onError: (Object e) {
        state = AiChatState(
            error: e is AiFailure
                ? e
                : const AiFailure(
                    AiFailureKind.unknown, 'Something went wrong.'));
      },
      onDone: () {
        if (state.streaming) _finish();
      },
    );
  }

  void _finish() => state = const AiChatState();
}

final NotifierProvider<AiChatController, AiChatState> aiChatControllerProvider =
    NotifierProvider<AiChatController, AiChatState>(AiChatController.new);
