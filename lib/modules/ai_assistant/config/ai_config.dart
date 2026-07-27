import 'package:lexiora/core/constants/db_constants.dart';

class AiConfig {
  const AiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  factory AiConfig.fromEnvironment() => const AiConfig(
        baseUrl:
            'https://sapiora-ai-worker.ismaillasharibaloch53.workers.dev',
        apiKey: 'worker',
        model: 'auto',
      );

  final String baseUrl;
  final String apiKey;
  final String model;

  /// Always configured because the API key is stored securely
  /// in the Cloudflare Worker.
  bool get isConfigured => true;

  Uri get chatCompletionsUri {
    final String base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base${AiConstants.chatCompletionsPath}');
  }

  AiConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
  }) =>
      AiConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
      );

  @override
  String toString() =>
      'AiConfig(baseUrl: $baseUrl, model: $model, apiKey: ***)';
}