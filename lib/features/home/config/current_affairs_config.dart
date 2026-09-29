class CurrentAffairsConfig {
  const CurrentAffairsConfig({required this.baseUrl});

  factory CurrentAffairsConfig.fromEnvironment() => const CurrentAffairsConfig(
        baseUrl: String.fromEnvironment('SAPIORA_CURRENT_AFFAIRS_BASE_URL'),
      );

  final String baseUrl;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Uri get latestUri {
    final String base = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final String path = base.endsWith('/api/current-affairs/latest')
        ? ''
        : '/api/current-affairs/latest';
    return Uri.parse('$base$path');
  }
}
