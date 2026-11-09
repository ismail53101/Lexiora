import 'dart:convert';
import 'dart:io';

import 'package:lexiora/features/home/config/current_affairs_config.dart';
import 'package:lexiora/features/home/domain/entities/current_affairs_feed.dart';

class CurrentAffairsApiClient {
  CurrentAffairsApiClient(this._config);

  final CurrentAffairsConfig _config;

  Future<Map<String, dynamic>> fetchSummary(String storyId) async {
    if (_config.summaryBaseUrl.trim().isEmpty) {
      throw const CurrentAffairsUnavailableException(
        'AI summary service is not configured.',
      );
    }

    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final HttpClientRequest request =
          await client.getUrl(_config.summaryUri(storyId)).timeout(
                const Duration(seconds: 10),
              );
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.userAgentHeader, 'DarsNexa/Current-Affairs');
      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 20));
      final String raw = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok) {
        throw CurrentAffairsUnavailableException(
          'AI summary API returned HTTP ${response.statusCode}.',
        );
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const CurrentAffairsUnavailableException(
          'AI summary API returned an invalid response.',
        );
      }
      return decoded;
    } on CurrentAffairsUnavailableException {
      rethrow;
    } on Object catch (error) {
      throw CurrentAffairsUnavailableException(error.toString());
    } finally {
      client.close(force: true);
    }
  }

  Future<CurrentAffairsFeed> fetchLatest() async {
    if (!_config.isConfigured) {
      throw const CurrentAffairsUnavailableException();
    }

    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final HttpClientRequest request =
          await client.getUrl(_config.latestUri).timeout(
                const Duration(seconds: 10),
              );
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.userAgentHeader, 'Sapiora/Current-Affairs');
      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 15));
      final String raw = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != HttpStatus.ok) {
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
      client.close(force: true);
    }
  }
}

class CurrentAffairsUnavailableException implements Exception {
  const CurrentAffairsUnavailableException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'Current Affairs is temporarily unavailable.';
}
