import 'package:lexiora/modules/flashcards/data/flashcard_schema.dart';

/// Rows of every table, keyed by table name, in the exact column set of
/// [FcSchema]. Timestamps are Unix seconds.
class BackupData {
  const BackupData({
    required this.decks,
    required this.cards,
    required this.logs,
    required this.states,
    required this.settings,
    required this.version,
  });

  final List<Map<String, Object?>> decks;
  final List<Map<String, Object?>> cards;
  final List<Map<String, Object?>> logs;
  final List<Map<String, Object?>> states;
  final List<Map<String, Object?>> settings;

  /// 1 = old Drift JSON (camelCase, millisecond timestamps, no FSRS state);
  /// 2 = this engine's format.
  final int version;
}

const String backupType = 'flashcards_backup';
const int backupVersion = 2;

Map<String, dynamic> encodeBackup(BackupData d, DateTime exportedAt) =>
    <String, dynamic>{
      'app': 'sapiora',
      'type': backupType,
      'version': backupVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'decks': d.decks,
      'cards': d.cards,
      'logs': d.logs,
      'states': d.states,
      'settings': d.settings,
    };

String _snake(String camel) => camel.replaceAllMapped(
    RegExp(r'[A-Z]'), (Match m) => '_${m.group(0)!.toLowerCase()}');

Object? _normalise(String col, Object? v, {required bool millis}) {
  if (v == null) return null;
  if (FcSchema.timeCols.contains(col)) {
    if (v is num) return millis ? v.toInt() ~/ 1000 : v.toInt();
    if (v is String) {
      final DateTime? t = DateTime.tryParse(v);
      return t == null ? null : t.millisecondsSinceEpoch ~/ 1000;
    }
  }
  if (v is bool) return v ? 1 : 0;
  return v;
}

List<Map<String, Object?>> _rows(
  Object? raw,
  List<String> cols, {
  required bool snakeCase,
  required bool millis,
}) {
  if (raw is! List) return const <Map<String, Object?>>[];
  final List<Map<String, Object?>> out = <Map<String, Object?>>[];
  for (final Object? e in raw) {
    if (e is! Map) continue;
    final Map<String, Object?> src = <String, Object?>{
      for (final MapEntry<Object?, Object?> kv in e.entries)
        (snakeCase ? _snake('${kv.key}') : '${kv.key}'): kv.value,
    };
    out.add(<String, Object?>{
      for (final String c in cols) c: _normalise(c, src[c], millis: millis),
    });
  }
  return out;
}

/// Reads a backup of either version. Throws [FormatException] when [json] is
/// not a flashcards backup.
BackupData decodeBackup(Map<String, dynamic> json) {
  if (json['type'] != backupType) {
    throw const FormatException('Not a flashcards backup file.');
  }
  final int version = (json['version'] as num?)?.toInt() ?? 1;
  if (version > backupVersion) {
    throw const FormatException(
        'This backup was made by a newer version of the app.');
  }
  final bool v1 = version < 2;
  return BackupData(
    version: version,
    decks: _rows(json['decks'], FcSchema.deckCols, snakeCase: v1, millis: v1),
    cards: _rows(json['cards'], FcSchema.cardCols, snakeCase: v1, millis: v1),
    logs: _rows(json['logs'], FcSchema.logCols, snakeCase: v1, millis: v1),
    states:
        _rows(json['states'], FcSchema.stateCols, snakeCase: false, millis: false),
    settings: _rows(json['settings'], FcSchema.settingsCols,
        snakeCase: false, millis: false),
  );
}
