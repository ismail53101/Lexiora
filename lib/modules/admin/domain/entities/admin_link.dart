import 'package:equatable/equatable.dart';

/// A curated external link (e.g. a reference article, a past-paper site)
/// added via the Admin Panel.
class AdminLink extends Equatable {
  const AdminLink({
    required this.id,
    required this.title,
    required this.url,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String url;
  final String? note;
  final DateTime createdAt;

  factory AdminLink.fromJson(Map<String, dynamic> json) => AdminLink(
        id: json['id'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'url': url,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => <Object?>[id, title, url, note, createdAt];
}
