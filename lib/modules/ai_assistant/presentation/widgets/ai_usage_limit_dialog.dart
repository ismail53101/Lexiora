import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';

/// Presents the free AI allowance gate without automatically opening an ad.
Future<void> showAiUsageLimitDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final String? action = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text("You've used your 7 free AI searches."),
      content: const Text(
        'Choose how you would like to continue using the AI Assistant.',
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop('reward'),
          child: const Text('Watch Ad for 7 More Searches'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop('premium'),
          child: const Text('Go Premium'),
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
  final bool granted =
      await ref.read(aiChatControllerProvider.notifier).watchAdForMoreAi();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        granted
            ? 'You can now make 7 more AI searches.'
            : 'No additional searches were added.',
      ),
    ),
  );
}
