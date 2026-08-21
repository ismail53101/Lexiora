import 'package:lexiora/core/constants/db_constants.dart';

/// Which upstream the request should prefer, as a hint to the Cloudflare
/// Worker gateway — the app itself never holds credentials for, or talks
/// directly to, any individual provider (Forge AI, HCNSEC, or any future
/// one). The Worker owns the real decision, including automatic fallback
/// when a provider is down; this is only ever a preference.
enum AiProvider {
  /// Let the Worker decide (its own default provider, with automatic
  /// fallback to the other if that one fails). The right choice for almost
  /// all requests — this is the default.
  auto,
  forge,
  hcnsec,
  tokenrouter,
  openrouter;

  /// The exact string sent in the `X-AI-Provider` header.
  String get wireValue => name;

  static AiProvider fromWireValue(String value) => switch (value.trim().toLowerCase()) {
        'forge' => AiProvider.forge,
        'hcnsec' => AiProvider.hcnsec,
        'tokenrouter' => AiProvider.tokenrouter,
        'openrouter' => AiProvider.openrouter,
        _ => AiProvider.auto,
      };
}

/// Runtime configuration for the AI provider.
///
/// The API key is supplied at build time via a compile-time define and is only
/// ever held in memory — it is never hardcoded, persisted, or logged. Build with:
///
///   flutter build apk --dart-define=SAPIORA_AI_API_KEY=sk-xxxx \
///     [--dart-define=SAPIORA_AI_BASE_URL=https://your-worker.workers.dev] \
///     [--dart-define=SAPIORA_AI_MODEL=auto] \
///     [--dart-define=SAPIORA_AI_PROVIDER=auto|forge|hcnsec|tokenrouter|openrouter]
///
/// [baseUrl] must always point at the Cloudflare Worker gateway, never at a
/// provider directly — the Worker is the only thing that holds Forge/HCNSEC
/// credentials (as Worker secrets) and is the only thing that ever calls
/// them. With `auto`, the Worker tries every configured provider in its
/// fallback order; with an explicit value, it uses that provider only.
class AiConfig {
  const AiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.provider = AiProvider.auto,
  });

  /// Reads configuration from compile-time environment defines.
  factory AiConfig.fromEnvironment() => AiConfig(
        baseUrl: const String.fromEnvironment(
          AiConstants.envBaseUrl,
          defaultValue: AiConstants.defaultBaseUrl,
        ),
        apiKey: const String.fromEnvironment(AiConstants.envApiKey),
        model: const String.fromEnvironment(
          AiConstants.envModel,
          defaultValue: AiConstants.defaultModel,
        ),
        provider: AiProvider.fromWireValue(
          const String.fromEnvironment(
            AiConstants.envProvider,
            defaultValue: AiConstants.defaultProvider,
          ),
        ),
      );

  final String baseUrl;
  final String apiKey;
  final String model;
  final AiProvider provider;

  /// Whether an API key has been provided.
  bool get isConfigured => apiKey.trim().isNotEmpty;

  /// Full chat-completions endpoint — always the Worker's own URL.
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
    AiProvider? provider,
  }) =>
      AiConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        provider: provider ?? this.provider,
      );

  /// Redacts the API key so it can never leak into logs or error output.
  @override
  String toString() =>
      'AiConfig(baseUrl: $baseUrl, model: $model, provider: ${provider.name}, '
      'apiKey: ${apiKey.isEmpty ? "<unset>" : "***"})';
}
