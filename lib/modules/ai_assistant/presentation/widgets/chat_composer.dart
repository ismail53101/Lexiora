import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lexiora/core/services/pdf_discovery_service.dart' show DeviceFile;
import 'package:lexiora/core/services/pdf_import_service.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_attachment.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_message_tools.dart';
import 'package:path_provider/path_provider.dart';
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
  static const Uuid _uuid = Uuid();

  bool _hasText = false;
  String? _pendingImagePath;
  bool _pickingImage = false;
  bool _pickingPdf = false;

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

  bool get _canSend => _hasText || _pendingImagePath != null;

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

  /// Opens the same native PDF picker the Library's "Import PDF" uses, pulls
  /// the plain text out of whichever file is chosen, and drops it into the
  /// message box (with a clear `[PDF attached: ...]` marker) so the person
  /// can add their own question before sending — same idea as the existing
  /// image attachment, just for documents instead of photos.
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
      final String? extracted = await extractPdfPlainText(file.path);
      if (!mounted) return;
      if (extracted == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't read any text from that PDF (it may be a scanned "
              'image with no text layer).',
            ),
          ),
        );
        return;
      }
      final String block = '[PDF attached: ${file.name}]\n$extracted\n\n';
      final String existing = _controller.text;
      _controller.text = block + existing;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
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
              subtitle: const Text('Its text is added so you can ask about it'),
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

  void _send() {
    if (!_canSend) return;
    final String content = AiAttachment.encode(
      imagePath: _pendingImagePath,
      text: _controller.text.trim(),
    );
    ref.read(aiChatControllerProvider.notifier).send(content);
    _controller.clear();
    setState(() => _pendingImagePath = null);
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                      expands: false,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.center,
                      style:
                          theme.textTheme.bodyLarge?.copyWith(color: inputTextColor),
                      cursorColor: scheme.primary,
                      decoration: InputDecoration(
                        hintText: widget.enabled
                            ? 'Ask Sapiora'
                            : 'Sapiora is not configured',
                        hintStyle: theme.textTheme.bodyLarge
                            ?.copyWith(color: hintColor),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
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
  final VoidCallback onSend;
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
        onPressed: canSend ? onSend : null,
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
