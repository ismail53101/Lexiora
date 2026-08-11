/// Pure helper: candidate base forms for fuzzy vocabulary matching.
///
/// Vocabulary packs store base forms ("Contribute", "Focus"), but readers
/// often select inflected words ("contributing", "focused", "studies").
/// [baseForms] returns the exact word followed by progressively de-inflected
/// candidates so a lookup can match "contributing" against the pack's
/// "Contribute" entry. Order is significant — callers should try candidates
/// in order and use the first hit.
List<String> baseForms(String wordLower) {
  final String w = wordLower.trim().toLowerCase();
  if (w.isEmpty) return const <String>[];
  final List<String> out = <String>[w];

  void add(String candidate) {
    if (candidate.isNotEmpty && !out.contains(candidate)) out.add(candidate);
  }

  // studies → study ; studied → study
  if (w.endsWith('ies')) {
    add('${w.substring(0, w.length - 3)}y');
  } else if (w.endsWith('ied')) {
    add('${w.substring(0, w.length - 3)}y');
  }

  if (w.endsWith('ing')) {
    final String stem = w.substring(0, w.length - 3);
    add(stem);
    add('${stem}e'); // contributing → contribute
    if (stem.length >= 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
      add(stem.substring(0, stem.length - 1)); // running → run
    }
  } else if (w.endsWith('ed')) {
    final String stem = w.substring(0, w.length - 2);
    add(stem);
    add('${stem}e'); // focused → focuse (harmless miss), studied → studie
    if (stem.length >= 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
      add(stem.substring(0, stem.length - 1)); // stopped → stop
    }
  }

  if (w.endsWith('es') && w.length > 3) {
    add(w.substring(0, w.length - 2)); // boxes → box ; watches → watch
    add(w.substring(0, w.length - 1)); // contributes → contribute
  } else if (w.endsWith('s') && !w.endsWith('ss') && w.length > 3) {
    add(w.substring(0, w.length - 1)); // books → book
  }

  if (w.endsWith('ly') && w.length > 4) {
    add(w.substring(0, w.length - 2)); // quickly → quick
  }

  return out;
}
