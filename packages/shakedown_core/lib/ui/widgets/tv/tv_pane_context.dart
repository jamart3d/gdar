import 'package:flutter/widgets.dart';

/// Lightweight InheritedWidget that broadcasts whether the TV left
/// (show-list) pane is currently active.  Placed by [TvDualPaneLayout]
/// around the ShowListScreen subtree.  Consumed by [CardStyle.compute()]
/// so cards can go transparent when the pane is inactive — without any
/// prop-drilling through ShowListScreen / ShowListItem / ShowListCard.
class TvPaneContext extends InheritedWidget {
  const TvPaneContext({
    super.key,
    required this.isLeftPaneActive,
    required super.child,
  });

  /// True when the TV left (show-list) pane has keyboard/D-Pad focus.
  final bool isLeftPaneActive;

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  /// Returns [isLeftPaneActive] from the nearest ancestor, defaulting to
  /// `true` so non-TV contexts are never affected.
  static bool of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<TvPaneContext>();
    return result?.isLeftPaneActive ?? true;
  }

  @override
  bool updateShouldNotify(TvPaneContext old) =>
      isLeftPaneActive != old.isLeftPaneActive;
}
