import 'package:lexiora/core/constants/db_constants.dart';

/// Runtime configuration for the AI provider.
///
/// The API key is supplied at build time via a compile-time define and is only
/// ever held in memory — it is never hardcoded, persisted, or logged. Build with:
///
///   flutter build apk --dart-define=SAPIORA_AI_API_KEY=sk-xxxx \
///     [--dart-define=SAPIORA_AI_BASE_URL=https://api.hcnsec.cn] \
///     [--dart-define=SAPIORA_AI_MODEL=auto]
class AiConfig {
  const AiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  /// Reads configuration from compile-time environment defines.
  factory AiConfig.fromEnvironment() => const AiConfig(
        baseUrl: String.fromEnvironment(
          AiConstants.envBaseUrl,
          defaultValue: AiConstants.defaultBaseUrl,
        ),
        apiKey: String.fromEnvironment(AiConstants.envApiKey),
        model: String.fromEnvironment(
          AiConstants.envModel,
          defaultValue: AiConstants.defaultModel,
        ),
      );

  final String baseUrl;
  final String apiKey;
  final String model;

  /// Whether an API key has been provided.
  bool get isConfigured => apiKey.trim().isNotEmpty;

  /// Full chat-completions endpoint.
  Uri get chatCompletionsUri {
    final String base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base${AiConstants.chatCompletionsPath}');
  }

  AiConfig copyWith({String? baseUrl, String? apiKey, String? model}) =>
      AiConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
      );

  /// Redacts the API key so it can never leak into logs or error output.
  @override
  String toString() =>
      'AiConfig(baseUrl: $baseUrl, model: $model, apiKey: ${apiKey.isEmpty ? "<unset>" : "***"})';
}
