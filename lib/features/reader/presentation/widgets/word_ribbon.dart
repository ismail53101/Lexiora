import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

/// Read-only snapshot of the formatting at the caret / selection.
class WordRibbonState {
  const WordRibbonState({
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strike,
    required this.vertAlign,
    required this.sizePoints,
    required this.font,
    required this.color,
    required this.highlight,
    required this.alignment,
    required this.isRtl,
    required this.canUndo,
    required this.canRedo,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final WmlVertAlign vertAlign;
  final int sizePoints;
  final String font;
  final String color;
  final String? highlight;
  final WmlJustification alignment;
  final bool isRtl;
  final bool canUndo;
  final bool canRedo;
}

/// One entry of the styles gallery.
class WordStyleSpec {
  const WordStyleSpec(
    this.name, {
    this.headingLevel,
    this.sizePt,
    this.bold,
    this.italic,
    this.color,
    this.align,
    this.spaceBefore,
    this.spaceAfter,
    this.lineSpacing,
    this.indentLeft,
  });

  final String name;

  /// 0 = Normal, 1..4 = Heading 1..4 (uses the editor's heading command).
  final int? headingLevel;
  final double? sizePt;
  final bool? bold;
  final bool? italic;
  final String? color;
  final WmlJustification? align;
  final double? spaceBefore;
  final double? spaceAfter;
  final double? lineSpacing;
  final double? indentLeft;
}

const List<WordStyleSpec> kWordStyles = <WordStyleSpec>[
  WordStyleSpec('Normal', headingLevel: 0),
  WordStyleSpec('No Spacing', headingLevel: 0, spaceAfter: 0, lineSpacing: 1.0),
  WordStyleSpec('Heading 1', headingLevel: 1),
  WordStyleSpec('Heading 2', headingLevel: 2),
  WordStyleSpec('Heading 3', headingLevel: 3),
  WordStyleSpec('Heading 4', headingLevel: 4),
  WordStyleSpec('Title', sizePt: 28, bold: false, color: '0F4761', spaceAfter: 4),
  WordStyleSpec('Subtitle', sizePt: 14, color: '595959', spaceAfter: 8),
  WordStyleSpec('Subtle Emphasis', italic: true, color: '595959'),
  WordStyleSpec('Emphasis', italic: true),
  WordStyleSpec('Intense Emphasis', italic: true, bold: true, color: '0F4761'),
  WordStyleSpec('Strong', bold: true),
  WordStyleSpec('Quote',
      italic: true,
      color: '404040',
      align: WmlJustification.center,
      indentLeft: 36,
      spaceBefore: 10,
      spaceAfter: 10),
  WordStyleSpec('Intense Quote',
      italic: true,
      bold: true,
      color: '0F4761',
      align: WmlJustification.center,
      indentLeft: 36,
      spaceBefore: 12,
      spaceAfter: 12),
  WordStyleSpec('Book Title', bold: true, italic: true),
  WordStyleSpec('List Paragraph', indentLeft: 36),
];

/// Everything the ribbon can ask the editor to do.
class WordRibbonActions {
  const WordRibbonActions({
    required this.toggleBold,
    required this.toggleItalic,
    required this.toggleUnderline,
    required this.toggleStrike,
    required this.setVertAlign,
    required this.setFont,
    required this.setSize,
    required this.setColor,
    required this.setHighlight,
    required this.clearFormatting,
    required this.applyParagraph,
    required this.applyList,
    required this.applyStyle,
    required this.undo,
    required this.redo,
    required this.insertTable,
    required this.insertPageBreak,
    required this.find,
    required this.close,
  });

  final VoidCallback toggleBold;
  final VoidCallback toggleItalic;
  final VoidCallback toggleUnderline;
  final VoidCallback toggleStrike;
  final ValueChanged<WmlVertAlign> setVertAlign;
  final ValueChanged<String> setFont;
  final ValueChanged<int> setSize;
  final ValueChanged<String> setColor;
  final ValueChanged<String?> setHighlight;
  final VoidCallback clearFormatting;
  final void Function(void Function(WmlParagraphProps p) update) applyParagraph;
  final void Function({required bool numbered}) applyList;
  final ValueChanged<WordStyleSpec> applyStyle;
  final VoidCallback undo;
  final VoidCallback redo;
  final VoidCallback insertTable;
  final VoidCallback insertPageBreak;

  /// Finds [query]; returns how many matches exist and the 1-based position of
  /// the selected one. [step] 0 = first match, 1 = next, -1 = previous.
  final ({int count, int index}) Function(String query, int step) find;
  final VoidCallback close;
}

enum _Tab { home, insert }

enum _Page { main, styles, paragraph, find }

/// Dark, Word-like ribbon panel: Home / Insert tabs, drill-down pages for
/// Styles, Paragraph and Find.
class WordRibbon extends StatefulWidget {
  const WordRibbon({super.key, required this.state, required this.on});

  final WordRibbonState state;
  final WordRibbonActions on;

  @override
  State<WordRibbon> createState() => _WordRibbonState();
}

class _WordRibbonState extends State<WordRibbon> {
  static const Color _bg = Color(0xFF1B1B1B);
  static const Color _row = Color(0xFF242424);
  static const Color _on = Color(0xFF3B3B3B);
  static const Color _accent = Color(0xFF5AA2FF);

  _Tab _tab = _Tab.home;
  _Page _page = _Page.main;
  bool _showFonts = false;
  bool _showColors = false;
  bool _showHighlights = false;
  bool _showMore = false;
  int _findCount = 0;
  int _findPos = 0;
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  WordRibbonState get _s => widget.state;
  WordRibbonActions get _a => widget.on;

  static const List<String> _fonts = <String>[
    'Arial',
    'Times New Roman',
    'Courier New',
    'Liberation Sans',
    'Liberation Serif',
    'Liberation Mono',
  ];
  static const List<String> _colors = <String>[
    '000000', '595959', 'C00000', 'FF0000', 'ED7D31', 'FFC000',
    '92D050', '00B050', '00B0F0', '0070C0', '7030A0', 'FFFFFF',
  ];
  static const List<String> _highlights = <String>[
    'FFFF00', '00FF00', '00FFFF', 'FF00FF', 'FFCC80', 'C8E6C9', 'E1BEE7',
  ];

  Color _hex(String hex) {
    final String h = hex.replaceAll('#', '');
    final int? v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return Color(v ?? 0xFF000000);
  }

  // ---- building blocks --------------------------------------------------

  Widget _header() {
    final String title = switch (_page) {
      _Page.styles => 'Styles',
      _Page.paragraph => 'Paragraph',
      _Page.find => 'Find',
      _Page.main => _tab == _Tab.home ? 'Home' : 'Insert',
    };
    return Container(
      height: 44,
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: <Widget>[
          if (_page != _Page.main)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _page = _Page.main),
            )
          else
            const SizedBox(width: 12),
          if (_page == _Page.main)
            PopupMenuButton<_Tab>(
              color: _row,
              onSelected: (_Tab t) => setState(() => _tab = t),
              itemBuilder: (BuildContext c) => const <PopupMenuEntry<_Tab>>[
                PopupMenuItem<_Tab>(value: _Tab.home, child: Text('Home')),
                PopupMenuItem<_Tab>(value: _Tab.insert, child: Text('Insert')),
              ],
              child: Row(children: <Widget>[
                Text(title,
                    style: const TextStyle(
                        color: _accent, fontSize: 17, fontWeight: FontWeight.w600)),
                const Icon(Icons.unfold_more, color: Colors.white70, size: 20),
              ]),
            )
          else
            Text(title,
                style: const TextStyle(
                    color: _accent, fontSize: 17, fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.undo,
                color: _s.canUndo ? Colors.white : Colors.white24),
            onPressed: _s.canUndo ? _a.undo : null,
          ),
          IconButton(
            icon: Icon(Icons.redo,
                color: _s.canRedo ? Colors.white : Colors.white24),
            onPressed: _s.canRedo ? _a.redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onPressed: _a.close,
          ),
        ],
      ),
    );
  }

  Widget _toggle(IconData icon, bool active, VoidCallback onTap,
      {String? label}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          color: active ? _on : _row,
          child: label != null
              ? Text(label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      decoration: label == 'ab' ? TextDecoration.lineThrough : null))
              : Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String text, {VoidCallback? onTap, bool chevron = false, Color? iconColor, Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        color: _row,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: <Widget>[
          Icon(icon, color: iconColor ?? Colors.white, size: 22),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
          if (trailing != null) trailing,
          if (chevron) const Icon(Icons.chevron_right, color: Colors.white54),
        ]),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: Color(0xFF111111));

  Widget _swatches(List<String> values, ValueChanged<String> onPick, {VoidCallback? onNone}) {
    return Container(
      color: _row,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          if (onNone != null)
            GestureDetector(
              onTap: onNone,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54),
                ),
                child: const Icon(Icons.block, color: Colors.white70, size: 18),
              ),
            ),
          for (final String v in values)
            GestureDetector(
              onTap: () => onPick(v),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _hex(v),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _segment(List<Widget> children) => SizedBox(
        height: 46,
        child: Row(children: children),
      );

  // ---- pages ----------------------------------------------------------------

  Widget _homeMain() {
    final WordRibbonState s = _s;
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        // Font name + size
        Container(
          height: 50,
          color: _row,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _showFonts = !_showFonts),
                child: Row(children: <Widget>[
                  Flexible(
                    child: Text(s.font,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white70),
                ]),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: () => _a.setSize(math.max(6, s.sizePoints - 1)),
            ),
            Text('${s.sizePoints}',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _a.setSize(math.min(96, s.sizePoints + 1)),
            ),
          ]),
        ),
        if (_showFonts)
          Container(
            color: _row,
            child: Column(children: <Widget>[
              for (final String f in _fonts)
                ListTile(
                  dense: true,
                  title: Text(f, style: const TextStyle(color: Colors.white)),
                  trailing: f == s.font ? const Icon(Icons.check, color: _accent) : null,
                  onTap: () {
                    _a.setFont(f);
                    setState(() => _showFonts = false);
                  },
                ),
            ]),
          ),
        _divider(),
        _segment(<Widget>[
          _toggle(Icons.format_bold, s.bold, _a.toggleBold),
          _toggle(Icons.format_italic, s.italic, _a.toggleItalic),
          _toggle(Icons.format_underlined, s.underline, _a.toggleUnderline),
          _toggle(Icons.strikethrough_s, s.strike, _a.toggleStrike),
        ]),
        _divider(),
        _item(
          Icons.border_color,
          'Highlight',
          iconColor: s.highlight == null ? Colors.white : _hex(s.highlight!),
          chevron: true,
          onTap: () => setState(() => _showHighlights = !_showHighlights),
        ),
        if (_showHighlights)
          _swatches(_highlights, (String v) {
            _a.setHighlight(v);
            setState(() => _showHighlights = false);
          }, onNone: () {
            _a.setHighlight(null);
            setState(() => _showHighlights = false);
          }),
        _divider(),
        _item(
          Icons.format_color_text,
          'Font Color',
          iconColor: _hex(s.color),
          chevron: true,
          onTap: () => setState(() => _showColors = !_showColors),
        ),
        if (_showColors)
          _swatches(_colors, (String v) {
            _a.setColor(v);
            setState(() => _showColors = false);
          }),
        _divider(),
        _item(Icons.format_clear, 'Clear Formatting', onTap: _a.clearFormatting),
        _divider(),
        _item(Icons.text_format, 'More Formatting',
            chevron: true, onTap: () => setState(() => _showMore = !_showMore)),
        if (_showMore)
          _segment(<Widget>[
            _toggle(Icons.subscript, s.vertAlign == WmlVertAlign.subscript, () {
              _a.setVertAlign(s.vertAlign == WmlVertAlign.subscript
                  ? WmlVertAlign.baseline
                  : WmlVertAlign.subscript);
            }),
            _toggle(Icons.superscript, s.vertAlign == WmlVertAlign.superscript, () {
              _a.setVertAlign(s.vertAlign == WmlVertAlign.superscript
                  ? WmlVertAlign.baseline
                  : WmlVertAlign.superscript);
            }),
          ]),
        _divider(),
        _item(Icons.format_list_bulleted, 'Bullets', onTap: () => _a.applyList(numbered: false)),
        _divider(),
        _item(Icons.format_list_numbered, 'Numbering', onTap: () => _a.applyList(numbered: true)),
        _divider(),
        _segment(<Widget>[
          _toggle(Icons.format_indent_decrease, false, () => _indent(-36)),
          _toggle(Icons.format_indent_increase, false, () => _indent(36)),
          _toggle(Icons.format_textdirection_l_to_r, !s.isRtl,
              () => _a.applyParagraph((WmlParagraphProps p) => p.rightToLeft = false)),
          _toggle(Icons.format_textdirection_r_to_l, s.isRtl,
              () => _a.applyParagraph((WmlParagraphProps p) => p.rightToLeft = true)),
        ]),
        _divider(),
        _segment(<Widget>[
          _toggle(Icons.format_align_left, s.alignment == WmlJustification.left,
              () => _a.applyParagraph((WmlParagraphProps p) => p.justification = WmlJustification.left)),
          _toggle(Icons.format_align_center, s.alignment == WmlJustification.center,
              () => _a.applyParagraph((WmlParagraphProps p) => p.justification = WmlJustification.center)),
          _toggle(Icons.format_align_right, s.alignment == WmlJustification.right,
              () => _a.applyParagraph((WmlParagraphProps p) => p.justification = WmlJustification.right)),
          _toggle(Icons.format_align_justify, s.alignment == WmlJustification.justify,
              () => _a.applyParagraph((WmlParagraphProps p) => p.justification = WmlJustification.justify)),
        ]),
        _divider(),
        _item(Icons.format_line_spacing, 'Paragraph Formatting',
            chevron: true, onTap: () => setState(() => _page = _Page.paragraph)),
        _divider(),
        _item(Icons.style, 'Styles',
            chevron: true, onTap: () => setState(() => _page = _Page.styles)),
        _divider(),
        _item(Icons.search, 'Find', onTap: () => setState(() => _page = _Page.find)),
      ],
    );
  }

  void _indent(double delta) {
    _a.applyParagraph((WmlParagraphProps p) {
      final WmlIndent i = p.indent;
      p.indent = WmlIndent(
        left: math.max(0, i.left + delta),
        right: i.right,
        firstLine: i.firstLine,
        hanging: i.hanging,
      );
    });
  }

  Widget _insertTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _item(Icons.table_chart, 'Table', onTap: _a.insertTable),
        _divider(),
        _item(Icons.note_add, 'Page Break', onTap: _a.insertPageBreak),
      ],
    );
  }

  Widget _stylesPage() {
    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 2.6,
      children: <Widget>[
        for (final WordStyleSpec st in kWordStyles)
          InkWell(
            onTap: () {
              _a.applyStyle(st);
            },
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                st.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: st.color != null ? _hex(st.color!) : Colors.black,
                  fontWeight: (st.bold ?? (st.headingLevel != null && st.headingLevel! > 0))
                      ? FontWeight.w700
                      : FontWeight.w400,
                  fontStyle: (st.italic ?? false) ? FontStyle.italic : FontStyle.normal,
                  fontSize: math.min(22, math.max(13, (st.sizePt ?? (st.headingLevel == 1 ? 20 : st.headingLevel == 2 ? 17 : 14)))),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _paragraphPage() {
    Widget header(String t) => Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(t, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        );
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        header('Special Indent'),
        _item(Icons.format_indent_decrease, 'None',
            onTap: () => _a.applyParagraph((WmlParagraphProps p) {
                  final WmlIndent i = p.indent;
                  p.indent = WmlIndent(left: i.left, right: i.right);
                })),
        _divider(),
        _item(Icons.format_indent_increase, 'First Line',
            onTap: () => _a.applyParagraph((WmlParagraphProps p) {
                  final WmlIndent i = p.indent;
                  p.indent = WmlIndent(left: i.left, right: i.right, firstLine: 36);
                })),
        _divider(),
        _item(Icons.format_align_left, 'Hanging',
            onTap: () => _a.applyParagraph((WmlParagraphProps p) {
                  final WmlIndent i = p.indent;
                  p.indent = WmlIndent(left: i.left, right: i.right, hanging: 36);
                })),
        header('Line Spacing'),
        Container(
          color: _row,
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
            for (final double v in <double>[1.0, 1.15, 1.5, 2.0, 2.5, 3.0])
              ChoiceChip(
                label: Text(v.toString()),
                selected: false,
                onSelected: (_) => _a.applyParagraph((WmlParagraphProps p) {
                  p.lineSpacing = v;
                  p.lineSpacingRule = WmlLineSpacingRule.auto;
                  p.explicitLineSpacing = true;
                }),
              ),
          ]),
        ),
        header('Spacing'),
        _item(Icons.vertical_align_top, 'Add Space Before Paragraph',
            onTap: () => _a.applyParagraph((WmlParagraphProps p) {
                  p.spacingBefore = 12;
                  p.explicitSpacingBefore = true;
                })),
        _divider(),
        _item(Icons.vertical_align_top, 'Remove Space Before Paragraph',
            onTap: () => _a.applyParagraph((WmlParagraphProps p) {
                  p.spacingBefore = 0;
                  p.explicitSpacingBefore = true;
                })),
        _divider(),
        _item(Icons.vertical_align_bottom, 'Add Space After Paragraph',
            onTap: () => _a.applyParagraph((WmlParagraphProps p) {
                  p.spacingAfter = 12;
                  p.explicitSpacingAfter = true;
                })),
        _divider(),
        _item(Icons.vertical_align_bottom, 'Remove Space After Paragraph',
            onTap: () => _a.applyParagraph((WmlParagraphProps p) {
                  p.spacingAfter = 0;
                  p.explicitSpacingAfter = true;
                })),
      ],
    );
  }

  Widget _findPage() {
    void run(int step) {
      final String q = _query.text;
      if (q.isEmpty) {
        setState(() {
          _findCount = 0;
          _findPos = 0;
        });
        return;
      }
      final ({int count, int index}) result = _a.find(q, step);
      setState(() {
        _findCount = result.count;
        _findPos = result.index;
      });
    }

    return Container(
      color: _row,
      padding: const EdgeInsets.all(16),
      child: Column(children: <Widget>[
        TextField(
          controller: _query,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => run(1),
          onChanged: (_) => run(0),
          decoration: const InputDecoration(
            hintText: 'Find in document',
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search, color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: <Widget>[
          Text(
            _query.text.isEmpty
                ? ''
                : _findCount == 0
                    ? 'No results'
                    : '$_findPos of $_findCount',
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
            onPressed: () => run(-1),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onPressed: () => run(1),
          ),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_page) {
      _Page.styles => _stylesPage(),
      _Page.paragraph => _paragraphPage(),
      _Page.find => _findPage(),
      _Page.main => _tab == _Tab.home ? _homeMain() : _insertTab(),
    };
    return Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.dark),
      child: Material(
        color: _bg,
        child: Column(children: <Widget>[
          _header(),
          const Divider(height: 1, thickness: 1, color: Color(0xFF111111)),
          Expanded(child: body),
        ]),
      ),
    );
  }
}
