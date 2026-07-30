/// How an image attachment is carried inside [AiMessage.content].
///
/// No database column exists for attachments (adding one needs a drift
/// codegen run this environment can't perform), so the image's on-disk path
/// is embedded as a hidden first line of the message text instead — a plain
/// TEXT column already supports that with zero schema change. Everything
/// that displays or sends a message decodes through [AiAttachment.parse]
/// rather than reading `content` directly, so this stays an implementation
/// detail no other code needs to know about.
class AiAttachment {
  const AiAttachment._({required this.imagePath, required this.text});

  /// Absolute path to the persisted image file, or `null` when the message
  /// has no attachment.
  final String? imagePath;

  /// The user-visible/sendable text, with the marker line (if any) removed.
  final String text;

  bool get hasImage => imagePath != null;

  static const String _prefix = '\u0001ai_image:';

  /// Builds the storable content for a message with an optional image.
  static String encode({required String? imagePath, required String text}) {
    if (imagePath == null || imagePath.isEmpty) return text;
    return '$_prefix$imagePath\n$text';
  }

  /// Parses stored `content` back into its image path (if any) and text.
  static AiAttachment parse(String content) {
    if (!content.startsWith(_prefix)) {
      return AiAttachment._(imagePath: null, text: content);
    }
    final int newline = content.indexOf('\n');
    if (newline == -1) {
      return AiAttachment._(
        imagePath: content.substring(_prefix.length),
        text: '',
      );
    }
    return AiAttachment._(
      imagePath: content.substring(_prefix.length, newline),
      text: content.substring(newline + 1),
    );
  }
}
