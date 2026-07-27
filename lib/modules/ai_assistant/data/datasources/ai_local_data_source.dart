import 'package:drift/drift.dart';
import 'package:lexiora/core/database/app_database.dart';

/// All Drift queries for the AI Assistant (offline chat persistence).
class AiLocalDataSource {
  AiLocalDataSource(this._db);

  final AppDatabase _db;

  // ── Conversations ───────────────────────────────────────────────────────────

  Stream<List<QueryRow>> watchConversationSummaries(String query) {
    final String q = query.trim().toLowerCase();
    final bool filtered = q.isNotEmpty;
    return _db
        .customSelect(
          'SELECT c.*, '
          '(SELECT COUNT(*) FROM ai_messages m WHERE m.conversation_id = c.id) '
          'AS message_count, '
          '(SELECT m.content FROM ai_messages m WHERE m.conversation_id = c.id '
          '  ORDER BY m.order_index DESC LIMIT 1) AS last_message '
          'FROM ai_conversations c '
          '${filtered ? 'WHERE c.search_text LIKE ? OR EXISTS '
              '(SELECT 1 FROM ai_messages m WHERE m.conversation_id = c.id '
              '  AND LOWER(m.content) LIKE ?)' : ''} '
          'ORDER BY c.pinned DESC, c.updated_at DESC',
          variables: <Variable<Object>>[
            if (filtered) Variable.withString('%$q%'),
            if (filtered) Variable.withString('%$q%'),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.aiConversations,
            _db.aiMessages,
          },
        )
        .watch();
  }

  AiConversationRow conversationRowFrom(QueryRow r) =>
      _db.aiConversations.map(r.data);

  Future<AiConversationRow?> conversation(String id) =>
      (_db.select(_db.aiConversations)
            ..where(($AiConversationsTable t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertConversation(AiConversationsCompanion c) =>
      _db.into(_db.aiConversations).insertOnConflictUpdate(c);

  Future<void> updateConversation(String id, AiConversationsCompanion c) =>
      (_db.update(_db.aiConversations)
            ..where(($AiConversationsTable t) => t.id.equals(id)))
          .write(c);

  Future<void> deleteConversation(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.aiMessages)
            ..where(($AiMessagesTable t) => t.conversationId.equals(id)))
          .go();
      await (_db.delete(_db.aiConversations)
            ..where(($AiConversationsTable t) => t.id.equals(id)))
          .go();
    });
  }

  Future<void> deleteAllConversations() async {
    await _db.transaction(() async {
      await _db.delete(_db.aiMessages).go();
      await _db.delete(_db.aiConversations).go();
    });
  }

  // ── Messages ─────────────────────────────────────────────────────────────────

  /// The latest [limit] messages, returned ascending (oldest → newest).
  Stream<List<AiMessageRow>> watchMessages(String conversationId, int limit) {
    return (_db.select(_db.aiMessages)
          ..where(($AiMessagesTable t) => t.conversationId.equals(conversationId))
          ..orderBy(<OrderClauseGenerator<$AiMessagesTable>>[
            ($AiMessagesTable t) =>
                OrderingTerm(expression: t.orderIndex, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch()
        .map((List<AiMessageRow> rows) => rows.reversed.toList(growable: false));
  }

  Future<List<AiMessageRow>> allMessages(String conversationId) =>
      (_db.select(_db.aiMessages)
            ..where(($AiMessagesTable t) => t.conversationId.equals(conversationId))
            ..orderBy(<OrderClauseGenerator<$AiMessagesTable>>[
              ($AiMessagesTable t) => OrderingTerm(expression: t.orderIndex),
            ]))
          .get();

  Future<void> insertMessage(AiMessagesCompanion m) =>
      _db.into(_db.aiMessages).insert(m);

  Future<void> deleteMessage(String id) =>
      (_db.delete(_db.aiMessages)..where(($AiMessagesTable t) => t.id.equals(id)))
          .go();

  Future<int> nextOrderIndex(String conversationId) async {
    final QueryRow row = await _db
        .customSelect(
          'SELECT COALESCE(MAX(order_index), -1) AS m FROM ai_messages '
          'WHERE conversation_id = ?',
          variables: <Variable<Object>>[Variable.withString(conversationId)],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{_db.aiMessages},
        )
        .getSingle();
    return row.read<int>('m') + 1;
  }

  /// The most recent assistant message in a conversation, if any.
  Future<AiMessageRow?> lastAssistantMessage(String conversationId) =>
      (_db.select(_db.aiMessages)
            ..where(($AiMessagesTable t) =>
                t.conversationId.equals(conversationId) & t.role.equals(2))
            ..orderBy(<OrderClauseGenerator<$AiMessagesTable>>[
              ($AiMessagesTable t) =>
                  OrderingTerm(expression: t.orderIndex, mode: OrderingMode.desc),
            ])
            ..limit(1))
          .getSingleOrNull();
}
