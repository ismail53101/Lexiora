/// Classified AI errors with user-friendly messages. No provider internals or
/// secrets are ever surfaced here.
enum AiFailureKind {
  notConfigured,
  unauthorized, // 401
  forbidden, // 403
  notFound, // 404
  timeout, // 408 / client timeout
  rateLimited, // 429
  server, // 5xx
  network, // no connectivity / socket
  malformed, // bad/unexpected response body
  cancelled, // user stopped generation
  unknown,
}

/// A domain error the UI can present directly.
class AiFailure implements Exception {
  const AiFailure(this.kind, this.message, {this.statusCode});

  final AiFailureKind kind;
  final String message;
  final int? statusCode;

  bool get isCancellation => kind == AiFailureKind.cancelled;

  /// Maps an HTTP status code to a friendly failure.
  factory AiFailure.fromStatus(int status) {
    switch (status) {
      case 401:
        return const AiFailure(AiFailureKind.unauthorized,
            'Authentication failed. The AI API key is missing or invalid.',
            statusCode: 401);
      case 403:
        return const AiFailure(AiFailureKind.forbidden,
            'Access denied. This API key is not permitted to use the AI service.',
            statusCode: 403);
      case 404:
        return const AiFailure(AiFailureKind.notFound,
            'The AI endpoint could not be found. Please check the configuration.',
            statusCode: 404);
      case 408:
        return const AiFailure(AiFailureKind.timeout,
            'The request timed out. Please try again.',
            statusCode: 408);
      case 429:
        return const AiFailure(AiFailureKind.rateLimited,
            'Too many requests. Please wait a moment and try again.',
            statusCode: 429);
      default:
        if (status >= 500) {
          return AiFailure(AiFailureKind.server,
              'The AI service is having trouble (error $status). Please try again later.',
              statusCode: status);
        }
        return AiFailure(AiFailureKind.unknown,
            'Something went wrong (error $status). Please try again.',
            statusCode: status);
    }
  }

  static const AiFailure notConfigured = AiFailure(
    AiFailureKind.notConfigured,
    'The AI Assistant is not configured. An API key is required to chat.',
  );
  static const AiFailure network = AiFailure(
    AiFailureKind.network,
    'No internet connection. Please check your network and try again.',
  );
  static const AiFailure timeout = AiFailure(
    AiFailureKind.timeout,
    'The request timed out. Please try again.',
  );
  static const AiFailure malformed = AiFailure(
    AiFailureKind.malformed,
    'The AI returned an unexpected response. Please try again.',
  );
  static const AiFailure cancelled =
      AiFailure(AiFailureKind.cancelled, 'Generation stopped.');

  @override
  String toString() => 'AiFailure(${kind.name}): $message';
}
