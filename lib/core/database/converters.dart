import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:lexiora/core/models/normalized_rect.dart';

/// Persists a list of [NormalizedRect] as a compact JSON string.
///
/// Highlights, underlines and text-anchored notes store their geometry with
/// this converter, keeping all annotation data in Lexiora's own database rather
/// than mutating the PDF.
class NormalizedRectListConverter
    extends TypeConverter<List<NormalizedRect>, String> {
  const NormalizedRectListConverter();

  @override
  List<NormalizedRect> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const <NormalizedRect>[];
    final List<dynamic> data = jsonDecode(fromDb) as List<dynamic>;
    return data
        .map((dynamic e) =>
            NormalizedRect.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  String toSql(List<NormalizedRect> value) =>
      jsonEncode(value.map((NormalizedRect e) => e.toJson()).toList());
}
