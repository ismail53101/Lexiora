import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lexiora/core/services/pdf_discovery_service.dart' show DeviceFile;
import 'package:lexiora/core/services/pdf_import_service.dart';
import 'package:lexiora/core/services/pdf_ocr_service.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_attachment.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_message_tools.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_usage_limit_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

/// The message input bar: a single ChatGPT-style rounded pill holding the
/// attach button, the text field, and the send / stop toggle.
class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({super.key, required this.enabled});

  final bool enabled;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final PdfImportService _pdfPicker = PdfImportService();
  final PdfOcrService _pdfOcr = PdfOcrService();
  static const Uuid _uuid = Uuid();

  bool _hasText = false;
  String? _pendingImagePath;
  String? _pendingPdfPath;
  String? _pendingPdfName;
  String? _pendingPdfText;
  bool _pickingImage = false;
  bool _pickingPdf = false;
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  BuildContext? _voiceSheetContext;
  bool _voiceSheetClosed = false;
  bool _voiceRecognitionEnded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final bool has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _hasText || _pendingImagePath != null || _pendingPdfPath != null;

  Future<void> _pickImage(ImageSource source) async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 88,
      );
      if (picked == null) return;

      // Copy into the app's own persistent storage — the picker's own file
      // can live in a transient cache location that the OS may clear, and
      // this image needs to survive as long as the conversation does (it's
      // shown again every time the chat history is reopened).
      final Directory dir = await _imagesDirectory();
      final String ext =
          picked.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final String savedPath = '${dir.path}/${_uuid.v4()}.$ext';
      await File(picked.path).copy(savedPath);

      if (mounted) setState(() => _pendingImagePath = savedPath);
    } on Object {
      // Picker cancelled/denied/failed — nothing to attach, no crash.
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<Directory> _imagesDirectory() async {
    final Directory support = await getApplicationSupportDirectory();
    final Directory dir = Directory('${support.path}/ai_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Opens the same native PDF picker the Library's "Import PDF" uses. The
  /// selected document stays as a PDF attachment chip; extracted text is kept
  /// as hidden context for the AI request and is never pasted into the editor.
  Future<void> _attachPdf() async {
    if (_pickingPdf) return;
    setState(() => _pickingPdf = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final List<DeviceFile> picked = await _pdfPicker.pickAndImport();
      if (picked.isEmpty) return;
      if (picked.length > 1 && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Only the first PDF picked was attached.')),
        );
      }
      final DeviceFile file = picked.first;
      // Always run the existing page-aware OCR preparation. It skips pages
      // that already have text and fills in scanned pages, which also makes
      // mixed text/scanned PDFs readable instead of handling only the fully
      // image-based case.
      final String readablePath = await _pdfOcr.makeSearchable(
        documentId: _uuid.v4(),
        sourcePath: file.path,
      );
      final String? extracted = await extractPdfPlainText(readablePath);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            extracted == null
                ? 'PDF attached, but no readable text could be found.'
                : readablePath == file.path
                    ? 'PDF attached and ready for questions.'
                    : 'Scanned PDF processed and ready for questions.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _pendingPdfPath = readablePath;
        _pendingPdfName = file.name;
        _pendingPdfText = extracted;
      });
      _focus.requestFocus();
    } on Object {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not attach that PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingPdf = false);
    }
  }

  void _showAttachSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Attach a PDF'),
              subtitle: const Text('Attach the document and ask about it'),

              onTap: () {
                Navigator.of(sheetContext).pop();
                _attachPdf();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _requestCloseVoiceSheet() {
    if (_voiceSheetClosed) return;
    _voiceSheetClosed = true;
    final BuildContext? sheet = _voiceSheetContext;
    if (sheet != null && sheet.mounted) Navigator.of(sheet).pop();
  }

  Future<void> _voiceInput() async {
    if (_speech.isListening) {
      await _speech.stop();
      _requestCloseVoiceSheet();
      if (mounted) setState(() {});
      return;
    }
    try {
      final PermissionStatus permission =
          await Permission.microphone.request();
      if (!permission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                permission.isPermanentlyDenied
                    ? 'Microphone permission is blocked. Allow it in Android Settings.'
                    : 'Microphone permission is required for voice input.',
              ),
            ),
          );
        }
        return;
      }
      final ValueNotifier<String> liveText = ValueNotifier<String>('');
      _voiceSheetContext = null;
      _voiceSheetClosed = false;
      _voiceRecognitionEnded = false;
      if (!_speechReady) {
        _speechReady = await _speech.initialize(
          onStatus: (String status) {
            if (status == 'done' || status == 'notListening') {
              _voiceRecognitionEnded = true;
              _requestCloseVoiceSheet();
            }
            if (mounted) setState(() {});
          },
          onError: (SpeechRecognitionError error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Voice input error: \${error.errorMsg}')),
              );
              setState(() {});
            }
            _requestCloseVoiceSheet();
          },
        );
      }
      if (!_speechReady) {
        liveText.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
              'Speech recognition is not available on this device.',
            )),
          );
        }
        return;
      }
      TextSelection insertionSelection = _controller.selection;
      if (!insertionSelection.isValid) {
        insertionSelection =
            TextSelection.collapsed(offset: _controller.text.length);
      }
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          liveText.value = result.recognizedWords;
          if (!result.finalResult) {
            if (mounted) setState(() {});
            return;
          }
          _requestCloseVoiceSheet();
          final String spoken = result.recognizedWords.trim();
          if (spoken.isEmpty) return;
          final TextEditingValue current = _controller.value;
          final int start = current.selection.isValid
              ? current.selection.start
              : insertionSelection.start;
          final int end = current.selection.isValid
              ? current.selection.end
              : insertionSelection.end;
          final String updated = current.text.replaceRange(start, end, spoken);
          final int cursor = start + spoken.length;
          _controller.value = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: cursor),
          );
          insertionSelection = _controller.selection;
          _focus.requestFocus();
          if (mounted) setState(() {});
        },
      );
      if (!_speech.isListening) {
        liveText.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not start speech recognition.')),
          );
        }
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
          _voiceSheetContext = ctx;
          if (_voiceRecognitionEnded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _requestCloseVoiceSheet();
            });
          }
          return _VoiceListeningSheet(transcript: liveText);
        },
      );
      _voiceSheetContext = null;
      if (_speech.isListening) await _speech.stop();

      // Once the voice sheet closes, immediately submit the recognized
      // prompt instead of requiring the user to press Send.
      final bool hasVoiceText = liveText.value.trim().isNotEmpty;
      liveText.dispose();
      if (mounted) setState(() {});
      if (hasVoiceText && mounted && _canSend) {
        await _send();
      }
    } catch (_) {
      await _speech.stop();
      _requestCloseVoiceSheet();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice input is unavailable right now.')),
        );
      }
    }
  }

  Future<void> _send() async {
    if (!_canSend) return;
    final String content = AiAttachment.encode(
      imagePath: _pendingImagePath,
      pdfPath: _pendingPdfPath,
      pdfName: _pendingPdfName,
      pdfText: _pendingPdfText,
      text: _controller.text.trim(),
    );
    final AiSendResult result =
        await ref.read(aiChatControllerProvider.notifier).send(content);
    if (!mounted) return;
    if (result == AiSendResult.limitReached) {
      await showAiUsageLimitDialog(context, ref);
      return;
    }
    if (result != AiSendResult.started) return;
    _controller.clear();
    setState(() {
      _pendingImagePath = null;
      _pendingPdfPath = null;
      _pendingPdfName = null;
      _pendingPdfText = null;
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool streaming = ref
        .watch(aiChatControllerProvider.select((AiChatState s) => s.streaming));

    // Forced explicitly per-brightness rather than trusting
    // `surfaceContainerHighest`/`onSurfaceVariant` alone: on this app's
    // light theme those tokens were resolving dark enough that the "Ask
    // Sapiora" hint text became almost invisible against the pill. Picking
    // the pill background and hint/text colors directly by brightness
    // guarantees real contrast in both themes.
    final Color pillColor =
        isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF0F1F4);
    final Color pillBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final Color hintColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.45);
    final Color inputTextColor = isDark ? Colors.white : Colors.black87;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_pendingImagePath != null) ...<Widget>[
              _ImagePreviewChip(
                path: _pendingImagePath!,
                onRemove: () => setState(() => _pendingImagePath = null),
              ),
              const SizedBox(height: 8),
            ],
            if (_pendingPdfPath != null) ...<Widget>[
              _PdfPreviewChip(
                name: _pendingPdfName ?? 'Attached PDF',
                onRemove: () => setState(() {
                  _pendingPdfPath = null;
                  _pendingPdfName = null;
                  _pendingPdfText = null;
                }),
              ),
              const SizedBox(height: 8),
            ],
            // One continuous rounded pill holding everything — attach, the
            // text field, and send — matching the latest ChatGPT Android
            // composer: a single dark capsule, no separate floating buttons.
            Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: pillBorder),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  _AttachButton(
                    busy: _pickingImage || _pickingPdf,
                    enabled: widget.enabled,
                    iconColor: inputTextColor,
                    onTap: _showAttachSheet,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.center,
                      style:
                          theme.textTheme.bodyLarge?.copyWith(color: inputTextColor),
                      cursorColor: scheme.primary,
                      decoration: InputDecoration(
                        hintText: widget.enabled
                            ? 'Ask DarsNexa'
                            : 'AI Assistant is not configured',
                        hintStyle: theme.textTheme.bodyLarge
                            ?.copyWith(color: hintColor),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: 'Voice input',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.enabled ? _voiceInput : null,
                    icon: Icon(
                      _speech.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _speech.isListening ? scheme.primary : inputTextColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: _SendStopButton(
                      streaming: streaming,
                      canSend: widget.enabled && _canSend,
                      onSend: _send,
                      onStop: () =>
                          ref.read(aiChatControllerProvider.notifier).stop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _VoiceListeningSheet extends StatefulWidget {
  const _VoiceListeningSheet({required this.transcript});
  final ValueNotifier<String> transcript;
  @override
  State<_VoiceListeningSheet> createState() => _VoiceListeningSheetState();
}
class _VoiceListeningSheetState extends State<_VoiceListeningSheet>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final AnimationController _wave = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900),
  )..repeat();
  @override
  void dispose() { _pulse.dispose(); _wave.dispose(); super.dispose(); }
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
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: <Color>[
                cs.primary.withValues(alpha: 0.94),
                cs.surface.withValues(alpha: 0.96),
                Colors.cyan.withValues(alpha: 0.72),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                blurRadius: 34, spreadRadius: 2,
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
                  width: 42, height: 4,
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
                      width: 82 + value * 8, height: 82 + value * 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: cs.primary.withValues(alpha: 0.72),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            blurRadius: 22 + value * 12, spreadRadius: 4,
                            color: cs.primary.withValues(alpha: 0.38),
                          ),
                          BoxShadow(
                            blurRadius: 18, spreadRadius: 1,
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
                const Text('Listening…', style: TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 5),
                const Text('Speak now, I’m listening to your voice',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 14),
                AnimatedBuilder(
                  animation: _wave,
                  builder: (BuildContext context, Widget? child) {
                    return SizedBox(
                      height: 42, width: double.infinity,
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
                        child: Text(value, textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
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
    required this.progress, required this.primary, required this.secondary,
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

class _AttachButton extends StatelessWidget {
  const _AttachButton({
    required this.busy,
    required this.enabled,
    required this.onTap,
    required this.iconColor,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Attach an image',
      onPressed: enabled && !busy ? onTap : null,
      visualDensity: VisualDensity.compact,
      icon: busy
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor,
              ),
            )
          : Icon(Icons.add_rounded,
              color: enabled ? iconColor : iconColor.withValues(alpha: 0.4)),
    );
  }
}

class _ImagePreviewChip extends StatelessWidget {
  const _ImagePreviewChip({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(path),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 72,
                height: 72,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close,
                    size: 14, color: theme.colorScheme.onError),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfPreviewChip extends StatelessWidget {
  const _PdfPreviewChip({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.fromLTRB(8, 7, 6, 7),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: scheme.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'PDF document',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove PDF',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: Icon(
                Icons.close_rounded,
                color: scheme.onSurfaceVariant,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The circular send / stop button — solid blue with an upward arrow while
/// idle (matching ChatGPT), swapping to a filled stop icon while a reply is
/// streaming. Sizing and behavior are unchanged; only the idle-state look
/// was made to match ChatGPT's flat, solid-color circle instead of a
/// gradient.
class _SendStopButton extends StatelessWidget {
  const _SendStopButton({
    required this.streaming,
    required this.canSend,
    required this.onSend,
    required this.onStop,
  });

  final bool streaming;
  final bool canSend;
  final Future<void> Function() onSend;
  final VoidCallback onStop;

  static const double _size = 34;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    if (streaming) {
      return SizedBox(
        width: _size,
        height: _size,
        child: IconButton.filled(
          onPressed: onStop,
          tooltip: 'Stop generating',
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.stop_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: canSend ? scheme.primary : scheme.surfaceContainerHighest,
      ),
      child: IconButton(
        onPressed: canSend ? () => unawaited(onSend()) : null,
        tooltip: 'Send',
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.arrow_upward_rounded,
          size: 19,
          color: canSend
              ? scheme.onPrimary
              : scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
