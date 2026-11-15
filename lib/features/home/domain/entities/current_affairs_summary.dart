class CurrentAffairsSummary {
  const CurrentAffairsSummary({
    required this.summary,
    required this.summaryEn,
    required this.keyPoints,
    required this.examRelevance,
    required this.examSubjects,
  });

  final String summary;
  final List<String> summaryEn;
  final List<String> keyPoints;
  final String examRelevance;
  final List<String> examSubjects;

  factory CurrentAffairsSummary.fromJson(Map<String, dynamic> json) {
    final _ExamRelevanceData relevance = _parseExamRelevance(
      json['examRelevance'],
      json['examSubjects'],
    );

    return CurrentAffairsSummary(
      summary: json['summary']?.toString().trim() ?? '',
      summaryEn: _strings(json['summaryEn']),
      keyPoints: _strings(json['keyPoints']),
      examRelevance: relevance.text,
      examSubjects: relevance.subjects,
    );
  }

  static _ExamRelevanceData _parseExamRelevance(
    Object? rawRelevance,
    Object? rawSubjects,
  ) {
    final List<String> subjects = _strings(rawSubjects);
    String text = '';

    if (rawRelevance is String) {
      text = rawRelevance.trim();
    } else if (rawRelevance is List) {
      final List<String> items = _strings(rawRelevance);
      text = items.join(' • ');
    } else if (rawRelevance is Map) {
      text = _firstString(
        rawRelevance,
        const <String>[
          'text',
          'relevance',
          'description',
          'explanation',
          'whyImportant',
          'why_important',
          'summary',
        ],
      );

      if (subjects.isEmpty) {
        subjects.addAll(
          _firstList(
            rawRelevance,
            const <String>[
              'examSubjects',
              'subjects',
              'exams',
              'topics',
            ],
          ),
        );
      }
    }

    if (text.isEmpty && subjects.isNotEmpty) {
      text = 'Relevant for ${subjects.join(', ')}.';
    }

    return _ExamRelevanceData(
      text: text,
      subjects: subjects.toSet().toList(growable: false),
    );
  }

  static String _firstString(
    Map<dynamic, dynamic> map,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final Object? value = map[key];
      final String text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static List<String> _firstList(
    Map<dynamic, dynamic> map,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final List<String> values = _strings(map[key]);
      if (values.isNotEmpty) return values;
    }
    return const <String>[];
  }

  static List<String> _strings(Object? value) {
    if (value is String) {
      final String item = value.trim();
      return item.isEmpty ? const <String>[] : <String>[item];
    }
    if (value is! List) return const <String>[];

    return value
        .map((Object? item) => item?.toString().trim() ?? '')
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class _ExamRelevanceData {
  const _ExamRelevanceData({
    required this.text,
    required this.subjects,
  });

  final String text;
  final List<String> subjects;
}
