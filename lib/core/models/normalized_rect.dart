import 'package:equatable/equatable.dart';

/// A rectangle expressed in **normalized page coordinates**: every value is in
/// the range 0..1 relative to the page, with the origin at the top-left.
///
/// Storing normalized coordinates is the key to robust annotations: a highlight
/// captured at one zoom level or screen size renders correctly at any other,
/// because the reader multiplies these fractions by the *current* rendered page
/// size at paint time. The data is never tied to a device or a zoom factor, and
/// it is never written back into the PDF file — Lexiora owns it.
class NormalizedRect extends Equatable {
  const NormalizedRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory NormalizedRect.fromJson(Map<String, dynamic> json) => NormalizedRect(
        left: (json['l'] as num).toDouble(),
        top: (json['t'] as num).toDouble(),
        width: (json['w'] as num).toDouble(),
        height: (json['h'] as num).toDouble(),
      );

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'l': left,
        't': top,
        'w': width,
        'h': height,
      };

  @override
  List<Object?> get props => [left, top, width, height];
}
