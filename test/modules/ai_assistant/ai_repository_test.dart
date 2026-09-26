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
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_project.dart';
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

  test('createProject and watchProjects expose conversation counts', () async {
    final AiProject p = await repo.createProject('English');
    expect(p.name, 'English');

    final AiConversation inside =
        await repo.createConversation(projectId: p.id);
    await repo.createConversation(); // outside every project

    final List<AiProjectSummary> projects = await repo.watchProjects().first;
    expect(projects.single.project.id, p.id);
    expect(projects.single.conversationCount, 1);
    expect(projects.single.lastActivity, isNotNull);

    // The conversation inside keeps the link on the entity too.
    expect(inside.projectId, p.id);
    expect(
        (await repo.watchConversations()
                .first)
            .map((AiConversationSummary s) => s.conversation.projectId),
        containsAll(<String?>[p.id, null]));
  });

  test('setConversationProject moves a chat in and out of a project', () async {
    final AiProject p = await repo.createProject('Grammar');
    final AiConversation c = await repo.createConversation();

    await repo.setConversationProject(c.id, p.id);
    expect((await repo.conversation(c.id))!.projectId, p.id);
    expect((await repo.watchProjects().first).single.conversationCount, 1);

    await repo.setConversationProject(c.id, null);
    expect((await repo.conversation(c.id))!.projectId, isNull);
    expect((await repo.watchProjects().first).single.conversationCount, 0);
  });

  test('renameProject updates the name and search text', () async {
    final AiProject p = await repo.createProject('Old name');
    await repo.renameProject(p.id, 'New name');
    final List<AiProjectSummary> projects = await repo.watchProjects().first;
    expect(projects.single.project.name, 'New name');
    expect((await repo.watchProjects(query: 'new').first).length, 1);
    expect((await repo.watchProjects(query: 'old').first).length, 0);
  });

  test('deleteProject keeps its conversations (they return to Recents)',
      () async {
    final AiProject p = await repo.createProject('Temp');
    final AiConversation c =
        await repo.createConversation(projectId: p.id);
    await repo.sendMessage(conversationId: c.id, userText: 'Hi').drain<void>();

    await repo.deleteProject(p.id);

    expect(await repo.watchProjects().first, isEmpty);
    final AiConversation? survivor = await repo.conversation(c.id);
    expect(survivor, isNotNull);
    expect(survivor!.projectId, isNull,
        reason: 'no conversation may keep pointing at a deleted project');
    expect((await repo.watchMessages(c.id).first).length, 2);
  });

  test('a conversation created with a project stays inside it and chats fully',
      () async {
    final AiProject p = await repo.createProject('English');
    final AiConversation c =
        await repo.createConversation(projectId: p.id);

    // Conversation created BEFORE any message must still be listed in the
    // project (so "New chat" inside a project is immediately visible).
    List<AiConversationSummary> inside = await repo.watchConversations().first;
    expect(
        inside.any((AiConversationSummary s) =>
            s.conversation.id == c.id && s.conversation.projectId == p.id),
        isTrue);

    // Chatting works exactly like a normal conversation.
    await repo.sendMessage(conversationId: c.id, userText: 'What is a noun?')
        .drain<void>();
    final List<AiMessage> msgs = await repo.watchMessages(c.id).first;
    expect(msgs.length, 2);
    expect(msgs.first.role, AiRole.user);
    expect(msgs.last.role, AiRole.assistant);

    // Still in the project after chatting, with a real last-message preview.
    inside = await repo.watchConversations().first;
    final AiConversationSummary summary =
        inside.firstWhere((AiConversationSummary s) => s.conversation.id == c.id);
    expect(summary.conversation.projectId, p.id);
    expect(summary.lastMessage, 'Hello world');
    expect(summary.messageCount, 2);
  });

  test('recents contain only real conversations, never search activity',
      () async {
    // Searching must not create anything.
    expect((await repo.watchConversations(query: 'hello').first), isEmpty);
    expect(await repo.watchConversations().first, isEmpty,
        reason: 'a search query alone must not appear as a conversation');

    final AiConversation c = await repo.createConversation();
    await repo.sendMessage(conversationId: c.id, userText: 'Hello world')
        .drain<void>();

    final List<AiConversationSummary> recents =
        await repo.watchConversations().first;
    expect(recents, hasLength(1));
    expect(recents.single.conversation.id, c.id);
    expect(recents.single.conversation.title, 'Hello world');
    expect(recents.single.lastMessage, 'Hello world');
  });

  test('conversations with no messages are not real history', () async {
    // An empty shell (created but never chatted in) must not appear as a
    // Recent — the UI filters on messageCount, which starts at 0.
    final AiConversation empty = await repo.createConversation();
    final List<AiConversationSummary> before =
        await repo.watchConversations().first;
    expect(
        before
            .where((AiConversationSummary s) => s.conversation.id == empty.id)
            .single
            .messageCount,
        0);

    // After a real message the same conversation becomes visible history.
    await repo.sendMessage(conversationId: empty.id, userText: 'Hello')
        .drain<void>();
    final List<AiConversationSummary> after =
        await repo.watchConversations().first;
    expect(
        after
            .where((AiConversationSummary s) => s.conversation.id == empty.id)
            .single
            .messageCount,
        2);
  });

  test('recents order conversations newest-first', () async {
    final AiConversation older = await repo.createConversation();
    await repo.sendMessage(conversationId: older.id, userText: 'first')
        .drain<void>();
    final AiConversation newer = await repo.createConversation();
    await repo.sendMessage(conversationId: newer.id, userText: 'second')
        .drain<void>();

    final List<AiConversationSummary> recents =
        await repo.watchConversations().first;
    expect(recents.first.conversation.id, newer.id,
        reason: 'the newest conversation is at the top');
    expect(recents.last.conversation.id, older.id);
  });
}
