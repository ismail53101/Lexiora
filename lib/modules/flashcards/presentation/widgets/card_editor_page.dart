import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/modules/flashcards/domain/fsrs/fsrs_scheduler.dart';
import 'package:lexiora/modules/flashcards/domain/logic/cloze.dart';
import 'package:lexiora/modules/flashcards/domain/logic/csv_codec.dart';
import 'package:lexiora/modules/flashcards/domain/models/fc_models.dart';
import 'package:lexiora/modules/flashcards/domain/repositories/fc_repository.dart';
import 'package:lexiora/modules/flashcards/presentation/providers/fc_providers.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_widgets.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/fc_content.dart';
import 'package:lexiora/modules/flashcards/presentation/widgets/card_editor_utils.dart';
import 'package:lexiora/modules/dictionary/presentation/providers/dictionary_providers.dart';

/// Opens the card editor; resolves to true when something was saved.
Future<bool?> openCardEditor(BuildContext context, {required String deckId, String? cardId}) =>
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext c) => FcCardEditorPage(deckId: deckId, cardId: cardId),
      ),
    );

/// Create or edit one card (basic, cloze or type-the-answer) with a live preview.
class _VoiceListeningSheet extends StatefulWidget {
  const _VoiceListeningSheet({required this.transcript});
  final ValueNotifier<String> transcript;

  @override
  State<_VoiceListeningSheet> createState() => _VoiceListeningSheetState();
}

