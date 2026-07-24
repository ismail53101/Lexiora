import 'package:flutter/widgets.dart';

/// Responsive breakpoints (aligned with Material 3 window size classes).
///
/// Lexiora adapts from phones to tablets; at [medium] and above the library and
/// reader switch to a two-pane master-detail layout.
abstract final class Breakpoints {
  static const double compact = 600; // phones
  static const double medium = 840; // large phones / small tablets
  static const double expanded = 1200; // tablets / desktop

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => widthOf(context) < compact;

  static bool isExpanded(BuildContext context) =>
      widthOf(context) >= expanded;

  /// True when a two-pane (master-detail) layout should be used.
  static bool isTablet(BuildContext context) => widthOf(context) >= medium;
}
