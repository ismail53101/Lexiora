class CurrentAffairsConfig {
  const CurrentAffairsConfig({
    required this.baseUrl,
    required this.summaryBaseUrl,
  });

  factory CurrentAffairsConfig.fromEnvironment() => const CurrentAffairsConfig(
        baseUrl: String.fromEnvironment(
          'SAPIORA_CURRENT_AFFAIRS_BASE_URL',
          defaultValue:
              'https://sapiora-ai-worker.ismaillasharibaloch53.workers.dev',
        ),
        summaryBaseUrl: String.fromEnvironment(
          'SAPIORA_CURRENT_AFFAIRS_SUMMARY_BASE_URL',
          defaultValue: '',
        ),
      );

  final String baseUrl;
  final String summaryBaseUrl;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Uri get latestUri {
    final String base = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final String path = base.endsWith('/api/current-affairs/latest')
        ? ''
        : '/api/current-affairs/latest';
    return Uri.parse('$base$path');
  }

  Uri summaryUri(String storyId) {
    final String base =
        summaryBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse(
      '$base/api/current-affairs/summary?id=${Uri.encodeQueryComponent(storyId)}',
    );
  }
}
