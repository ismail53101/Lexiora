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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
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
              const SizedBox(height: 12),
            ],
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2B2B2B),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _AttachButton(
                    busy: _pickingImage,
                    enabled: widget.enabled,
                    onTap: _showAttachSheet,
                  ),
                  const SizedBox(width: 4),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.enabled
                            ? 'Ask Sapiora'
                            : 'AI Assistant is not configured',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _SendStopButton(
                    streaming: streaming,
                    canSend: widget.enabled && _canSend,
                    onSend: _send,
                    onStop: () =>
                        ref.read(aiChatControllerProvider.notifier).stop(),
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
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled && !busy ? onTap : null,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF3A3A3C),
        ),
        child: busy
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
      ),
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
    if (streaming) {
      return InkWell(
        onTap: onStop,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF3A3A3C),
          ),
          child: const Center(
            child: Icon(Icons.stop_rounded, color: Colors.white, size: 24),
          ),
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: canSend ? const Color(0xFF0A84FF) : const Color(0xFF3A3A3C),
      ),
      child: IconButton(
        onPressed: canSend ? onSend : null,
        tooltip: 'Send',
        padding: EdgeInsets.zero,
        disabledColor: Colors.white.withValues(alpha: 0.5),
        color: Colors.white,
        icon: const Icon(
          Icons.north_rounded,
          size: 24,
        ),
      ),
    );
  }
}