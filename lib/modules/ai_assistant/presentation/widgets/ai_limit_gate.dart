import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_usage_limit_dialog.dart';

/// Invisible widget that re-asks the learner to "Watch Ad to Continue" whenever
/// the free allowance is used up and they:
///  * (re)enter the AI Assistant screen, or
///  * switch to another conversation / start a new chat.
/// Leaving and coming back therefore never skips the gate. Nothing is shown
/// while searches are still available.
class AiLimitGate extends ConsumerStatefulWidget {
  const AiLimitGate({super.key, required this.conversationId});

  final String? conversationId;

  @override
  ConsumerState<AiLimitGate> createState() => _AiLimitGateState();
}

class _AiLimitGateState extends ConsumerState<AiLimitGate> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(AiLimitGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) _scheduleCheck();
  }

  void _scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_check());
    });
  }

  Future<void> _check() async {
    if (_checking || !sl.isRegistered<RewardedAdManager>()) return;
    _checking = true;
    try {
      final bool canStart = await sl<RewardedAdManager>().canStartAiRequest();
      if (canStart || !mounted) return;
      await showAiUsageLimitDialog(context, ref);
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}