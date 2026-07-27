import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/ai_assistant/data/services/openai_compatible_chat_service.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_failure.dart';

void main() {
  group('SSE delta parsing', () {
    test('extracts incremental content', () {
      expect(
        OpenAiCompatibleChatService.parseStreamDelta(
            '{"choices":[{"delta":{"content":"Hi"}}]}'),
        'Hi',
      );
    });

    test('role-only / empty delta returns null', () {
      expect(
        OpenAiCompatibleChatService.parseStreamDelta(
            '{"choices":[{"delta":{"role":"assistant"}}]}'),
        isNull,
      );
    });

    test('tolerates a message-shaped chunk', () {
      expect(
        OpenAiCompatibleChatService.parseStreamDelta(
            '{"choices":[{"message":{"content":"Yo"}}]}'),
        'Yo',
      );
    });

    test('invalid JSON returns null (never throws)', () {
      expect(OpenAiCompatibleChatService.parseStreamDelta('not json'), isNull);
      expect(OpenAiCompatibleChatService.parseStreamDelta('{}'), isNull);
    });
  });

  group('full completion parsing', () {
    test('reads choices[0].message.content', () {
      expect(
        OpenAiCompatibleChatService.parseFullContent(<String, dynamic>{
          'choices': <dynamic>[
            <String, dynamic>{
              'message': <String, dynamic>{'content': '  Answer  '}
            }
          ]
        }),
        'Answer',
      );
    });

    test('empty choices → empty string', () {
      expect(
          OpenAiCompatibleChatService.parseFullContent(
              <String, dynamic>{'choices': <dynamic>[]}),
          '');
    });
  });

  group('HTTP status → AiFailure', () {
    test('maps known codes to friendly failures', () {
      expect(AiFailure.fromStatus(401).kind, AiFailureKind.unauthorized);
      expect(AiFailure.fromStatus(403).kind, AiFailureKind.forbidden);
      expect(AiFailure.fromStatus(404).kind, AiFailureKind.notFound);
      expect(AiFailure.fromStatus(408).kind, AiFailureKind.timeout);
      expect(AiFailure.fromStatus(429).kind, AiFailureKind.rateLimited);
      expect(AiFailure.fromStatus(500).kind, AiFailureKind.server);
      expect(AiFailure.fromStatus(503).kind, AiFailureKind.server);
      expect(AiFailure.fromStatus(418).kind, AiFailureKind.unknown);
    });

    test('every failure carries a non-empty user message', () {
      for (final int code in <int>[401, 403, 404, 408, 429, 500, 418]) {
        expect(AiFailure.fromStatus(code).message, isNotEmpty);
      }
    });
  });
}
