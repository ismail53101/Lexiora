import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/ai_assistant/data/services/openai_compatible_chat_service.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_failure.dart';

void main() {
  test('Cloudflare 5xx / 52x, timeouts and network drops are retried', () {
    for (final int status in <int>[500, 502, 503, 504, 520, 522, 524]) {
      expect(
        OpenAiCompatibleChatService.isTransientFailure(
          AiFailure.fromStatus(status),
        ),
        isTrue,
        reason: 'status $status',
      );
    }
    expect(
      OpenAiCompatibleChatService.isTransientFailure(AiFailure.timeout),
      isTrue,
    );
    expect(
      OpenAiCompatibleChatService.isTransientFailure(AiFailure.network),
      isTrue,
    );
  });

  test('auth, rate-limit and not-found errors are never retried', () {
    for (final int status in <int>[401, 403, 404, 429]) {
      expect(
        OpenAiCompatibleChatService.isTransientFailure(
          AiFailure.fromStatus(status),
        ),
        isFalse,
        reason: 'status $status',
      );
    }
  });
}