import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Remote policy for mandatory app updates.
///
/// Update docs/app_update.json on the public DarsNexa repository to require a
/// newer Play Store version. Network/config errors fail open so users are not
/// locked out because GitHub is temporarily unavailable.
class AppUpdateService {
  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Keep in sync with pubspec.yaml's +build number when releasing a new AAB.
  static const int currentVersionCode = 79;

  static const String _policyUrl =
      'https://raw.githubusercontent.com/ismail53101/Lexiora/rebrand/darsnexa/docs/app_update.json';

  Future<UpdatePolicy?> fetchPolicy() async {
    try {
      final http.Response response = await _client
          .get(Uri.parse(_policyUrl), headers: const {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final int minimum = decoded['minimumVersionCode'] is int
          ? decoded['minimumVersionCode'] as int
          : 0;
      final String title = decoded['title'] is String
          ? decoded['title'] as String
          : 'DarsNexa Update Available';
      final String message = decoded['message'] is String
          ? decoded['message'] as String
          : "We've improved your learning experience. Please update to continue.";
      final String storeUrl = decoded['storeUrl'] is String
          ? decoded['storeUrl'] as String
          : 'https://play.google.com/store/apps/details?id=com.sapiora.app';

      if (minimum <= currentVersionCode) return null;
      return UpdatePolicy(
        minimumVersionCode: minimum,
        title: title,
        message: message,
        storeUrl: storeUrl,
      );
    } catch (error) {
      debugPrint('DarsNexa update check failed open: $error');
      return null;
    }
  }

  void dispose() => _client.close();
}

class UpdatePolicy {
  const UpdatePolicy({
    required this.minimumVersionCode,
    required this.title,
    required this.message,
    required this.storeUrl,
  });

  final int minimumVersionCode;
  final String title;
  final String message;
  final String storeUrl;
}
