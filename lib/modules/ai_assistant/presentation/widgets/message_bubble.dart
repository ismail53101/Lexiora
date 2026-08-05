import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_attachment.dart';
import 'package:lexiora/modules/ai_assistant/domain/entities/ai_message.dart';
import 'package:lexiora/modules/ai_assistant/presentation/widgets/ai_markdown.dart';
import 'package:share_plus/share_plus.dart';

/// One persisted chat message, shown with a sender label + timestamp above
/// the bubble and (for assistant replies) a small avatar and a row of quick
/// actions below — copy, thumbs up/down and read-aloud. Long-press still
/// opens the full copy/share/delete/(regen) sheet.
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

    final Widget header = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _isUser ? 'You' : 'AI Assistant',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _isUser
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
            ),
          ),
          Text(
            '  •  ${_time(message.createdAt)}',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    final Widget bubble = GestureDetector(
      onLongPress: () => _showActions(context, text),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (_isUser ? 0.82 : 0.72),
        ),
        padding: EdgeInsets.fromLTRB(
            attachment.hasImage ? 6 : 14, 12, attachment.hasImage ? 6 : 14, 12),
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
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (attachment.hasImage) ...<Widget>[
              _AttachedImage(path: attachment.imagePath!),
              if (text.isNotEmpty || (_isError && text.isEmpty))
                const SizedBox(height: 8),
            ],
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: attachment.hasImage ? 8 : 0),
              child: _buildBody(context, text, fg),
            ),
          ],
        ),
      ),
    );

    final Widget content = Column(
      crossAxisAlignment:
          _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        header,
        bubble,
        if (!_isUser)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _ActionRow(
              onCopy: () => _copy(context, text),
              onRegenerate: onRegenerate,
              onFeedback: (bool liked) => _feedback(context, liked),
              onSpeak: () => _comingSoon(context, 'Read aloud'),
            ),
          ),
      ],
    );

    if (_isUser) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Align(alignment: Alignment.centerRight, child: content),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _AiAvatar(),
          const SizedBox(width: 8),
          Flexible(child: content),
        ],
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
            state.hideToolbar();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Translate is temporarily unavailable on this Flutter version.',
                ),
              ),
            );
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

  void _feedback(BuildContext context, bool liked) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(liked ? 'Thanks for the feedback!' : 'Thanks — noted.'),
        ),
      );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature is coming in a future update.')),
      );
  }

  static String _time(DateTime dt) {
    final int h24 = dt.hour;
    final int h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final String period = h24 < 12 ? 'AM' : 'PM';
    final String m = dt.minute.toString().padLeft(2, '0');
    return '$h12:$m $period';
  }
}

/// The small square gradient avatar shown beside assistant replies — reuses
/// the app's own brand gradient and iconography, no extra image asset needed.
class _AiAvatar extends StatelessWidget {
  const _AiAvatar();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[scheme.primary, scheme.tertiary],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.auto_stories_rounded, color: scheme.onPrimary, size: 18),
    );
  }
}

/// Copy / thumbs-up / thumbs-down / read-aloud quick actions under an
/// assistant reply.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onCopy,
    required this.onFeedback,
    required this.onSpeak,
    this.onRegenerate,
  });

  final VoidCallback onCopy;
  final ValueChanged<bool> onFeedback;
  final VoidCallback onSpeak;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _icon(context, Icons.copy_outlined, 'Copy', onCopy),
        _icon(context, Icons.thumb_up_outlined, 'Good response',
            () => onFeedback(true)),
        _icon(context, Icons.thumb_down_outlined, 'Bad response',
            () => onFeedback(false)),
        _icon(context, Icons.volume_up_outlined, 'Read aloud', onSpeak),
        if (onRegenerate != null)
          _icon(context, Icons.refresh_rounded, 'Regenerate', onRegenerate!),
      ].map((Widget w) => Padding(
            padding: const EdgeInsets.only(right: 2),
            child: IconTheme(
              data: IconThemeData(color: scheme.onSurfaceVariant, size: 17),
              child: w,
            ),
          )).toList(),
    );
  }

  Widget _icon(
      BuildContext context, IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 28),
      onPressed: onTap,
    );
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
