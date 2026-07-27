import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/ai_assistant/data/datasources/ai_local_data_source.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_chat.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';
import 'package:lexiora/modules/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:lexiora/modules/ai_assistant/domain/services/ai_chat_service.dart';
import 'package:uuid/uuid.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl(this._local, this._service, this._config);

  final AiLocalDataSource _local;
  final AiChatService _service;
  final AiConfig _config;
  static const Uuid _uuid = Uuid();

  /// A light system prompt that nudges rich Markdown/LaTeX output. Never
  /// persisted — added only to outgoing requests.
  static const String _systemPrompt =
      'You are Sapiora\'s built-in study assistant. Be clear and concise. '
      'Format answers in Markdown — use headings, bullet lists, tables, fenced '
      'code blocks with language tags, and LaTeX (\$...\$ or \$\$...\$\$) for '
      'math when helpful.';

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  AiProviderInfo get providerInfo => _service.info;

  // ── Conversations ─────────────────────────────────────────────────────────

  @override
  Stream<List<AiConversationSummary>> watchConversations({String query = ''}) =>
      _local.watchConversationSummaries(query).map((List<QueryRow> rows) => rows
          .map((QueryRow r) => AiConversationSummary(
                conversation: _toConversation(_local.conversationRowFrom(r)),
                messageCount: r.read<int>('message_count'),
                lastMessage: r.read<String?>('last_message'),
              ))
          .toList(growable: false));

  @override
  Future<AiConversation> createConversation({String? title}) async {
    final DateTime now = DateTime.now();
    final AiConversation c = AiConversation(
      id: _uuid.v4(),
      title: (title == null || title.trim().isEmpty) ? 'New chat' : title.trim(),
      model: _config.model,
      createdAt: now,
      updatedAt: now,
    );
    await _local.upsertConversation(AiConversationsCompanion.insert(
      id: c.id,
      title: c.title,
      model: Value<String?>(c.model),
      searchText: Value<String>(c.title.toLowerCase()),
      createdAt: now,
      updatedAt: now,
    ));
    return c;
  }

  @override
  Future<AiConversation?> conversation(String id) async {
    final AiConversationRow? r = await _local.conversation(id);
    return r == null ? null : _toConversation(r);
  }

  @override
  Future<void> renameConversation(String id, String title) {
    final String t = title.trim().isEmpty ? 'Untitled chat' : title.trim();
    return _local.updateConversation(
      id,
      AiConversationsCompanion(
        title: Value<String>(t),
        searchText: Value<String>(t.toLowerCase()),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteConversation(String id) => _local.deleteConversation(id);

  @override
  Future<void> deleteAllConversations() => _local.deleteAllConversations();

  // ── Messages ───────────────────────────────────────────────────────────────

  @override
  Stream<List<AiMessage>> watchMessages(String conversationId,
          {int limit = 40}) =>
      _local.watchMessages(conversationId, limit).map(
          (List<AiMessageRow> rows) =>
              rows.map(_toMessage).toList(growable: false));

  @override
  Future<void> deleteMessage(String id) => _local.deleteMessage(id);

  // ── Chat lifecycle ──────────────────────────────────────────────────────────

  @override
  Stream<AiStreamEvent> sendMessage({
    required String conversationId,
    required String userText,
    AiCancelToken? cancel,
  }) async* {
    await _persistUser(conversationId, userText);
    yield* _streamAssistant(conversationId, cancel);
  }

  @override
  Stream<AiStreamEvent> regenerate({
    required String conversationId,
    AiCancelToken? cancel,
  }) async* {
    final AiMessageRow? last = await _local.lastAssistantMessage(conversationId);
    if (last != null) await _local.deleteMessage(last.id);
    yield* _streamAssistant(conversationId, cancel);
  }

  Future<void> _persistUser(String conversationId, String userText) async {
    final int order = await _local.nextOrderIndex(conversationId);
    final DateTime now = DateTime.now();
    await _local.insertMessage(AiMessagesCompanion.insert(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: AiRole.user.index,
      content: userText,
      orderIndex: Value<int>(order),
      createdAt: now,
    ));
    if (order == 0) {
      final String title = _titleFrom(userText);
      await _local.updateConversation(
        conversationId,
        AiConversationsCompanion(
          title: Value<String>(title),
          searchText: Value<String>(title.toLowerCase()),
          updatedAt: Value<DateTime>(now),
        ),
      );
    } else {
      await _local.updateConversation(conversationId,
          AiConversationsCompanion(updatedAt: Value<DateTime>(now)));
    }
  }

  Stream<AiStreamEvent> _streamAssistant(
      String conversationId, AiCancelToken? cancel) async* {
    final List<AiMessage> history = await _historyWithSystem(conversationId);
    final StringBuffer acc = StringBuffer();

    await for (final AiStreamEvent ev
        in _service.streamChat(history, model: _config.model, cancel: cancel)) {
      switch (ev) {
        case AiDelta():
          acc.write(ev.text);
          yield ev;
        case AiDone():
          await _persistAssistant(conversationId, ev.fullText);
          yield ev;
        case AiError():
          await _persistAssistant(conversationId, ev.partialText,
              error: ev.failure.message);
          yield ev;
      }
    }
  }

  Future<void> _persistAssistant(String conversationId, String content,
      {String? error}) async {
    // Nothing to keep and no error → skip (empty reply).
    if (content.trim().isEmpty && error == null) return;
    final int order = await _local.nextOrderIndex(conversationId);
    final DateTime now = DateTime.now();
    await _local.insertMessage(AiMessagesCompanion.insert(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: AiRole.assistant.index,
      content: content,
      status: Value<int>(error == null ? 0 : 1),
      error: Value<String?>(error),
      orderIndex: Value<int>(order),
      createdAt: now,
    ));
    await _local.updateConversation(conversationId,
        AiConversationsCompanion(updatedAt: Value<DateTime>(now)));
  }

  Future<List<AiMessage>> _historyWithSystem(String conversationId) async {
    final DateTime now = DateTime.now();
    final List<AiMessage> stored = (await _local.allMessages(conversationId))
        .where((AiMessageRow r) => r.status != 1) // skip prior error rows
        .map(_toMessage)
        .toList();
    return <AiMessage>[
      AiMessage(
        id: 'system',
        conversationId: conversationId,
        role: AiRole.system,
        content: _systemPrompt,
        createdAt: now,
      ),
      ...stored,
    ];
  }

  String _titleFrom(String text) {
    final String firstLine = text.trim().split('\n').first.trim();
    if (firstLine.length <= 48) return firstLine.isEmpty ? 'New chat' : firstLine;
    return '${firstLine.substring(0, 48).trimRight()}…';
  }

  // ── Mapping ─────────────────────────────────────────────────────────────────

  AiConversation _toConversation(AiConversationRow r) => AiConversation(
        id: r.id,
        title: r.title,
        model: r.model,
        pinned: r.pinned,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  AiMessage _toMessage(AiMessageRow r) => AiMessage(
        id: r.id,
        conversationId: r.conversationId,
        role: AiRole.fromIndex(r.role),
        content: r.content,
        status: AiMessageStatus.fromStored(r.status),
        error: r.error,
        orderIndex: r.orderIndex,
        createdAt: r.createdAt,
      );
}
