import 'package:equatable/equatable.dart';

/// A user-defined library category (e.g. "Grammar", "Novels").
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, colorValue, createdAt];
}
