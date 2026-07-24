import 'dart:io';

import 'package:flutter/services.dart';

/// Reports the Android API level (via the native `lexiora/platform` channel) so
/// the app can choose the correct permission/discovery strategy per version.
class DeviceInfoService {
  DeviceInfoService();

  static const MethodChannel _channel = MethodChannel('lexiora/platform');
  int? _cachedSdkInt;

  /// The Android SDK/API level (e.g. 34 for Android 14). Returns 0 off-Android.
  Future<int> androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    return _cachedSdkInt ??=
        (await _channel.invokeMethod<int>('getSdkInt')) ?? 0;
  }
}
