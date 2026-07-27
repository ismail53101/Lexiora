import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/ai_assistant/config/ai_config.dart';
import 'package:lexiora/modules/ai_assistant/data/datasources/ai_local_data_source.dart';
import 'package:lexiora/modules/ai_assistant/data/repositories/ai_repository_impl.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_chat.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_conversation.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_failure.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';
import 'package:lexiora/modules/ai_assistant/domain/services/ai_chat_service.dart';

/// A scripted chat service — no network. Records the last request and emits a
/// configurable sequence of events.
class _FakeChatService implements AiChatService {
  List<AiStreamEvent> Function()? script;
  List<AiMessage> lastMessages = <AiMessage>[];

  @override
  AiProviderInfo get info => const AiProviderInfo(
      id: 'fake', name: 'Fake', capabilities: <AiCapability>{AiCapability.chat});

  @override
  Stream<AiStreamEvent> streamChat(List<AiMessage> messages,
      {String? model, AiCancelToken? cancel}) async* {
    lastMessages = messages;
    final List<AiStreamEvent> events = (script ??
        () => <AiStreamEvent>[
              const AiDelta('Hello '),
              const AiDelta('world'),
              const AiDone('Hello world'),
            ])();
    for (final AiStreamEvent e in events) {
      yield e;
    }
  }
}

void main() {
  late AppDatabase db;
  late AiRepositoryImpl repo;
  late _FakeChatService service;
  const AiConfig config = AiConfig(
      baseUrl: 'https://example.test', apiKey: 'SECRETVALUE', model: 'auto');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = _FakeChatService();
    repo = AiRepositoryImpl(AiLocalDataSource(db), service, config);
  });

  tearDown(() async {
    await db.close();
  });

  test('send persists the user message and the streamed assistant reply',
      () async {
    final AiConversation c = await repo.createConversation();
    final List<AiStreamEvent> events = await repo
        .sendMessage(conversationId: c.id, userText: 'Hi there')
        .toList();

    expect(events.whereType<AiDelta>().length, 2);
    expect(events.last, isA<AiDone>());

    final List<AiMessage> msgs = await repo.watchMessages(c.id).first;
    expect(msgs.length, 2);
    expect(msgs[0].role, AiRole.user);
    expect(msgs[0].content, 'Hi there');
    expect(msgs[1].role, AiRole.assistant);
    expect(msgs[1].content, 'Hello world');

    // History sent to the provider begins with a system prompt then the user.
    expect(service.lastMessages.first.role, AiRole.system);
    expect(service.lastMessages.any((AiMessage m) => m.content == 'Hi there'),
        isTrue);
  });

  test('first message auto-titles the conversation', () async {
    final AiConversation c = await repo.createConversation();
    await repo.sendMessage(conversationId: c.id, userText: 'Explain gravity').drain<void>();
    final AiConversation? updated = await repo.conversation(c.id);
    expect(updated!.title, 'Explain gravity');
  });

  test('watchConversations exposes count + last-message preview', () async {
    final AiConversation c = await repo.createConversation();
    await repo.sendMessage(conversationId: c.id, userText: 'Hi').drain<void>();
    final List<AiConversationSummary> list =
        await repo.watchConversations().first;
    expect(list.single.messageCount, 2);
    expect(list.single.lastMessage, 'Hello world');
  });

  test('search matches title and message content', () async {
    final AiConversation c = await repo.createConversation();
    await repo
        .sendMessage(conversationId: c.id, userText: 'Photosynthesis basics')
        .drain<void>();
    expect((await repo.watchConversations(query: 'photo').first).length, 1);
    expect((await repo.watchConversations(query: 'world').first).length, 1); // in reply
    expect((await repo.watchConversations(query: 'zzzz').first).length, 0);
  });

  test('rename and delete', () async {
    final AiConversation c = await repo.createConversation();
    await repo.renameConversation(c.id, 'My chat');
    expect((await repo.conversation(c.id))!.title, 'My chat');
    await repo.deleteConversation(c.id);
    expect(await repo.conversation(c.id), isNull);
  });

  test('regenerate replaces the last assistant reply (no duplicate)', () async {
    final AiConversation c = await repo.createConversation();
    await repo.sendMessage(conversationId: c.id, userText: 'Hi').drain<void>();
    expect((await repo.watchMessages(c.id).first).length, 2);

    service.script = () => <AiStreamEvent>[const AiDone('Second answer')];
    await repo.regenerate(conversationId: c.id).drain<void>();

    final List<AiMessage> msgs = await repo.watchMessages(c.id).first;
    expect(msgs.length, 2, reason: 'assistant reply replaced, not appended');
    expect(msgs.last.content, 'Second answer');
  });

  test('errors persist an inline error message and are excluded from history',
      () async {
    final AiConversation c = await repo.createConversation();
    service.script = () => <AiStreamEvent>[
          const AiError(AiFailure.network, partialText: 'partial'),
        ];
    final List<AiStreamEvent> events =
        await repo.sendMessage(conversationId: c.id, userText: 'Hi').toList();
    expect(events.single, isA<AiError>());

    final List<AiMessage> msgs = await repo.watchMessages(c.id).first;
    expect(msgs.length, 2);
    expect(msgs.last.status, AiMessageStatus.error);
    expect(msgs.last.content, 'partial');

    // Next request must not include the error row in the history.
    service.script = () => <AiStreamEvent>[const AiDone('ok')];
    await repo.regenerate(conversationId: c.id).drain<void>();
    expect(service.lastMessages.any((AiMessage m) => m.status == AiMessageStatus.error),
        isFalse);
  });

  test('config redacts the API key in toString', () {
    expect(config.toString().contains('SECRETVALUE'), isFalse,
        reason: 'the key value must never appear in logs/output');
    expect(config.toString(), contains('***'));
  });
}
