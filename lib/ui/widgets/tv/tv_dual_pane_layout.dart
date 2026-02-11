import 'package:flutter/material.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';

class TvDualPaneLayout extends StatelessWidget {
  const TvDualPaneLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Expanded(
            flex: 4,
            child: ShowListScreen(isPane: true),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
          const Expanded(
            flex: 6,
            child: PlaybackScreen(isPane: true),
          ),
        ],
      ),
    );
  }
}
