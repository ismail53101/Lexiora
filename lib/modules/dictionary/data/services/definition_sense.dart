/// Pure, testable helpers that pick the most useful sense for competitive-exam
/// readers from a list of dictionary definitions.
///
/// Dictionary data (WordNet-derived word sets and the free online dictionary)
/// orders senses by corpus frequency, which routinely puts a rare, literary or
/// technical sense first — e.g. "attention" → "the work of providing treatment
/// for or attending to someone" and "tragedy" → "drama in which the
/// protagonist is overcome…". For exam writing the *general* sense is what
/// matters, so we score each definition:
///
///   score = word count + 3 × (domain-indicator words present)
///
/// and prefer the lowest score, breaking ties toward definitions containing
/// general-abstraction markers ("concentration", "process", "situation", …).
library;

/// Words that mark a definition as narrow/technical rather than general.
const Set<String> kDomainIndicators = <String>{
  'drama',
  'protagonist',
  'optical',
  'conic',
  'radiation',
  'infection',
  'stance',
  'erect',
  'courteous',
  'rendered',
  'military',
  'soldier',
  'chemical',
  'molecule',
  'anatomical',
  'apparatus',
  'organism',
  'insect',
  'disease',
  'nautical',
  'grammar',
  'linguistics',
  'physiology',
  'artery',
  'gland',
  'muscle',
  'heraldry',
  'taxation',
};

/// Markers of a general/abstract sense, used only to break ties.
const List<String> kGeneralMarkers = <String>[
  'concentrate',
  'concentration',
  'attention',
  'general',
  'process',
  'state',
  'quality',
  'condition',
  'event',
  'situation',
  'feeling',
  'interest',
  'power',
  'result',
  'cause',
  'act of',
  'to give',
  'to help',
];

bool _hasGeneralMarker(String definition) {
  final String d = definition.toLowerCase();
  return kGeneralMarkers.any(d.contains);
}

/// Returns the index of the best (most general) definition, or `null` when
/// [definitions] is empty.
int? pickBestDefinitionIndex(List<String> definitions) {
  if (definitions.isEmpty) return null;
  if (definitions.length == 1) return 0;

  int? best;
  int bestScore = 1 << 62;
  for (int i = 0; i < definitions.length; i++) {
    final String d = definitions[i].toLowerCase();
    int score = d.split(RegExp(r'\s+')).length;
    for (final String marker in kDomainIndicators) {
      if (d.contains(marker)) score += 3;
    }
    if (score < bestScore) {
      best = i;
      bestScore = score;
    } else if (score == bestScore &&
        best != null &&
        _hasGeneralMarker(definitions[i]) &&
        !_hasGeneralMarker(definitions[best])) {
      best = i;
    }
  }
  return best;
}

/// Returns the best definition, or `null` when [definitions] is empty.
String? pickBestDefinition(List<String> definitions) {
  final int? index = pickBestDefinitionIndex(definitions);
  return index == null ? null : definitions[index];
}
