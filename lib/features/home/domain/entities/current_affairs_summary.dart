class CurrentAffairsSummary {
  const CurrentAffairsSummary({
    required this.summary,
    required this.summaryEn,
    required this.summaryUr,
    required this.keyPoints,
    required this.examRelevance,
    required this.examSubjects,
  });

  final String summary;
  final List<String> summaryEn;
  final String summaryUr;
  final List<String> keyPoints;
  final String examRelevance;
  final List<String> examSubjects;

  factory CurrentAffairsSummary.fromJson(Map<String, dynamic> json) {
    return CurrentAffairsSummary(
      summary: json['summary']?.toString() ?? '',
      summaryEn: _strings(json['summaryEn']),
      summaryUr: json['summaryUr']?.toString().trim() ?? '',
      keyPoints: _strings(json['keyPoints']),
      examRelevance: json['examRelevance']?.toString().trim() ?? '',
      examSubjects: _strings(json['examSubjects']),
    );
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((Object? item) => item?.toString().trim() ?? '')
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}