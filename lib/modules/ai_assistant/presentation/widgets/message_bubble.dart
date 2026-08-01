import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_attachment.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_markdown.dart';
import 'package:lexiora/modules/translation/presentation/widgets/translation_popup.dart';
import 'package:share_plus/share_plus.dart';

/// One persisted chat message. User messages are plain selectable text (plus
/// an attached image, if any); assistant messages render Markdown.
/// Long-press for copy/share/delete/(regen).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onRegenerate,
  });

  final AiMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;

  bool get _isUser => message.role == AiRole.user;
  bool get _isError => message.status == AiMessageStatus.error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AiAttachment attachment = AiAttachment.parse(message.content);
    final String text = attachment.text;

    final Color bg = _isUser
        ? theme.colorScheme.primary
        : (_isError
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest);
    final Color fg = _isUser
        ? theme.colorScheme.onPrimary
        : (_isError
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onSurface);

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showActions(context, text),
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.86),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: EdgeInsets.fromLTRB(
              attachment.hasImage ? 6 : 14, 6, attachment.hasImage ? 6 : 14, 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(_isUser ? 16 : 4),
              bottomRight: Radius.circular(_isUser ? 4 : 16),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (attachment.hasImage) ...<Widget>[
                _AttachedImage(path: attachment.imagePath!),
                if (text.isNotEmpty || (_isError && text.isEmpty))
                  const SizedBox(height: 8),
              ],
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: attachment.hasImage ? 8 : 0),
                child: _buildBody(context, text, fg),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: attachment.hasImage ? 8 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _time(message.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: fg.withValues(alpha: 0.6), fontSize: 10),
                    ),
                    if (!_isUser) ...<Widget>[
                      const SizedBox(width: 8),
                      _iconBtn(context, Icons.copy, 'Copy',
                          () => _copy(context, text)),
                      if (onRegenerate != null)
                        _iconBtn(context, Icons.refresh, 'Regenerate',
                            onRegenerate!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String text, Color fg) {
    if (_isError && text.trim().isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline, size: 18, color: fg),
          const SizedBox(width: 8),
          Flexible(
              child: Text(message.error ?? 'Something went wrong.',
                  style: TextStyle(color: fg))),
        ],
      );
    }
    final Widget body = _isUser
        ? SelectableText(text, style: TextStyle(color: fg))
        : AiMarkdown(data: text, color: fg);
    final Widget selectableBody = SelectionArea(
      contextMenuBuilder: (BuildContext context, SelectableRegionState state) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: <ContextMenuButtonItem>[
            ...state.contextMenuButtonItems,
            ContextMenuButtonItem(
              label: 'Translate',
              onPressed: () {
                final String? selected = state.selectedContent?.plainText;
                state.hideToolbar();
                if (selected != null && selected.trim().isNotEmpty) {
                  showTranslationPopup(context, selected.trim());
                }
              },
            ),
          ],
        );
      },
      child: body,
    );
    if (_isError && text.trim().isNotEmpty) {
      final ThemeData theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          selectableBody,
          const SizedBox(height: 6),
          Text(message.error ?? 'Stopped',
              style: theme.textTheme.labelSmall?.copyWith(color: fg)),
        ],
      );
    }
    return selectableBody;
  }

  Widget _iconBtn(
      BuildContext context, IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 15),
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 28),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: onTap,
    );
  }

  void _showActions(BuildContext context, String text) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.of(context).pop();
                _copy(context, text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(context).pop();
                _share(text);
              },
            ),
            if (onRegenerate != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Regenerate'),
                onTap: () {
                  Navigator.of(context).pop();
                  onRegenerate!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(const SnackBar(content: Text('Copied')));
  }

  Future<void> _share(String text) async {
    if (text.trim().isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: text));
  }

  static String _time(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }
}

/// The thumbnail for an image attached to a user message — tap to view it
/// full-screen.
class _AttachedImage extends StatelessWidget {
  const _AttachedImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (_, _, _) => Container(
            height: 120,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }
}
