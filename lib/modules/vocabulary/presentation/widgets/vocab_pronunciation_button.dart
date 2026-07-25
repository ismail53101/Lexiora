import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/vocabulary/presentation/providers/vocabulary_providers.dart';

/// A compact "tap to hear" button backed by the shared on-device TTS service.
///
/// * checks availability for [languageCode] on mount and **hides** if that
///   voice is unavailable (never a dead button);
/// * shows a spinner while speaking; never crashes on a TTS error.
class VocabPronunciationButton extends ConsumerStatefulWidget {
  const VocabPronunciationButton({
    super.key,
    required this.text,
    this.languageCode = 'en-US',
  });

  final String text;
  final String languageCode;

  @override
  ConsumerState<VocabPronunciationButton> createState() =>
      _VocabPronunciationButtonState();
}

class _VocabPronunciationButtonState
    extends ConsumerState<VocabPronunciationButton> {
  bool? _available; // null while checking
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    bool ok;
    try {
      ok = await ref
          .read(vocabularyPronunciationServiceProvider)
          .isAvailable(widget.languageCode);
    } on Object {
      ok = false;
    }
    if (mounted) setState(() => _available = ok);
  }

  Future<void> _play() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(vocabularyPronunciationServiceProvider).speak(
            widget.text,
            languageCode: widget.languageCode,
          );
    } on Object {
      // Never crash on a TTS failure.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_available != true) return const SizedBox(width: 40);
    return IconButton.filledTonal(
      onPressed: _busy ? null : _play,
      tooltip: 'Play pronunciation',
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.volume_up_outlined, size: 20),
    );
  }
}