class _VoiceListeningSheetState extends State<_VoiceListeningSheet>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                cs.primary.withValues(alpha: 0.94),
                cs.surface.withValues(alpha: 0.96),
                Colors.cyan.withValues(alpha: 0.72),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                blurRadius: 34,
                spreadRadius: 2,
                color: cs.primary.withValues(alpha: 0.28),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (BuildContext context, Widget? child) {
                    final double value = _pulse.value;
                    return Container(
                      width: 82 + value * 8,
                      height: 82 + value * 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: cs.primary.withValues(alpha: 0.72),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            blurRadius: 22 + value * 12,
                            spreadRadius: 4,
                            color: cs.primary.withValues(alpha: 0.38),
                          ),
                          BoxShadow(
                            blurRadius: 18,
                            spreadRadius: 1,
                            color: Colors.cyan.withValues(alpha: 0.24),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: <Color>[
                            cs.primary.withValues(alpha: 0.96),
                            Colors.cyan.withValues(alpha: 0.82),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.mic_rounded, size: 38, color: Colors.white),
                    );
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Listening…',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Speak now, I’m listening to your voice',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 14),
                AnimatedBuilder(
                  animation: _wave,
                  builder: (BuildContext context, Widget? child) {
                    return SizedBox(
                      height: 42,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _VoiceWavePainter(
                          progress: _wave.value,
                          primary: cs.primary,
                          secondary: Colors.cyanAccent,
                        ),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<String>(
                  valueListenable: widget.transcript,
                  builder: (BuildContext context, String value, Widget? child) {
                    if (value.trim().isEmpty) return const SizedBox(height: 2);
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 54),
                      child: SingleChildScrollView(
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceWavePainter extends CustomPainter {
  const _VoiceWavePainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..strokeCap = StrokeCap.round;
    const int bars = 31;
    final double gap = size.width / (bars + 1);
    for (int i = 0; i < bars; i++) {
      final double phase = (i / bars) * math.pi * 2;
      final double motion = math.sin((progress * math.pi * 2) + phase);
      final double envelope = 0.25 + 0.75 * math.sin((i / (bars - 1)) * math.pi);
      final double height = 5 + (motion.abs() * envelope * 27);
      paint
        ..strokeWidth = 3.2
        ..color = Color.lerp(primary, secondary, i / (bars - 1))!;
      final double x = gap * (i + 1);
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceWavePainter oldDelegate) => oldDelegate.progress != progress;
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.cloze,
    required this.onCloze,
    required this.onMic,
    required this.onImage,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onClear,
    required this.boldActive,
    required this.italicActive,
    required this.underlineActive,
    required this.listening,
  });

  final bool cloze;
  final VoidCallback onCloze;
  final VoidCallback onMic;
  final VoidCallback onImage;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onClear;
  final bool boldActive;
  final bool italicActive;
  final bool underlineActive;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 2,
      children: <Widget>[
        IconButton(tooltip: 'Cloze mode', icon: const Icon(Icons.crop_free), color: cloze ? cs.primary : null, onPressed: onCloze),
        IconButton(tooltip: 'Voice input', icon: Icon(listening ? Icons.mic : Icons.mic_none), color: listening ? cs.primary : null, onPressed: onMic),
        IconButton(tooltip: 'Insert image', icon: const Icon(Icons.image_outlined), onPressed: onImage),
        IconButton(tooltip: 'Bold', icon: const Icon(Icons.format_bold), color: boldActive ? cs.primary : null, onPressed: onBold),
        IconButton(tooltip: 'Italic', icon: const Icon(Icons.format_italic), color: italicActive ? cs.primary : null, onPressed: onItalic),
        IconButton(tooltip: 'Underline', icon: const Icon(Icons.format_underlined), color: underlineActive ? cs.primary : null, onPressed: onUnderline),
        IconButton(tooltip: 'Clear formatting', icon: const Icon(Icons.format_clear), onPressed: onClear),
      ],
    );
  }
}

class FcCardEditorPage extends ConsumerStatefulWidget {
  const FcCardEditorPage({super.key, required this.deckId, this.cardId});

  final String deckId;
  final String? cardId;

  @override
  ConsumerState<FcCardEditorPage> createState() => _FcCardEditorPageState();
}

class _FcCardEditorPageState extends ConsumerState<FcCardEditorPage> {
  final FcRichTextController _front = FcRichTextController();
  final FcRichTextController _back = FcRichTextController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _tagInput = TextEditingController();
  final FocusNode _frontFocus = FocusNode();

  FcCardType _type = FcCardType.basic;
  final List<String> _tags = <String>[];
  bool _reversed = false;
  bool _showAnswer = false;
  bool _multipleAnswers = false;
  FcRichTextController? _activeController;
  TextSelection _frontSelection = const TextSelection.collapsed(offset: 0);
  TextSelection _backSelection = const TextSelection.collapsed(offset: 0);
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _loading = true;
  bool _saving = false;
  int _addedCount = 0;
  FcCard? _existing;
  FcDeck? _deck;

  bool get _editing => widget.cardId != null;

  @override
  void initState() {
    super.initState();
    _load();
    _front.addListener(_handleFrontChanged);
    _back.addListener(_handleBackChanged);
  }

  void _handleFrontChanged() {
    _frontSelection = _front.selection;
    if (mounted) setState(() {});
  }

  void _handleBackChanged() {
    _backSelection = _back.selection;
    if (mounted) setState(() {});
  }


  Future<void> _voiceInput() async {
    final FcRichTextController c = _editorController;
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() {});
      return;
    }

    try {
      final PermissionStatus permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        if (mounted) {
          fcToast(
            context,
            permission.isPermanentlyDenied
                ? 'Microphone permission is blocked. Allow it in Android Settings.'
                : 'Microphone permission is required for voice input.',
          );
        }
        return;
      }

      final ValueNotifier<String> liveText = ValueNotifier<String>('');
      BuildContext? sheetContext;
      bool closed = false;

      Future<void> closeSheet() async {
        if (closed) return;
        closed = true;
        if (sheetContext != null && sheetContext!.mounted) {
          Navigator.of(sheetContext!).pop();
        }
      }

      if (!_speechReady) {
        final bool ready = await _speech.initialize(
          onStatus: (String status) {
            if ((status == 'done' || status == 'notListening') &&
                sheetContext != null) {
              closeSheet();
            }
            if (mounted) setState(() {});
          },
          onError: (SpeechRecognitionError error) {
            if (mounted) {
              fcToast(context, 'Voice input error: ${error.errorMsg}');
              setState(() {});
            }
            closeSheet();
          },
        );
        _speechReady = ready;
      }

      if (!_speechReady) {
        liveText.dispose();
        if (mounted) {
          fcToast(context, 'Speech recognition is not available on this device.');
        }
        return;
      }

      TextSelection insertionSelection =
          identical(c, _front) ? _frontSelection : _backSelection;
      if (!insertionSelection.isValid) {
        insertionSelection = TextSelection.collapsed(offset: c.text.length);
      }

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          liveText.value = result.recognizedWords;
          if (!result.finalResult) {
            if (mounted) setState(() {});
            return;
          }

          final String spoken = result.recognizedWords.trim();
          if (spoken.isEmpty) return;

          c.value = insertSpeechText(
            TextEditingValue(text: c.text, selection: insertionSelection),
            spoken,
          );
          insertionSelection = c.selection;
          if (identical(c, _front)) {
            _frontSelection = c.selection;
          } else {
            _backSelection = c.selection;
          }
          if (mounted) setState(() {});
        },
      );

      if (!_speech.isListening) {
        liveText.dispose();
        if (mounted) fcToast(context, 'Could not start speech recognition.');
        return;
      }

      if (mounted) setState(() {});
      await SystemSound.play(SystemSoundType.click);
      if (!mounted) {
        liveText.dispose();
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: true,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.08),
        builder: (BuildContext ctx) {
          sheetContext = ctx;
          return _VoiceListeningSheet(transcript: liveText);
        },
      );

      if (_speech.isListening) {
        await _speech.stop();
      }
      liveText.dispose();
      if (mounted) setState(() {});
    } catch (_) {
      await _speech.stop();
      if (mounted) {
        setState(() {});
        fcToast(context, 'Voice input is unavailable right now.');
      }
    }
  }

  Future<void> _load() async {
    final FcRepository repo = ref.read(fcRepositoryProvider);
    _deck = await repo.deck(widget.deckId);
    if (widget.cardId != null) {
      final FcCard? c = await repo.card(widget.cardId!);
      if (c != null) {
        _existing = c;
        _type = c.type;
        _multipleAnswers = c.type == FcCardType.typed && c.back.contains('|');
        _front.loadMarkup(c.front);
        _back.loadMarkup(c.back);
        _notes.text = c.notes ?? '';
        _tags.addAll(c.tags);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _speech.stop();
    _front.removeListener(_handleFrontChanged);
    _back.removeListener(_handleBackChanged);
    _front.dispose();
    _back.dispose();
    _notes.dispose();
    _tagInput.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  FcRichTextController get _editorController => _activeController ?? _front;

  void _insertCloze() {
    if (_type != FcCardType.cloze) {
      setState(() {
        _type = FcCardType.cloze;
        _showAnswer = false;
      });
    }
    final FcRichTextController c = _front;
    final TextSelection sel = c.selection;
    if (sel.isValid && !sel.isCollapsed) {
      _wrapSelection(sameNumber: false);
      return;
    }
    final int index = nextClozeIndex(c.text);
    final int pos = sel.isValid ? sel.baseOffset : c.text.length;
    final String marker = '{{c' + index.toString() + '::}}';
    c.value = TextEditingValue(
      text: c.text.replaceRange(pos, pos, marker),
      selection: TextSelection.collapsed(offset: pos + marker.length - 2),
    );
    setState(() {});
    _frontFocus.requestFocus();
  }

  Future<void> _pickImage() async {
    final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${root.path}/flashcards_media');
    if (!await dir.exists()) await dir.create(recursive: true);
    final String target = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}_${file.name}';
    await File(file.path).copy(target);
    final FcRichTextController c = _editorController;
    final int pos = c.selection.isValid ? c.selection.baseOffset : c.text.length;
    final String token = '[img:' + target + ']';
    final String prefix = c.text.isNotEmpty && !c.text.endsWith('\n') ? '\n' : '';
    final String insertion = prefix + token;
    c.value = TextEditingValue(
      text: c.text.replaceRange(pos, pos, insertion),
      selection: TextSelection.collapsed(offset: pos + insertion.length),
    );
    setState(() {});
  }

  Future<void> _editMultipleAnswers() async {
    final List<String> existing = _back.text
        .split('|')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .take(5)
        .toList();
    final List<TextEditingController> controllers = List<TextEditingController>.generate(
      5,
      (int index) => TextEditingController(
        text: index < existing.length ? existing[index] : '',
      ),
    );

    try {
      final bool? saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (BuildContext sheetContext) {
          final ColorScheme cs = Theme.of(sheetContext).colorScheme;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Multiple Answers',
                      style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add up to 5 accepted answers. Any one of them will be accepted during study.',
                      style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 18),
                    for (int i = 0; i < controllers.length; i++) ...<Widget>[
                      TextField(
                        controller: controllers[i],
                        textInputAction: i == controllers.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Answer ' + (i + 1).toString(),
                          prefixIcon: CircleAvatar(
                            radius: 14,
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              (i + 1).toString(),
                              style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Done'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (saved == true) {
        final List<String> answers = controllers
            .map((TextEditingController c) => c.text.trim())
            .where((String value) => value.isNotEmpty)
            .toList();
        if (answers.isEmpty) {
          setState(() {
            _multipleAnswers = false;
            if (_type == FcCardType.typed) _type = FcCardType.basic;
          });
          return;
        }
        _back.text = answers.join(' | ');
        setState(() {
          _multipleAnswers = true;
          _type = FcCardType.typed;
        });
      }
    } finally {
      for (final TextEditingController controller in controllers) {
        controller.dispose();
      }
    }
  }

  void _setMultipleAnswers(bool enabled) {
    if (!enabled) {
      setState(() {
        _multipleAnswers = false;
        if (_type == FcCardType.typed) _type = FcCardType.basic;
      });
      return;
    }
    _editMultipleAnswers();
  }

  void _swapFrontBack() {
    final String a = _front.text;
    _front.text = _back.text;
    _back.text = a;
    if (_multipleAnswers && !_back.text.contains('|')) {
      _multipleAnswers = false;
      if (_type == FcCardType.typed) _type = FcCardType.basic;
    }
    setState(() {});
  }

  TextSelection _selectionFor(FcRichTextController c) =>
      identical(c, _front) ? _frontSelection : _backSelection;

  void _format(String tag) {
    final FcRichTextController c = _editorController;
    c.toggleFormat(tag, _selectionFor(c));
    setState(() {});
  }

  void _clearFormatting() {
    final FcRichTextController c = _editorController;
    final TextSelection selection = _selectionFor(c);
    c.clearFormatting();
    c.value = c.value.copyWith(selection: selection);
    setState(() {});
  }

  Future<void> _translateBack() async {
    final TextSelection selection = _front.selection;
    String word = selection.isValid && !selection.isCollapsed
        ? _front.text.substring(selection.start, selection.end)
        : _front.text;

    word = word
        .replaceAll(RegExp(r'\[(?:b|i|u)\]'), '')
        .replaceAll(RegExp(r'\[/(?:b|i|u)\]'), '')
        .replaceAll(RegExp(r'\{\{c\d+::'), '')
        .replaceAll('}}', '')
        .trim();

    if (word.contains(RegExp(r'\s'))) {
      fcToast(context, 'Select one word in Front to translate.');
      return;
    }
    if (word.isEmpty) {
      fcToast(context, 'Enter or select a word first.');
      return;
    }

    try {
      final profile = await ref.read(wordProfileProvider(word.toLowerCase()).future);
      final List<String> offlineUrdu = profile.exam?.urduMeanings ?? const <String>[];
      if (offlineUrdu.isNotEmpty) {
        _back.text = offlineUrdu.take(3).join('، ');
        setState(() {});
        return;
      }

      final ai = await ref.read(wordAiEnrichmentProvider(word.toLowerCase()).future);
      final List<String> aiUrdu = ai?.urduMeanings ?? const <String>[];
      if (aiUrdu.isNotEmpty) {
        _back.text = aiUrdu.take(3).join('، ');
        setState(() {});
        return;
      }

      final result = await ref.read(lookUpWordProvider).call(word.toLowerCase());
      result.fold(
        (_) => fcToast(context, 'Translation not found for “$word”.'),
        (value) {
          final String meaning = value?.meaning.trim() ?? '';
          if (meaning.isEmpty) {
            fcToast(context, 'Translation not found for “$word”.');
            return;
          }
          _back.text = meaning;
          setState(() {});
        },
      );
    } catch (_) {
      fcToast(context, 'Translation unavailable right now.');
    }
  }

  void _addTag(String raw) {
    final String t = raw.trim().replaceAll(',', '');
    if (t.isNotEmpty && !_tags.any((String e) => e.toLowerCase() == t.toLowerCase())) {
      setState(() => _tags.add(t));
    }
    _tagInput.clear();
  }

  void _wrapSelection({required bool sameNumber}) {
    final TextSelection sel = _front.selection;
    if (!sel.isValid || sel.isCollapsed) {
      fcToast(context, 'Select the text to hide first');
      return;
    }
    final List<int> existing = clozeIndices(_front.text);
    final int index = sameNumber && existing.isNotEmpty ? existing.last : nextClozeIndex(_front.text);
    final ({String text, int caret}) r =
        wrapSelectionAsCloze(_front.text, sel.start, sel.end, index);
    _front.value = TextEditingValue(
      text: r.text,
      selection: TextSelection.collapsed(offset: r.caret),
    );
    setState(() => _previewClozeIndex = index);
    _frontFocus.requestFocus();
  }

  String? _validate() {
    final String front = _front.text.trim();
    if (front.isEmpty) return 'The front can’t be empty';
    if (_type == FcCardType.cloze) {
      if (!hasCloze(front)) return 'Hide some text with the “Hide selection” button';
    } else if (_back.text.trim().isEmpty) {
      return 'The back can’t be empty';
    }
    return null;
  }

  Future<void> _save({required bool addAnother}) async {
    final String? err = _validate();
    if (err != null) {
      fcToast(context, err);
      return;
    }
    setState(() => _saving = true);
    final FcRepository repo = ref.read(fcRepositoryProvider);
    final String? notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    try {
      if (_editing && _existing != null) {
        final FcCard c = _existing!;
        final List<int> idx = clozeIndices(_front.text);
        await repo.updateCard(c.copyWith(
          front: _front.markupText.trim(),
          back: _back.markupText.trim(),
          type: _type,
          clozeIndex: () => (_type == FcCardType.cloze && c.clozeIndex != null && idx.contains(c.clozeIndex)) ? c.clozeIndex : null,
          tags: List<String>.of(_tags),
          notes: () => notes,
        ));
        if (mounted) Navigator.pop(context, true);
        return;
      }
      final AddCardsResult r = await repo.addCards(
        widget.deckId,
        <CardDraft>[
          CardDraft(
            front: _front.markupText.trim(),
            back: _back.markupText.trim(),
            type: _type,
            tags: List<String>.of(_tags),
            notes: notes,
          ),
        ],
        reversed: _reversed && _type == FcCardType.basic,
        clozePerDeletion: false,
        subject: _deck?.subject,
        topic: _deck?.topic,
      );
      _addedCount += r.created;
      if (!mounted) return;
      if (addAnother) {
        _front.clear();
        _back.clear();
        _notes.clear();
        setState(() {
          _saving = false;
          _showAnswer = false;
        });
        _frontFocus.requestFocus();
        fcToast(context, r.created == 1 ? 'Card added' : '${r.created} cards added');
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        fcToast(context, 'Couldn’t save: $e');
      }
    }
  }

  FcCard _previewCard() {
    final DateTime now = DateTime.now();
    return FcCard(
      id: 'preview',
      deckId: widget.deckId,
      front: _front.markupText,
      back: _back.markupText,
      type: _type,
      clozeIndex: null,
      createdAt: now,
      updatedAt: now,
      fsrs: _existing?.fsrs ?? FsrsCard.fresh(now),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> tagSuggestions =
        ref.watch(fcTagSuggestionsProvider).asData?.value ?? const <String>[];
    final bool cloze = _type == FcCardType.cloze;

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? _) {
        if (!didPop) Navigator.pop(context, _addedCount > 0 ? true : null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Edit card' : 'New card'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, _addedCount > 0 ? true : null),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: _saving || _loading ? null : () => _save(addAnother: false),
              child: const Text('Save'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: <Widget>[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _front,
                    focusNode: _frontFocus,
                    onTap: () {
                      _activeController = _front;
                      _frontSelection = _front.selection;
                    },
                    onChanged: (_) => _activeController = _front,
                    autofocus: !_editing,
                    minLines: 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: cloze ? 'Text' : 'Front',
                      hintText: cloze ? 'The {{c1::heart}} pumps blood' : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _EditorToolbar(
                    cloze: cloze,
                    onCloze: _insertCloze,
                    onMic: _voiceInput,
                    onImage: _pickImage,
                    onBold: () => _format('b'),
                    onItalic: () => _format('i'),
                    onUnderline: () => _format('u'),
                    onClear: _clearFormatting,
                    boldActive: _editorController.isBoldActive,
                    italicActive: _editorController.isItalicActive,
                    underlineActive: _editorController.isUnderlineActive,
                    listening: _speech.isListening,
                  ),
                  if (cloze) ...<Widget>[
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: () => _wrapSelection(sameNumber: false),
                          icon: const Icon(Icons.visibility_off_outlined, size: 18),
                          label: const Text('Hide selection'),
                        ),
                        if (clozeIndices(_front.text).isNotEmpty)
                          OutlinedButton(
                            onPressed: () => _wrapSelection(sameNumber: true),
                            child: Text('Same blank (c${clozeIndices(_front.text).last})'),
                          ),
                      ],
                    ),
                  ],
                  SizedBox(
                    height: 68,
                    child: Center(
                      child: Material(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _swapFrontBack,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.swap_vert_rounded, size: 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: _back,
                    onTap: () {
                      _activeController = _back;
                      _backSelection = _back.selection;
                    },
                    minLines: cloze ? 1 : 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: cloze
                          ? 'Extra info (optional)'
                          : (_multipleAnswers ? 'Accepted answers' : 'Back'),
                      helperText: cloze
                          ? 'Optional — Cloze cards can be saved without a back.'
                          : (_multipleAnswers
                              ? 'Any one accepted answer can be entered during study.'
                              : null),
                      border: const OutlineInputBorder(),
                      suffixIcon: cloze ? null : IconButton(
                        tooltip: 'Translate from dictionary',
                        icon: const Icon(Icons.translate),
                        onPressed: _translateBack,
                      ),
                    ),
                  ),
                  if (!cloze) ...<Widget>[
                    const SizedBox(height: 8),
                    _EditorToolbar(
                      cloze: false,
                      onCloze: _insertCloze,
                      onMic: _voiceInput,
                      onImage: _pickImage,
                      onBold: () => _format('b'),
                      onItalic: () => _format('i'),
                      onUnderline: () => _format('u'),
                      onClear: _clearFormatting,
                      boldActive: _editorController.isBoldActive,
                      italicActive: _editorController.isItalicActive,
                      underlineActive: _editorController.isUnderlineActive,
                      listening: _speech.isListening,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: <Widget>[
                          SwitchListTile(
                            title: const Text('Multiple answers'),
                            subtitle: Text(
                              _multipleAnswers
                                  ? 'Multiple accepted answers are configured'
                                  : 'Accept more than one correct answer',
                            ),
                            value: _multipleAnswers,
                            onChanged: _setMultipleAnswers,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Also create the reverse card'),
                            subtitle: const Text('Adds back → front as a second card'),
                            value: _reversed && _type == FcCardType.basic,
                            onChanged: _type == FcCardType.basic
                                ? (bool v) => setState(() => _reversed = v)
                                : null,
                          ),
                          if (_multipleAnswers)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _editMultipleAnswers,
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Edit accepted answers'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Text('Preview', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(value: false, label: Text('Question')),
                          ButtonSegment<bool>(value: true, label: Text('Answer')),
                        ],
                        selected: <bool>{_showAnswer},
                        onSelectionChanged: (Set<bool> s) => setState(() => _showAnswer = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(minHeight: 110),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: _front.text.trim().isEmpty
                        ? Text('Start typing to see the card',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                        : FcCardFaceText(
                            card: _previewCard(),
                            face: _showAnswer ? FcFace.answer : FcFace.question,
                            fontSize: 20,
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text('Tags', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: <Widget>[
                      for (final String t in _tags)
                        InputChip(label: Text(t), onDeleted: () => setState(() => _tags.remove(t))),
                    ],
                  ),
                  TextField(
                    controller: _tagInput,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Add a tag and press done',
                      prefixIcon: Icon(Icons.sell_outlined),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _addTag,
                    onChanged: (String v) {
                      if (v.endsWith(',')) _addTag(v);
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final String t in tagSuggestions.where((String s) => !_tags.contains(s)).take(6))
                        ActionChip(label: Text('#$t'), onPressed: () => _addTag(t)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes (shown after the answer)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (!_editing) ...<Widget>[

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _save(addAnother: true),
                        icon: const Icon(Icons.add),
                        label: const Text('Save and add another'),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
