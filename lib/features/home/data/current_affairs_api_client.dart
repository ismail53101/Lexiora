import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexiora/features/home/config/current_affairs_config.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';

class CurrentAffairsApiClient {
  CurrentAffairsApiClient(this._config);

  final CurrentAffairsConfig _config;

  Future<CurrentAffairsFeed> fetchLatest() async {
    if (!_config.isConfigured) {
      throw const CurrentAffairsUnavailableException();
    }

    final http.Client client = http.Client();
    try {
      final http.Response response = await client.get(
        _config.latestUri,
        headers: const <String, String>{
          'Accept': 'application/json',
          'User-Agent': 'Sapiora/Current-Affairs',
        },
      ).timeout(const Duration(seconds: 15));
      final String raw = response.body;
      if (response.statusCode != 200) {
        throw CurrentAffairsUnavailableException(
          'Current Affairs API returned HTTP ${response.statusCode}.',
        );
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const CurrentAffairsUnavailableException(
          'Current Affairs API returned an invalid response.',
        );
      }
      return CurrentAffairsFeed.fromJson(decoded);
    } on CurrentAffairsUnavailableException {
      rethrow;
    } on Object catch (error) {
      throw CurrentAffairsUnavailableException(error.toString());
    } finally {
      client.close();
    }
  }
}

class CurrentAffairsUnavailableException implements Exception {
  const CurrentAffairsUnavailableException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'Current Affairs is temporarily unavailable.';
}
