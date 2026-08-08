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

    // ChatGPT-style split: the user's own messages stay in a solid, rounded
    // bubble on the right. Assistant replies get no bubble at all — just
    // plain full-width text on the left, like the real ChatGPT app — so long
    // answers (headings, tables, code) have the whole screen width to lay
    // out in instead of being squeezed into a ~70%-wide box.
    final bool useBubbleBox = _isUser || _isError;

    final Color bg = _isUser
        ? theme.colorScheme.primary
        : (_isError ? theme.colorScheme.errorContainer : Colors.transparent);
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
          if (!_isUser) ...<Widget>[
            Icon(Icons.auto_awesome_rounded,
                size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
          ],
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

    final Widget bubbleBody = Column(
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
    );

    final Widget bubble = GestureDetector(
      onLongPress: () => _showActions(context, text),
      child: useBubbleBox
          ? Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              padding: EdgeInsets.fromLTRB(attachment.hasImage ? 6 : 14, 12,
                  attachment.hasImage ? 6 : 14, 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(_isUser ? 16 : 4),
                  bottomRight: Radius.circular(_isUser ? 4 : 16),
                ),
                boxShadow: _isUser
                    ? <BoxShadow>[
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: bubbleBody,
            )
          // Assistant, no error: plain text, full available width.
          : SizedBox(width: double.infinity, child: bubbleBody),
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
            padding: const EdgeInsets.only(top: 6),
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

    // Assistant replies span the full row width (no avatar column) so text,
    // headings and tables get every available pixel — same as ChatGPT.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: content,
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
    // The "Show more" collapse belongs on the USER's own messages — someone
    // pasting a long article to ask the assistant about it shouldn't have
    // that whole block filling the screen — not on the assistant's replies,
    // which should always render in full.
    final Widget body = _isUser
        ? _ExpandableUserText(text: text, color: fg)
        : AiMarkdown(data: text, color: fg);
    // A visible, explicit selection highlight — on this app's theme the
    // ambient TextSelectionTheme color was blending into the bubble/page
    // background, so a long-press selection was there but invisible. User
    // bubbles get a light overlay (readable against the solid primary
    // background); assistant text (no background) gets a tinted-primary
    // highlight, same as most reading apps.
    final Widget selectableBody = Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: _isUser
              ? Colors.white.withValues(alpha: 0.35)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
        ),
      ),
      child: SelectionArea(
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
),
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

/// Wraps an assistant reply's rendered Markdown and, once it's tall enough
/// to feel like a wall of text, collapses it behind a fixed-height preview
/// with a bottom fade and a "Show more" toggle — the same pattern ChatGPT
/// Wraps a user-sent message and, once it's tall enough to feel like a wall
/// of text (e.g. a whole article pasted in to ask the assistant about),
/// collapses it behind a fixed-height preview with a bottom fade and a
/// "Show more" toggle — the same pattern ChatGPT uses. Short messages that
/// never exceed the preview height render exactly as before, with no
/// toggle at all.
class _ExpandableUserText extends StatefulWidget {
  const _ExpandableUserText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  State<_ExpandableUserText> createState() => _ExpandableUserTextState();
}

class _ExpandableUserTextState extends State<_ExpandableUserText> {
  static const double _collapsedHeight = 220;

  final GlobalKey _measureKey = GlobalKey();
  bool _measured = false;
  bool _overflows = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _ExpandableUserText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      // Re-measure if the message content itself ever changes in place
      // (e.g. a retried/edited message swapped in for the same bubble).
      _measured = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    final RenderBox? box =
        _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;
    final bool overflow = box.size.height > _collapsedHeight + 8;
    setState(() {
      _measured = true;
      _overflows = overflow;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget content =
        SelectableText(widget.text, style: TextStyle(color: widget.color));

    if (!_measured) {
      // First frame only: laid out off-screen purely to measure its
      // natural height, so there's no flash of full-length content before
      // deciding whether it needs to collapse.
      return Offstage(child: Container(key: _measureKey, child: content));
    }

    if (!_overflows || _expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          content,
          if (_overflows)
            _ShowMoreToggle(
              expanded: true,
              color: widget.color,
              onTap: () => setState(() => _expanded = false),
            ),
        ],
      );
    }

    // Fades to the bubble's own background (solid primary color), not the
    // page background — this preview sits inside the colored user bubble,
    // not directly on the scaffold.
    final Color fade = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRect(
          child: SizedBox(
            height: _collapsedHeight,
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: content,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            fade.withValues(alpha: 0),
                            fade,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _ShowMoreToggle(
          expanded: false,
          color: widget.color,
          onTap: () => setState(() => _expanded = true),
        ),
      ],
    );
  }
}

class _ShowMoreToggle extends StatelessWidget {
  const _ShowMoreToggle({
    required this.expanded,
    required this.onTap,
    this.color,
  });

  final bool expanded;
  final VoidCallback onTap;
  // Explicit override for when this sits inside a solid-colored bubble
  // (e.g. the primary-colored user bubble) — falls back to the theme's
  // primary color for the no-background assistant case.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tint = color ?? scheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              expanded ? 'Show less' : 'Show more',
              style: TextStyle(color: tint, fontWeight: FontWeight.w700),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: tint,
              size: 20,
            ),
          ],
        ),
      ),
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
