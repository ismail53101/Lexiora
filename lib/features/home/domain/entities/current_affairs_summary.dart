class CurrentAffairsSummary {
  const CurrentAffairsSummary({
    required this.summary,
    required this.keyPoints,
    required this.examRelevance,
  });

  final String summary;
  final List<String> keyPoints;
  final List<String> examRelevance;

  factory CurrentAffairsSummary.fromJson(Map<String, dynamic> json) {
    return CurrentAffairsSummary(
      summary: json['summary']?.toString() ?? '',
      keyPoints: _strings(json['keyPoints']),
      examRelevance: _strings(json['examRelevance']),
    );
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const <String>[];
    return value.map((Object? item) => item?.toString().trim() ?? '')
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
