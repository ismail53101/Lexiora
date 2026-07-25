import 'package:flutter_tts/flutter_tts.dart';

/// Abstraction over on-device audio pronunciation (text-to-speech).
///
/// Kept as an interface so the UI depends on a contract, not on a specific TTS
/// package, and can be faked in tests. Implementations use the device's TTS
/// engine, which works offline for any voice the user has installed.
abstract interface class PronunciationService {
  /// Whether audio is available for [languageCode] (e.g. "en-US"). Used to
  /// disable the play button gracefully when it is not.
  Future<bool> isAvailable(String languageCode);

  /// Speaks [text] in [languageCode]; completes when playback finishes.
  Future<void> speak(String text, {required String languageCode});

  /// Stops any current playback.
  Future<void> stop();
}

/// Default [PronunciationService] backed by `flutter_tts` (the device TTS
/// engine). No audio files are bundled or downloaded; pronunciation is
/// synthesized on-device and works offline for installed voices.
class TtsPronunciationService implements PronunciationService {
  TtsPronunciationService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }

  @override
  Future<bool> isAvailable(String languageCode) async {
    try {
      final Object? result = await _tts.isLanguageAvailable(languageCode);
      return result == true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    final String value = text.trim();
    if (value.isEmpty) return;
    await _ensureConfigured();
    await _tts.stop();
    await _tts.setLanguage(languageCode);
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1);
    await _tts.speak(value);
  }

  @override
  Future<void> stop() => _tts.stop();
}
