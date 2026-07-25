import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';

/// A "tap to hear pronunciation" button backed by on-device TTS.
///
/// Behaviour (per the mandatory pronunciation rules):
///  * checks audio availability for its [languageCode] on mount;
///  * **hides itself** when that accent's audio is unavailable (no broken /
///    dead button is ever shown);
///  * shows a loading spinner while speaking;
///  * never crashes — any TTS error is swallowed.
class PronunciationButton extends ConsumerStatefulWidget {
  const PronunciationButton({
    super.key,
    required this.text,
    required this.languageCode,
    required this.label,
  });

  /// The word to speak.
  final String text;

  /// TTS locale, e.g. "en-US" or "en-GB".
  final String languageCode;

  /// Short label, e.g. "US" or "UK".
  final String label;

  @override
  ConsumerState<PronunciationButton> createState() =>
      _PronunciationButtonState();
}

class _PronunciationButtonState extends ConsumerState<PronunciationButton> {
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
          .read(pronunciationServiceProvider)
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
      await ref.read(pronunciationServiceProvider).speak(
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
    // While checking, or when this accent has no voice, show nothing.
    if (_available != true) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: _busy ? null : _play,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.volume_up_outlined, size: 18),
      label: Text(widget.label),
    );
  }
}
