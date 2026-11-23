/// Weekly repeat rules for study sessions ("every Mon and Wed until 30 May").
/// Pure date arithmetic — no I/O.
library;

/// ISO weekdays: Monday = 1 … Sunday = 7 (same as [DateTime.weekday]).
const List<String> weekdayShort = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> weekdayLetters = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The most occurrences a single series may generate.
const int maxSeriesOccurrences = 200;

String dayKeyOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseDayKeyOrNull(String key) {
  final List<String> p = key.split('-');
  if (p.length != 3) return null;
  final int? y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Every date from [startDay] to [untilDay] (both inclusive, `yyyy-MM-dd`) whose
/// weekday is in [weekdays], oldest first. At most [maxOccurrences] dates are
/// returned. Malformed input gives an empty list.
List<String> occurrenceDays({
  required Set<int> weekdays,
  required String startDay,
  required String untilDay,
  int maxOccurrences = maxSeriesOccurrences,
}) {
  final DateTime? start = parseDayKeyOrNull(startDay);
  final DateTime? until = parseDayKeyOrNull(untilDay);
  if (start == null || until == null || weekdays.isEmpty) return const <String>[];
  final List<String> out = <String>[];
  for (DateTime d = start; !d.isAfter(until); d = DateTime(d.year, d.month, d.day + 1)) {
    if (!weekdays.contains(d.weekday)) continue;
    out.add(dayKeyOf(d));
    if (out.length >= maxOccurrences) break;
  }
  return out;
}

/// The last day of a series that runs for [weeks] weeks from [startDay]
/// (a 4-week series starting on 1 Mar ends on 28 Mar).
String untilAfterWeeks(String startDay, int weeks) {
  final DateTime? s = parseDayKeyOrNull(startDay);
  if (s == null) return startDay;
  return dayKeyOf(DateTime(s.year, s.month, s.day + weeks * 7 - 1));
}

/// "Mon, Wed", "Every day", "Weekdays", "Weekends".
String describeWeekdays(Set<int> weekdays) {
  final List<int> days = (weekdays.where((int d) => d >= 1 && d <= 7).toList()..sort());
  if (days.isEmpty) return 'No days';
  if (days.length == 7) return 'Every day';
  if (days.length == 5 && days.every((int d) => d <= 5)) return 'Weekdays';
  if (days.length == 2 && days.first == 6 && days.last == 7) return 'Weekends';
  return days.map((int d) => weekdayShort[d - 1]).join(', ');
}

/// Weekday set ⇄ bitmask (bit 0 = Monday … bit 6 = Sunday), for storage.
int weekdaysToMask(Set<int> weekdays) {
  int mask = 0;
  for (final int d in weekdays) {
    if (d >= 1 && d <= 7) mask |= 1 << (d - 1);
  }
  return mask;
}

Set<int> weekdaysFromMask(int mask) => <int>{
      for (int d = 1; d <= 7; d++)
        if (mask & (1 << (d - 1)) != 0) d,
    };

/// What topic each session of a repeating series gets. The index is stored.
enum RepeatTopicMode {
  /// Every session gets the same topic (good for revision).
  same('Same every time'),

  /// Each session gets the next unfinished topic of the subject's syllabus.
  syllabus('Next from syllabus'),

  /// Only the first session gets the topic; the rest stay blank.
  firstOnly('First session only');

  const RepeatTopicMode(this.label);
  final String label;

  static RepeatTopicMode fromIndex(int i) =>
      i >= 0 && i < RepeatTopicMode.values.length ? RepeatTopicMode.values[i] : RepeatTopicMode.same;
}

/// The topic for each of [count] sessions, in order.
///
/// * [RepeatTopicMode.same]: [typedTopic] for all.
/// * [RepeatTopicMode.firstOnly]: [typedTopic] for the first, then none.
/// * [RepeatTopicMode.syllabus]: [syllabusTopics] (unfinished, in order) minus
///   those in [exclude] (lower-case titles already used). If [typedTopic] is
///   given it is used for the first session, and the sequence continues from
///   that topic's place in the syllabus (or from the start when it is not on
///   the list). When the topics run out the remaining sessions get none.
List<String?> assignRepeatTopics({
  required int count,
  required RepeatTopicMode mode,
  String? typedTopic,
  List<String> syllabusTopics = const <String>[],
  Set<String> exclude = const <String>{},
}) {
  if (count <= 0) return const <String?>[];
  final String? typed = (typedTopic == null || typedTopic.trim().isEmpty) ? null : typedTopic.trim();
  switch (mode) {
    case RepeatTopicMode.same:
      return List<String?>.filled(count, typed);
    case RepeatTopicMode.firstOnly:
      return <String?>[typed, ...List<String?>.filled(count - 1, null)];
    case RepeatTopicMode.syllabus:
      final List<String> pool = <String>[
        for (final String t in syllabusTopics)
          if (!exclude.contains(t.trim().toLowerCase())) t,
      ];
      final List<String?> out = <String?>[];
      int next = 0;
      if (typed != null) {
        out.add(typed);
        final int at = pool.indexWhere((String t) => t.toLowerCase() == typed.toLowerCase());
        if (at >= 0) next = at + 1;
      }
      while (out.length < count) {
        out.add(next < pool.length ? pool[next++] : null);
      }
      return out;
  }
}
