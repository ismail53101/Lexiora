import 'dart:io';

import 'package:flutter/services.dart';

/// Toggles the Android "keep screen on" window flag (via the native
/// `lexiora/platform` channel). Used by the reader so the screen doesn't dim
/// while reading, when the user enables it in Settings.
class ScreenWakeService {
  ScreenWakeService();

  static const MethodChannel _channel = MethodChannel('lexiora/platform');

  Future<void> setKeepScreenOn(bool on) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', <String, Object?>{
        'on': on,
      });
    } on Object {
      // Non-fatal: keeping the screen on is a nicety, not a hard requirement.
    }
  }
}
