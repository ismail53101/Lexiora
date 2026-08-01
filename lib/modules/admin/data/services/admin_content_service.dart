import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_link.dart';
import 'package:lexiora/modules/admin/domain/entities/admin_note.dart';
import 'package:path_provider/path_provider.dart';

/// Stores the Admin Panel's links, notes, per-PDF subject tags, and PIN lock
/// as a single JSON file under the app's private storage — a deliberately
/// simple, dependency-free store (rather than a new database table, which
/// would need a drift codegen run) since this content is small,
/// admin-curated, and doesn't need querying.
///
/// Every write rewrites the whole file — fine at this scale (tens to low
/// hundreds of entries), and it keeps the format trivially inspectable.
class AdminContentService {
  AdminContentService();

  List<AdminLink>? _linksCache;
  List<AdminNote>? _notesCache;
  Map<String, String>? _pdfSubjectsCache; // documentId -> subject
  String? _pinHashCache; // null once loaded means "no PIN set"
  bool _pinLoaded = false;

  Future<List<AdminLink>> loadLinks() async {
    if (_linksCache != null) return _linksCache!;
    final Map<String, dynamic> data = await _readFile();
    final List<Object?> raw = (data['links'] as List<Object?>?) ?? const [];
    _linksCache = raw
        .whereType<Map<String, dynamic>>()
        .map(AdminLink.fromJson)
        .toList(growable: false);
    return _linksCache!;
  }

  Future<List<AdminNote>> loadNotes() async {
    if (_notesCache != null) return _notesCache!;
    final Map<String, dynamic> data = await _readFile();
    final List<Object?> raw = (data['notes'] as List<Object?>?) ?? const [];
    _notesCache = raw
        .whereType<Map<String, dynamic>>()
        .map(AdminNote.fromJson)
        .toList(growable: false);
    return _notesCache!;
  }

  Future<void> saveLink(AdminLink link) async {
    final List<AdminLink> links = List<AdminLink>.of(await loadLinks());
    final int i = links.indexWhere((AdminLink l) => l.id == link.id);
    if (i >= 0) {
      links[i] = link;
    } else {
      links.insert(0, link);
    }
    _linksCache = links;
    await _persist();
  }

  Future<void> deleteLink(String id) async {
    final List<AdminLink> links = List<AdminLink>.of(await loadLinks())
      ..removeWhere((AdminLink l) => l.id == id);
    _linksCache = links;
    await _persist();
  }

  Future<void> saveNote(AdminNote note) async {
    final List<AdminNote> notes = List<AdminNote>.of(await loadNotes());
    final int i = notes.indexWhere((AdminNote n) => n.id == note.id);
    if (i >= 0) {
      notes[i] = note;
    } else {
      notes.insert(0, note);
    }
    _notesCache = notes;
    await _persist();
  }

  Future<void> deleteNote(String id) async {
    final List<AdminNote> notes = List<AdminNote>.of(await loadNotes())
      ..removeWhere((AdminNote n) => n.id == id);
    _notesCache = notes;
    await _persist();
  }

  // ── Per-PDF subject tags ────────────────────────────────────────────────

  Future<Map<String, String>> loadPdfSubjects() async {
    if (_pdfSubjectsCache != null) return _pdfSubjectsCache!;
    final Map<String, dynamic> data = await _readFile();
    final Map<String, dynamic> raw =
        (data['pdfSubjects'] as Map<String, dynamic>?) ?? const {};
    _pdfSubjectsCache = raw.map(
        (String k, Object? v) => MapEntry<String, String>(k, v as String));
    return _pdfSubjectsCache!;
  }

  Future<void> setPdfSubject(String documentId, String? subject) async {
    final Map<String, String> map =
        Map<String, String>.of(await loadPdfSubjects());
    if (subject == null || subject.trim().isEmpty) {
      map.remove(documentId);
    } else {
      map[documentId] = subject.trim();
    }
    _pdfSubjectsCache = map;
    await _persist();
  }

  // ── PIN lock ─────────────────────────────────────────────────────────────

  /// Whether a PIN has been configured. `false` means the Admin Panel opens
  /// with no lock at all — the caller is responsible for prompting to set
  /// one on first use rather than assuming it's already protected.
  Future<bool> hasPin() async => (await _loadPinHash()) != null;

  Future<bool> verifyPin(String pin) async {
    final String? hash = await _loadPinHash();
    if (hash == null) return false;
    return hash == _hash(pin);
  }

  Future<void> setPin(String pin) async {
    _pinHashCache = _hash(pin);
    _pinLoaded = true;
    await _persist();
  }

  Future<void> clearPin() async {
    _pinHashCache = null;
    _pinLoaded = true;
    await _persist();
  }

  Future<String?> _loadPinHash() async {
    if (_pinLoaded) return _pinHashCache;
    final Map<String, dynamic> data = await _readFile();
    _pinHashCache = data['pinHash'] as String?;
    _pinLoaded = true;
    return _pinHashCache;
  }

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  // ── File I/O ─────────────────────────────────────────────────────────────

  Future<File> _file() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/admin_content.json');
  }

  Future<Map<String, dynamic>> _readFile() async {
    try {
      final File file = await _file();
      if (!await file.exists()) return <String, dynamic>{};
      final String text = await file.readAsString();
      if (text.trim().isEmpty) return <String, dynamic>{};
      final Object? decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on Object catch (e) {
      AppLogger.w('AdminContentService: read failed: $e');
      return <String, dynamic>{};
    }
  }

  Future<void> _persist() async {
    try {
      // Persisting always rewrites the whole file, so every section must be
      // populated first — otherwise saving e.g. a link while notes/PIN
      // haven't been loaded yet this session would silently wipe them out.
      final List<AdminLink> links = await loadLinks();
      final List<AdminNote> notes = await loadNotes();
      final Map<String, String> pdfSubjects = await loadPdfSubjects();
      final String? pinHash = await _loadPinHash();

      final File file = await _file();
      final Map<String, dynamic> data = <String, dynamic>{
        'links': links.map((AdminLink l) => l.toJson()).toList(),
        'notes': notes.map((AdminNote n) => n.toJson()).toList(),
        'pdfSubjects': pdfSubjects,
        'pinHash': pinHash,
      };
      await file.writeAsString(jsonEncode(data));
    } on Object catch (e) {
      AppLogger.w('AdminContentService: write failed: $e');
    }
  }
}
