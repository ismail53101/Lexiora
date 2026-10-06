import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';

/// Presents the free AI allowance gate without automatically opening an ad.
Future<void> showAiUsageLimitDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final Duration? wait = sl<RewardedAdManager>().aiRefillRemaining;
  final String waitText = wait == null
      ? 'Free searches return after one hour.'
      : 'Your next ${AdConfiguration.FREE_AI_REQUEST_LIMIT} free searches '
          'unlock in ${_formatWait(wait)}.';
  final String? action = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(
        "You've used your ${AdConfiguration.FREE_AI_REQUEST_LIMIT} free "
        'AI searches.',
      ),
      content: Text(
        '$waitText\n\nOr watch a short ad to continue right now.',
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop('reward'),
          child: Text(
            'Watch Ad to Continue '
            '(+${AdConfiguration.REWARDED_AI_REQUEST_BONUS})',
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop('premium'),
          child: const Text('Go Premium'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Not now'),
        ),
      ],
    ),
  );
  if (!context.mounted || action == null) return;
  if (action == 'premium') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium will be available soon.')),
    );
    return;
  }
  // Show a small "loading" dialog while the ad is fetched/shown, so the
  // button never looks dead.
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  bool loaderOpen = true;
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: <Widget>[
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Loading ad…')),
            ],
          ),
        ),
      ),
    ).whenComplete(() => loaderOpen = false),
  );
  final RewardedAdResult result = await ref
      .read(aiChatControllerProvider.notifier)
      .watchAdForMoreAiResult();
  if (loaderOpen && navigator.mounted) navigator.pop();
  if (!context.mounted) return;
  final String message = switch (result) {
    RewardedAdResult.rewarded => 'You can now make 7 more AI searches.',
    RewardedAdResult.premium => 'Premium users have unlimited searches.',
    RewardedAdResult.cooldown =>
      'Please wait a few minutes before watching another ad.',
    RewardedAdResult.unavailable =>
      'No ad is available right now. Check your internet connection and '
          'try again in a moment.',
    RewardedAdResult.failed =>
      'The ad was closed before it finished, so no searches were added. '
          'Watch the whole ad to get 7 more.',
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String _formatWait(Duration d) {
  final int minutes = (d.inSeconds / 60).ceil();
  if (minutes <= 1) return 'less than a minute';
  if (minutes < 60) return '$minutes minutes';
  return '1 hour';
}