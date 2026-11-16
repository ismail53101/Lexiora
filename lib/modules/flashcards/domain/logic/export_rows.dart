import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';

/// File formats the cards can be exported to.
enum FcExportFormat {
  csv('CSV spreadsheet', 'csv', 'text/csv'),
  anki('Anki text file', 'txt', 'text/plain'),
  xlsx('Excel workbook', 'xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
  pdf('PDF table', 'pdf', 'application/pdf'),
  json('JSON', 'json', 'application/json');

  const FcExportFormat(this.label, this.ext, this.mime);
  final String label;
  final String ext;
  final String mime;
}

String statusLabel(FcCard c) {
  if (c.suspended) return 'Suspended';
  return switch (c.state) {
    FsrsState.newCard => 'New',
    FsrsState.learning => 'Learning',
    FsrsState.relearning => 'Relearning',
    FsrsState.review => 'Review',
  };
}

const List<String> exportHeaders = <String>[
  'Deck', 'Type', 'Front', 'Back', 'Tags', 'Notes', 'Subject', 'Topic',
  'Status', 'Due', 'Stability (days)', 'Lapses',
];

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Header + one row per card, ready for CSV / XLSX / PDF.
List<List<String>> exportMatrix(List<FcCard> cards, Map<String, String> deckNames) =>
    <List<String>>[
      exportHeaders,
      for (final FcCard c in cards)
        <String>[
          deckNames[c.deckId] ?? '',
          c.type.label,
          c.front,
          c.back,
          c.tags.join(', '),
          c.notes ?? '',
          c.subject ?? '',
          c.topic ?? '',
          statusLabel(c),
          c.isNew ? '' : _dateOnly(c.fsrs.due),
          c.fsrs.stability == null ? '' : c.fsrs.stability!.toStringAsFixed(1),
          '${c.lapses}',
        ],
    ];

/// Tab-separated "front, back, tags" with no header: imports straight into
/// Anki ("Import file") and back into this app. Cloze texts keep their
/// `{{c1::…}}` markup, which Anki's Cloze note type understands.
String ankiText(List<FcCard> cards) => encodeDelimited(
      <List<String>>[
        for (final FcCard c in cards)
          <String>[
            c.front,
            c.back,
            c.tags.map((String t) => t.replaceAll(' ', '_')).join(' '),
          ],
      ],
      delimiter: '\t',
    );
