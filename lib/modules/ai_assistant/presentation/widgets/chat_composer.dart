import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_attachment.dart';
import 'package:lexiora/modules/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// The message input bar: text field, an image-attach button, and the
/// send / stop toggle.
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
  static const Uuid _uuid = Uuid();

  bool _hasText = false;
  String? _pendingImagePath;
  bool _pickingImage = false;

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
    final bool streaming = ref
        .watch(aiChatControllerProvider.select((AiChatState s) => s.streaming));

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.06),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _AttachButton(
                  busy: _pickingImage,
                  enabled: widget.enabled,
                  onTap: _showAttachSheet,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: widget.enabled
                            ? 'Message the assistant…'
                            : 'AI Assistant is not configured',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _MicButton(enabled: widget.enabled),
                const SizedBox(width: 8),
                _SendStopButton(
                  streaming: streaming,
                  canSend: widget.enabled && _canSend,
                  onSend: _send,
                  onStop: () =>
                      ref.read(aiChatControllerProvider.notifier).stop(),
                ),
              ],
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
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Attach an image',
      onPressed: enabled && !busy ? onTap : null,
      icon: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_photo_alternate_outlined),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Voice input — coming soon',
      onPressed: enabled
          ? () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
                content: Text('Voice input is coming in a future update.')))
          : null,
      icon: const Icon(Icons.mic_none_rounded),
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (streaming) {
      return IconButton.filled(
        onPressed: onStop,
        tooltip: 'Stop generating',
        icon: const Icon(Icons.stop_rounded),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.errorContainer,
          foregroundColor: theme.colorScheme.onErrorContainer,
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: canSend
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              )
            : null,
        color: canSend ? null : theme.colorScheme.surfaceContainerHighest,
      ),
      child: IconButton(
        onPressed: canSend ? onSend : null,
        tooltip: 'Send',
        icon: Icon(
          Icons.arrow_upward_rounded,
          color: canSend
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
