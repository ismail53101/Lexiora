class CurrentAffairsConfig {
  const CurrentAffairsConfig({required this.baseUrl});

  factory CurrentAffairsConfig.fromEnvironment() => const CurrentAffairsConfig(
        // Keep the live feed working in locally-installed APKs too. CI can
        // still override this with --dart-define when a different gateway is
        // required.
        baseUrl: String.fromEnvironment(
          'SAPIORA_CURRENT_AFFAIRS_BASE_URL',
          defaultValue:
              'https://sapiora-ai-worker.ismaillasharibaloch53.workers.dev',
        ),
      );

  final String baseUrl;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Uri get summaryBaseUri {
    final String base = baseUrl.trim().replaceFirst(RegExp(r'/+
    final String base = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final String path = base.endsWith('/api/current-affairs/latest')
        ? ''
        : '/api/current-affairs/latest';
    return Uri.parse('$base$path');
  }
}
), '');
    return Uri.parse(base);
  }

  Uri summaryUri(String storyId) {
    final String base = summaryBaseUri.toString().replaceFirst(RegExp(r'/+
    final String base = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final String path = base.endsWith('/api/current-affairs/latest')
        ? ''
        : '/api/current-affairs/latest';
    return Uri.parse('$base$path');
  }
}
), '');
    return Uri.parse('$base/api/current-affairs/summary?id=${Uri.encodeQueryComponent(storyId)}');
  }

  Uri get latestUri {
    final String base = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final String path = base.endsWith('/api/current-affairs/latest')
        ? ''
        : '/api/current-affairs/latest';
    return Uri.parse('$base$path');
  }
}
