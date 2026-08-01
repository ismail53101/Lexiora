import 'package:equatable/equatable.dart';

/// A standalone note (announcement, reminder, curation note, ...) added via
/// the Admin Panel — independent of any specific document.
class AdminNote extends Equatable {
  const AdminNote({
    required this.id,
    required this.title,
    required this.content,
    this.subject,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;

  /// Free-text grouping (e.g. "Pakistan Affairs", "English") — lets the
  /// unified Admin Panel list be organized/filtered by topic.
  final String? subject;
  final DateTime createdAt;

  factory AdminNote.fromJson(Map<String, dynamic> json) => AdminNote(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        subject: json['subject'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'content': content,
        'subject': subject,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      <Object?>[id, title, content, subject, createdAt];
}
