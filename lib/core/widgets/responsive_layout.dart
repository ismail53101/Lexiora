import 'package:flutter/widgets.dart';
import 'package:lexiora/core/responsive/breakpoints.dart';

/// Chooses between a [compact] (single-pane) and [expanded] (two-pane / tablet)
/// layout based on the current window width. When [expanded] is omitted the
/// compact layout is always used.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.expanded,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    if (expanded != null && Breakpoints.isTablet(context)) {
      return expanded!(context);
    }
    return compact(context);
  }
}
