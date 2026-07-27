import 'package:lexiora/modules/ai_assistant/domain/entities/ai_chat.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';
import 'package:lexiora/modules/ai_assistant/domain/repositories/ai_repository.dart';

/// Thin use cases over [AiRepository]. They keep the presentation layer free of
/// direct data-layer knowledge and make each operation independently testable.

class WatchConversations {
  const WatchConversations(this._repo);
  final AiRepository _repo;
  Stream<List<AiConversationSummary>> call({String query = ''}) =>
      _repo.watchConversations(query: query);
}

class WatchMessages {
  const WatchMessages(this._repo);
  final AiRepository _repo;
  Stream<List<AiMessage>> call(String conversationId, {int limit = 40}) =>
      _repo.watchMessages(conversationId, limit: limit);
}

class CreateConversation {
  const CreateConversation(this._repo);
  final AiRepository _repo;
  Future<AiConversation> call({String? title}) =>
      _repo.createConversation(title: title);
}

class RenameConversation {
  const RenameConversation(this._repo);
  final AiRepository _repo;
  Future<void> call(String id, String title) =>
      _repo.renameConversation(id, title);
}

class DeleteConversation {
  const DeleteConversation(this._repo);
  final AiRepository _repo;
  Future<void> call(String id) => _repo.deleteConversation(id);
}

class SendMessage {
  const SendMessage(this._repo);
  final AiRepository _repo;
  Stream<AiStreamEvent> call({
    required String conversationId,
    required String userText,
    AiCancelToken? cancel,
  }) =>
      _repo.sendMessage(
          conversationId: conversationId, userText: userText, cancel: cancel);
}

class RegenerateReply {
  const RegenerateReply(this._repo);
  final AiRepository _repo;
  Stream<AiStreamEvent> call({
    required String conversationId,
    AiCancelToken? cancel,
  }) =>
      _repo.regenerate(conversationId: conversationId, cancel: cancel);
}
