import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/services/ai_usage_store.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';

class _MemoryStore extends AiUsageStore {
  _MemoryStore(this.saved);
  AiUsageSnapshot? saved;
  @override
  Future<AiUsageSnapshot?> read() async => saved;
  @override
  Future<void> write(AiUsageSnapshot snapshot) async => saved = snapshot;
}

RewardedAdManager _manager(_MemoryStore store) => RewardedAdManager(
      isPremium: () async => false,
      aiUsageStore: store,
    );

void main() {
  test('7 free searches, then blocked, then an ad grants 7 more', () async {
    final RewardedAdManager m = _manager(_MemoryStore(null));
    for (int i = 0; i < AdConfiguration.FREE_AI_REQUEST_LIMIT; i++) {
      expect(await m.canStartAiRequest(), isTrue);
      m.recordSuccessfulAiRequest();
    }
    expect(await m.canStartAiRequest(), isFalse);
    expect(m.aiRefillRemaining, isNotNull);
    m.grantAiRequestsAfterReward();
    expect(await m.canStartAiRequest(), isTrue);
    expect(m.aiRefillRemaining, isNull);
  });

  test('a fresh free batch appears one hour after exhaustion', () async {
    final _MemoryStore store = _MemoryStore(
      AiUsageSnapshot(
        remaining: 0,
        exhaustedAt: DateTime.now().subtract(const Duration(minutes: 61)),
      ),
    );
    expect(await _manager(store).canStartAiRequest(), isTrue);
  });

  test('still blocked before the hour is over; survives restart', () async {
    final _MemoryStore store = _MemoryStore(
      AiUsageSnapshot(
        remaining: 0,
        exhaustedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
    );
    final RewardedAdManager m = _manager(store);
    expect(await m.canStartAiRequest(), isFalse);
    final Duration left = m.aiRefillRemaining!;
    expect(left.inMinutes, inInclusiveRange(38, 40));
  });
}